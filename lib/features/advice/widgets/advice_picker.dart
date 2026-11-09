import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../prescription/providers/editor_provider.dart';
import '../../prescription/providers/record_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/advice_template.dart';

class AdvicePicker extends ConsumerStatefulWidget {
  const AdvicePicker({super.key});

  @override
  ConsumerState<AdvicePicker> createState() => _AdvicePickerState();
}

class _AdvicePickerState extends ConsumerState<AdvicePicker> {
  final _custom = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final templates =
        ref.watch(adviceListProvider).asData?.value ?? const <AdviceTemplate>[];
    final selected =
        ref.watch(editorProvider).prescription?.advice ?? const <String>[];
    final notifier = ref.read(editorProvider.notifier);
    return SectionCard(
      title: strings.advice,
      subtitle: strings.adviceCopiedNote,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (templates.isEmpty)
            Text(
              strings.noTemplates,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (final template in templates)
              Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected.contains(template.body.trim()),
                  title: Text(
                    template.title.trim().isEmpty
                        ? template.body
                        : template.title,
                  ),
                  subtitle: template.title.trim().isEmpty
                      ? null
                      : Text(template.body),
                  onChanged: (checked) {
                    final body = template.body.trim();
                    if (checked ?? false) {
                      final added = notifier.addAdviceLine(body);
                      setState(() {
                        _message = added ? null : strings.alreadyAdded;
                      });
                    } else {
                      final index = selected.indexOf(body);
                      if (index >= 0) notifier.removeAdviceAt(index);
                    }
                  },
                ),
              ),
          const SizedBox(height: 8),
          AppTextField(
            fieldKey: const Key('advice-custom'),
            controller: _custom,
            label: strings.customAdvice,
            maxLines: 3,
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _message!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('add-custom-advice'),
            onPressed: () {
              final added = notifier.addAdviceLine(_custom.text);
              setState(() {
                _message = added ? null : strings.alreadyAdded;
                if (added) _custom.clear();
              });
            },
            child: Text(strings.addCustom),
          ),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              strings.selectedAdvice,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < selected.length; index++)
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${index + 1}. ${selected[index]}'),
                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      IconButton(
                        tooltip: strings.moveUp,
                        onPressed: index == 0
                            ? null
                            : () => notifier.moveAdvice(index, -1),
                        icon: const Icon(AppIcons.arrowUp, size: 18),
                      ),
                      IconButton(
                        tooltip: strings.moveDown,
                        onPressed: index == selected.length - 1
                            ? null
                            : () => notifier.moveAdvice(index, 1),
                        icon: const Icon(AppIcons.arrowDown, size: 18),
                      ),
                      IconButton(
                        tooltip: strings.remove,
                        onPressed: () => notifier.removeAdviceAt(index),
                        icon: const Icon(AppIcons.trash2, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
