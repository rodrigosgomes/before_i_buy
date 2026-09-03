import 'dart:async';

import 'package:before_i_buy_mobile/features/auth/auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const credential = GoogleIdentityCredential(
    idToken: 'id-token',
    accessToken: 'access-token',
  );

  test('exchanges native Google tokens for a Supabase session', () async {
    final session = _MemorySession();
    final gateway = SupabaseGoogleAuthGateway(
      identityProvider: _Identity(credential: credential),
      session: session,
    );

    final result = await gateway.signInWithGoogle();

    expect(result, SocialAuthResult.authenticated);
    expect(session.credentials, [credential]);
  });

  test('treats a dismissed native selector as neutral', () async {
    final session = _MemorySession();
    final gateway = SupabaseGoogleAuthGateway(
      identityProvider: _Identity(),
      session: session,
    );

    expect(await gateway.signInWithGoogle(), SocialAuthResult.cancelled);
    expect(session.credentials, isEmpty);
  });

  test('fails closed when identity or session exchange fails', () async {
    final identityFailure = SupabaseGoogleAuthGateway(
      identityProvider: _Identity(error: StateError('provider failure')),
      session: _MemorySession(),
    );
    final session = _MemorySession(error: StateError('session failure'));
    final sessionFailure = SupabaseGoogleAuthGateway(
      identityProvider: _Identity(credential: credential),
      session: session,
    );

    expect(await identityFailure.signInWithGoogle(), SocialAuthResult.failed);
    expect(await sessionFailure.signInWithGoogle(), SocialAuthResult.failed);
    expect(session.credentials, isEmpty);
  });

  test(
    'fake gateway emits only signed-in state after a successful entry',
    () async {
      final auth = FakeAuthGateway();
      final statuses = <AuthStatus>[];
      final subscription = auth.statusChanges.listen(statuses.add);

      expect(await auth.signInWithGoogle(), SocialAuthResult.authenticated);
      await Future<void>.delayed(Duration.zero);

      expect(auth.isAuthenticated, isTrue);
      expect(statuses, [AuthStatus.signedIn]);
      await subscription.cancel();
      await auth.close();
    },
  );
}

class _Identity implements GoogleIdentityProvider {
  const _Identity({this.credential, this.error});

  final GoogleIdentityCredential? credential;
  final Object? error;

  @override
  Future<GoogleIdentityCredential?> authenticate() async {
    if (error != null) throw error!;
    return credential;
  }
}

class _MemorySession implements AuthSessionGateway {
  _MemorySession({this.error});

  final Object? error;
  final credentials = <GoogleIdentityCredential>[];
  final _statuses = StreamController<AuthStatus>.broadcast();
  bool _authenticated = false;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Stream<AuthStatus> get statusChanges => _statuses.stream;

  @override
  Future<void> signInWithGoogleTokens(
    GoogleIdentityCredential credential,
  ) async {
    if (error != null) throw error!;
    credentials.add(credential);
    _authenticated = true;
    _statuses.add(AuthStatus.signedIn);
  }
}
