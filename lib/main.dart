import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/utils/app_log.dart';
import 'data/cloud/secure_supabase_local_storage.dart';
import 'data/local/app_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('bn');
  try {
    const url = String.fromEnvironment('SUPABASE_URL');
    const publishableKey = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );
    SupabaseClient? supabaseClient;
    String? cloudConfigurationError;
    if (url.isEmpty != publishableKey.isEmpty) {
      cloudConfigurationError =
          'Both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be configured.';
    } else if (url.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: url,
          publishableKey: publishableKey,
          authOptions: const FlutterAuthClientOptions(
            localStorage: SecureSupabaseLocalStorage(),
          ),
        );
        supabaseClient = Supabase.instance.client;
      } catch (error) {
        AppLog.error('supabase-initialize', error);
        cloudConfigurationError =
            'Supabase could not be initialized. Check the project URL and public key.';
      }
    }
    final overrides = await AppInitializer.create(
      supabaseClient: supabaseClient,
      cloudConfigurationError: cloudConfigurationError,
    );
    runApp(ProviderScope(overrides: overrides, child: const DocPadApp()));
  } catch (error) {
    AppLog.error('startup', error);
    runApp(const StartupErrorApp());
  }
}
