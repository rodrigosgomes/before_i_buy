import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'features/auth/auth_gateway.dart';
import 'features/analytics/creator_analytics.dart';
import 'features/creator/creator_remote_gateway.dart';
import 'features/creator/share_plus_invite_share_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig.fromEnvironment;
  AuthGateway? authGateway;
  CreatorProfileGateway creatorProfileGateway = MemoryCreatorProfileGateway();
  DilemmaPublicationGateway publicationGateway =
      MemoryDilemmaPublicationGateway();
  CreatorDilemmaGateway dilemmaGateway = MemoryCreatorDilemmaGateway();
  CreatorAnalyticsFactory analyticsFactory = (_) =>
      const NoopCreatorAnalytics();
  if (config.hasSupabaseConfiguration) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    authGateway = SupabaseGoogleAuthGateway(
      session: SupabaseAuthSessionGateway(Supabase.instance.client.auth),
      identityProvider: GoogleSignInIdentityProvider(
        webClientId: config.googleWebClientId,
        iosClientId: config.googleIosClientId,
      ),
    );
    creatorProfileGateway = SupabaseCreatorProfileGateway(
      Supabase.instance.client,
    );
    publicationGateway = SupabaseDilemmaPublicationGateway(
      Supabase.instance.client,
    );
    dilemmaGateway = SupabaseCreatorDilemmaGateway(Supabase.instance.client);
    analyticsFactory = (userId) => QueuedCreatorAnalytics(
      queue: SecureCreatorAnalyticsQueue(userId: userId),
      transport: SupabaseCreatorAnalyticsTransport(Supabase.instance.client),
    );
  }
  runApp(
    BeforeIBuyApp(
      config: config,
      authGateway: authGateway,
      creatorProfileGateway: creatorProfileGateway,
      publicationGateway: publicationGateway,
      dilemmaGateway: dilemmaGateway,
      shareGateway: SharePlusInviteShareGateway(),
      analyticsFactory: analyticsFactory,
    ),
  );
}
