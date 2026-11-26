import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/clinic_branding.dart';
import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';

import '../../features/settings/providers/settings_providers.dart';
import '../constants/breakpoints.dart';
import '../utils/dates.dart';
import 'feedback_widgets.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int _index() {
    if (location.startsWith('/patients')) return 1;
    if (location.startsWith('/advice')) return 2;
    if (location.startsWith('/medicines')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _go(BuildContext context, int index) {
    switch (index) {
      case 1:
        context.go('/patients');
      case 2:
        context.go('/advice');
      case 3:
        context.go('/medicines');
      case 4:
        context.go('/settings');
      default:
        context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final profile = ref.watch(profileProvider);
    final index = _index();
    final destinations = [
      (AppIcons.home, strings.home, const Key('nav-home')),
      (AppIcons.users, strings.patients, const Key('nav-patients')),
      (AppIcons.clipboardList, strings.advice, const Key('nav-advice')),
      (Icons.medication_outlined, 'Medicines', const Key('nav-medicines')),
      (AppIcons.settings, strings.settings, const Key('nav-settings')),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final mobile = Breakpoints.isMobile(width);
        final desktop = Breakpoints.isDesktop(width);
        final body = Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child),
          ],
        );

        if (mobile) {
          return Scaffold(
            body: SafeArea(child: body),
            bottomNavigationBar: NavigationBar(
              key: const Key('nav-bar'),
              selectedIndex: index,
              onDestinationSelected: (value) => _go(context, value),
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    key: item.$3,
                    icon: Icon(item.$1),
                    label: item.$2,
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  key: const Key('nav-rail'),
                  extended: desktop,
                  selectedIndex: index,
                  onDestinationSelected: (value) => _go(context, value),
                  leading: Padding(
                    padding: EdgeInsets.fromLTRB(desktop ? 12 : 8, 12, 12, 8),
                    child: _Brand(
                      extended: desktop,
                      title: profile.clinicName.trim().isEmpty
                          ? ClinicBranding.name
                          : profile.clinicName.trim(),
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: desktop
                            ? _DoctorFoot(
                                name: profile.name.trim().isEmpty
                                    ? strings.addYourName
                                    : profile.name.trim(),
                                date: formatDate(
                                  DateTime.now(),
                                  languageCode: strings.languageCode,
                                ),
                              )
                            : IconButton(
                                tooltip: strings.settings,
                                onPressed: () => context.go('/settings'),
                                icon: const Icon(AppIcons.user),
                              ),
                      ),
                    ),
                  ),
                  destinations: [
                    for (final item in destinations)
                      NavigationRailDestination(
                        icon: Icon(item.$1, key: item.$3),
                        label: Text(item.$2),
                      ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.extended, required this.title});

  final bool extended;
  final String title;

  @override
  Widget build(BuildContext context) {
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: Image.asset(
        ClinicBranding.logoAsset,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          color: Theme.of(context).colorScheme.primary,
          child: Icon(
            AppIcons.stethoscope,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
    if (!extended) return mark;
    return Row(
      children: [
        mark,
        const SizedBox(width: 10),
        SizedBox(
          width: 164,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _DoctorFoot extends StatelessWidget {
  const _DoctorFoot({required this.name, required this.date});

  final String name;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 2),
        Text(date, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
