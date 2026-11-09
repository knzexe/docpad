import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/utils/app_log.dart';
import 'data/local/app_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('bn');
  try {
    final overrides = await AppInitializer.create();
    runApp(ProviderScope(overrides: overrides, child: const DocPadApp()));
  } catch (error) {
    AppLog.error('startup', error);
    runApp(const StartupErrorApp());
  }
}
