import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { signedOut, signedIn }

abstract interface class AuthGateway {
  bool get isAuthenticated;
  Stream<AuthStatus> get statusChanges;
  Future<void> signInWithOtp({
    required String email,
    required String emailRedirectTo,
  });
}

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._auth);

  final GoTrueClient _auth;

  @override
  bool get isAuthenticated => _auth.currentSession != null;

  @override
  Stream<AuthStatus> get statusChanges => _auth.onAuthStateChange.map(
    (event) =>
        event.session == null ? AuthStatus.signedOut : AuthStatus.signedIn,
  );

  @override
  Future<void> signInWithOtp({
    required String email,
    required String emailRedirectTo,
  }) => _auth.signInWithOtp(email: email, emailRedirectTo: emailRedirectTo);
}

class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({bool authenticated = false, this.failure})
    : _authenticated = authenticated;

  final _controller = StreamController<AuthStatus>.broadcast();
  bool _authenticated;
  Object? failure;
  int sendCount = 0;
  String? lastEmail;
  String? lastRedirectTo;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Stream<AuthStatus> get statusChanges => _controller.stream;

  @override
  Future<void> signInWithOtp({
    required String email,
    required String emailRedirectTo,
  }) async {
    sendCount += 1;
    lastEmail = email;
    lastRedirectTo = emailRedirectTo;
    if (failure case final failure?) throw failure;
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
