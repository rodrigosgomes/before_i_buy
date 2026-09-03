import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { signedOut, signedIn }

enum SocialAuthResult { authenticated, cancelled, failed }

class GoogleIdentityCredential {
  const GoogleIdentityCredential({
    required this.idToken,
    required this.accessToken,
  });

  final String idToken;
  final String accessToken;
}

abstract interface class GoogleIdentityProvider {
  Future<GoogleIdentityCredential?> authenticate();
}

abstract interface class AuthSessionGateway {
  bool get isAuthenticated;
  Stream<AuthStatus> get statusChanges;
  Future<void> signInWithGoogleTokens(GoogleIdentityCredential credential);
}

abstract interface class AuthGateway {
  bool get isAuthenticated;
  Stream<AuthStatus> get statusChanges;
  Future<SocialAuthResult> signInWithGoogle();
}

class GoogleSignInIdentityProvider implements GoogleIdentityProvider {
  GoogleSignInIdentityProvider({
    required this.webClientId,
    required this.iosClientId,
    TargetPlatform? platform,
  }) : _platform = platform ?? defaultTargetPlatform;

  final String webClientId;
  final String iosClientId;
  final TargetPlatform _platform;
  Future<void>? _initialization;

  Future<void> _initialize() =>
      _initialization ??= GoogleSignIn.instance.initialize(
        serverClientId: webClientId,
        clientId: _platform == TargetPlatform.iOS ? iosClientId : null,
      );

  @override
  Future<GoogleIdentityCredential?> authenticate() async {
    await _initialize();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final authorization =
          await account.authorizationClient.authorizationForScopes([]) ??
          await account.authorizationClient.authorizeScopes([]);
      final idToken = account.authentication.idToken;
      if (idToken == null || authorization.accessToken.isEmpty) {
        throw const GoogleIdentityTokenException();
      }
      return GoogleIdentityCredential(
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
    } on GoogleSignInException catch (exception) {
      if (exception.code == GoogleSignInExceptionCode.canceled ||
          exception.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }
}

class GoogleIdentityTokenException implements Exception {
  const GoogleIdentityTokenException();
}

class SupabaseAuthSessionGateway implements AuthSessionGateway {
  SupabaseAuthSessionGateway(this._auth);

  final GoTrueClient _auth;

  @override
  bool get isAuthenticated => _auth.currentSession != null;

  @override
  Stream<AuthStatus> get statusChanges => _auth.onAuthStateChange.map(
    (event) =>
        event.session == null ? AuthStatus.signedOut : AuthStatus.signedIn,
  );

  @override
  Future<void> signInWithGoogleTokens(
    GoogleIdentityCredential credential,
  ) async {
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: credential.idToken,
      accessToken: credential.accessToken,
    );
  }
}

class SupabaseGoogleAuthGateway implements AuthGateway {
  SupabaseGoogleAuthGateway({
    required AuthSessionGateway session,
    required GoogleIdentityProvider identityProvider,
  }) : _session = session,
       _identityProvider = identityProvider;

  final AuthSessionGateway _session;
  final GoogleIdentityProvider _identityProvider;

  @override
  bool get isAuthenticated => _session.isAuthenticated;

  @override
  Stream<AuthStatus> get statusChanges => _session.statusChanges;

  @override
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      final credential = await _identityProvider.authenticate();
      if (credential == null) return SocialAuthResult.cancelled;
      await _session.signInWithGoogleTokens(credential);
      return SocialAuthResult.authenticated;
    } catch (_) {
      return SocialAuthResult.failed;
    }
  }
}

class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    bool authenticated = false,
    this.nextGoogleResult = SocialAuthResult.authenticated,
  }) : _authenticated = authenticated;

  final _controller = StreamController<AuthStatus>.broadcast();
  bool _authenticated;
  SocialAuthResult nextGoogleResult;
  int googleSignInCount = 0;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Stream<AuthStatus> get statusChanges => _controller.stream;

  @override
  Future<SocialAuthResult> signInWithGoogle() async {
    googleSignInCount += 1;
    if (nextGoogleResult == SocialAuthResult.authenticated) {
      completeSignIn();
    }
    return nextGoogleResult;
  }

  void completeSignIn() {
    _authenticated = true;
    _controller.add(AuthStatus.signedIn);
  }

  void signOut() {
    _authenticated = false;
    _controller.add(AuthStatus.signedOut);
  }

  Future<void> close() => _controller.close();
}
