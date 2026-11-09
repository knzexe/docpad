import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/utils/dates.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/editor_provider.dart';

class FollowUpSection extends ConsumerWidget {
  const FollowUpSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final nextVisit = ref.watch(editorProvider).prescription?.nextVisit;
    final language = strings.languageCode;
    return SectionCard(
      title: strings.followUp,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    nextVisit ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              ref.read(editorProvider.notifier).setNextVisit(picked);
            },
            icon: const Icon(AppIcons.calendar, size: 18),
            label: Text(
              nextVisit == null
                  ? strings.chooseDate
                  : '${strings.nextVisit}: ${formatDate(nextVisit, languageCode: language)}',
            ),
          ),
          if (nextVisit != null)
            TextButton(
              onPressed: () =>
                  ref.read(editorProvider.notifier).setNextVisit(null),
              child: Text(strings.clearDate),
            ),
        ],
      ),
    );
  }
}
