import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.googleWebClientId,
    required this.googleIosClientId,
    this.guestInviteBaseUrl = '',
  });

  final String supabaseUrl;
  final String supabasePublishableKey;
  final String googleWebClientId;
  final String googleIosClientId;
  final String guestInviteBaseUrl;

  bool get hasSupabaseConfiguration {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || supabasePublishableKey.trim().isEmpty) return false;
    final secure = uri.scheme == 'https';
    final local =
        uri.scheme == 'http' &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1');
    return uri.hasAuthority && (secure || local);
  }

  List<String> missingFor(TargetPlatform platform) {
    final missing = <String>[];
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      missing.add('Google nativo requer Android ou iOS');
    }
    if (!hasSupabaseConfiguration) {
      missing.add('SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY');
    }
    if (googleWebClientId.trim().isEmpty) {
      missing.add('GOOGLE_WEB_CLIENT_ID');
    }
    if (platform == TargetPlatform.iOS && googleIosClientId.trim().isEmpty) {
      missing.add('GOOGLE_IOS_CLIENT_ID');
    }
    return missing;
  }

  bool isReadyFor(TargetPlatform platform) => missingFor(platform).isEmpty;

  Uri? get guestInviteBaseUri {
    final uri = Uri.tryParse(guestInviteBaseUrl.trim());
    if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) return null;
    if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) return null;
    return uri;
  }

  static const fromEnvironment = AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    googleWebClientId: String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    googleIosClientId: String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
    guestInviteBaseUrl: String.fromEnvironment('GUEST_INVITE_BASE_URL'),
  );
}
