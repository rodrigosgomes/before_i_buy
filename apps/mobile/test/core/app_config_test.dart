import 'package:before_i_buy_mobile/core/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const readyConfig = AppConfig(
  supabaseUrl: 'https://example.supabase.co',
  supabasePublishableKey: 'public-key',
  googleWebClientId: 'web.apps.googleusercontent.com',
  googleIosClientId: 'ios.apps.googleusercontent.com',
);

void main() {
  test('accepts HTTPS Supabase configuration', () {
    expect(readyConfig.hasSupabaseConfiguration, isTrue);
    expect(readyConfig.isReadyFor(TargetPlatform.android), isTrue);
    expect(readyConfig.isReadyFor(TargetPlatform.iOS), isTrue);
  });

  test('allows localhost only over HTTP for local development', () {
    const config = AppConfig(
      supabaseUrl: 'http://localhost:54321',
      supabasePublishableKey: 'public-key',
      googleWebClientId: 'web.apps.googleusercontent.com',
      googleIosClientId: 'ios.apps.googleusercontent.com',
    );

    expect(config.hasSupabaseConfiguration, isTrue);
  });

  test('fails closed for malformed Supabase configuration', () {
    const config = AppConfig(
      supabaseUrl: 'http://untrusted.example',
      supabasePublishableKey: '',
      googleWebClientId: '',
      googleIosClientId: '',
    );

    expect(config.hasSupabaseConfiguration, isFalse);
    expect(
      config.missingFor(TargetPlatform.android),
      containsAll(<String>[
        'SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY',
        'GOOGLE_WEB_CLIENT_ID',
      ]),
    );
  });

  test('requires an iOS client ID only on iOS', () {
    const config = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: 'public-key',
      googleWebClientId: 'web.apps.googleusercontent.com',
      googleIosClientId: '',
    );

    expect(config.isReadyFor(TargetPlatform.android), isTrue);
    expect(
      config.missingFor(TargetPlatform.iOS),
      contains('GOOGLE_IOS_CLIENT_ID'),
    );
  });

  test('fails closed outside the supported mobile platforms', () {
    expect(
      readyConfig.missingFor(TargetPlatform.macOS),
      contains('Google nativo requer Android ou iOS'),
    );
  });

  test('accepts only a clean HTTPS guest invite origin', () {
    const configured = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: 'public-key',
      googleWebClientId: 'web.apps.googleusercontent.com',
      googleIosClientId: 'ios.apps.googleusercontent.com',
      guestInviteBaseUrl: 'https://guest.example.com/app',
    );
    const invalid = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: 'public-key',
      googleWebClientId: 'web.apps.googleusercontent.com',
      googleIosClientId: 'ios.apps.googleusercontent.com',
      guestInviteBaseUrl: 'http://guest.example.com?token=not-allowed',
    );

    expect(configured.guestInviteBaseUri?.path, '/app');
    expect(invalid.guestInviteBaseUri, isNull);

    const withUserInfo = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: 'public-key',
      googleWebClientId: 'web.apps.googleusercontent.com',
      googleIosClientId: 'ios.apps.googleusercontent.com',
      guestInviteBaseUrl: 'https://user@guest.example.com',
    );
    expect(withUserInfo.guestInviteBaseUri, isNull);
  });
}
