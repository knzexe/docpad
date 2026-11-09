import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/connectivity_provider.dart';
import '../../features/settings/providers/settings_providers.dart';
import '../theme/app_colors.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider);
    if (online.asData?.value != false) return const SizedBox.shrink();
    final strings = ref.watch(stringsProvider);
    return _Banner(color: AppColors.warning, message: strings.offlineBanner);
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message, this.danger = false});

  final String message;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      color: danger ? AppColors.danger : AppColors.primary,
      message: message,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.message});

  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

Future<bool> confirmDestructive(
  BuildContext context, {
  required AppStrings strings,
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

enum LeaveChoice { save, discard, cancel }

Future<LeaveChoice> confirmLeave(
  BuildContext context, {
  required AppStrings strings,
}) async {
  final result = await showDialog<LeaveChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(strings.leaveTitle),
      content: Text(strings.leaveBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, LeaveChoice.cancel),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, LeaveChoice.discard),
          child: Text(strings.discard),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, LeaveChoice.save),
          child: Text(strings.saveAndLeave),
        ),
      ],
    ),
  );
  return result ?? LeaveChoice.cancel;
}
