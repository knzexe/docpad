import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/advice/screens/advice_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/patients/models/patient.dart';
import '../../features/medicine/screens/medicine_library_screen.dart';
import '../../features/prescription/screens/prescription_editor_screen.dart';
import '../../features/prescription/screens/prescription_preview_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../widgets/app_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/patients',
            builder: (context, state) => const PatientsScreen(),
          ),
          GoRoute(
            path: '/advice',
            builder: (context, state) => const AdviceScreen(),
          ),
          GoRoute(
            path: '/medicines',
            builder: (context, state) => const MedicineLibraryScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/prescription/:id',
        builder: (context, state) {
          return PrescriptionEditorScreen(
            prescriptionId: state.pathParameters['id'],
            prefilled: state.extra is Patient ? state.extra! as Patient : null,
          );
        },
        routes: [
          GoRoute(
            path: 'preview',
            builder: (context, state) {
              return PrescriptionPreviewScreen(
                prescriptionId: state.pathParameters['id']!,
              );
            },
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
