import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/clinic_branding.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class DocPadApp extends ConsumerWidget {
  const DocPadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: ClinicBranding.name,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ClinicBranding.name,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${ClinicBranding.name} could not open local storage, so it did not start with an empty record list. Existing records were not erased.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}
