import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'features/auth/auth_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig.fromEnvironment;
  AuthGateway? authGateway;
  if (config.hasSupabaseConfiguration) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
    authGateway = SupabaseAuthGateway(Supabase.instance.client.auth);
  }
  runApp(BeforeIBuyApp(config: config, authGateway: authGateway));
}
