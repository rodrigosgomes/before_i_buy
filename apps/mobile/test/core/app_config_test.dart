import 'package:before_i_buy_mobile/core/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('accepts HTTPS and local Supabase URLs with a public key', () {
      expect(
        const AppConfig(
          supabaseUrl: 'https://project.supabase.co',
          supabaseAnonKey: 'public-key',
        ).hasSupabaseConfiguration,
        isTrue,
      );
      expect(
        const AppConfig(
          supabaseUrl: 'http://127.0.0.1:54321',
          supabaseAnonKey: 'public-key',
        ).hasSupabaseConfiguration,
        isTrue,
      );
    });

    test('rejects missing, malformed, and insecure remote configuration', () {
      for (final config in [
        const AppConfig(supabaseUrl: '', supabaseAnonKey: ''),
        const AppConfig(
          supabaseUrl: 'not-a-url',
          supabaseAnonKey: 'public-key',
        ),
        const AppConfig(
          supabaseUrl: 'http://example.com',
          supabaseAnonKey: 'public-key',
        ),
      ]) {
        expect(config.hasSupabaseConfiguration, isFalse);
      }
    });
  });
}
