class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.supabaseAnonKey});

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get hasSupabaseConfiguration {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || supabaseAnonKey.trim().isEmpty) return false;
    final secure = uri.scheme == 'https';
    final local =
        uri.scheme == 'http' &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1');
    return uri.hasAuthority && (secure || local);
  }

  static const fromEnvironment = AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
}
