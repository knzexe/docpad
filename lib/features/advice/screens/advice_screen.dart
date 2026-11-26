import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_icons.dart';

import 'package:uuid/uuid.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feedback_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../prescription/providers/record_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/advice_template.dart';

class AdviceScreen extends ConsumerStatefulWidget {
  const AdviceScreen({super.key});

  @override
  ConsumerState<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends ConsumerState<AdviceScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final advice = ref.watch(adviceListProvider);
    final filter = _search.text.trim().toLowerCase();
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: strings.adviceLibrary,
            subtitle: strings.adviceHint,
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(AppIcons.plus),
                label: Text(strings.addTemplate),
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: strings.searchTemplates,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          advice.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(strings.couldNotRead),
            data: (items) {
              final visible = items.where((item) {
                if (filter.isEmpty) return true;
                return item.title.toLowerCase().contains(filter) ||
                    item.body.toLowerCase().contains(filter);
              }).toList();
              if (visible.isEmpty) {
                return EmptyState(
                  icon: AppIcons.clipboardList,
                  title: strings.adviceLibrary,
                  body: strings.noTemplates,
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < visible.length; index++)
                    _TemplateCard(
                      template: visible[index],
                      index: items.indexOf(visible[index]),
                      lastIndex: items.length - 1,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _edit([AdviceTemplate? existing]) async {
    final strings = ref.read(stringsProvider);
    final saved = await showDialog<({String title, String body})>(
      context: context,
      builder: (context) => _TemplateEditor(
        heading: existing == null ? strings.addTemplate : strings.editTemplate,
        title: existing?.title ?? '',
        body: existing?.body ?? '',
        strings: strings,
      ),
    );
    if (saved == null) return;
    final current = ref.read(adviceListProvider).asData?.value.length ?? 0;
    await ref
        .read(adviceListProvider.notifier)
        .save(
          AdviceTemplate(
            id: existing?.id ?? const Uuid().v4(),
            title: saved.title,
            body: saved.body,
            sortOrder: existing?.sortOrder ?? current,
            updatedAt: DateTime.now(),
          ),
        );
  }
}

class _TemplateEditor extends StatefulWidget {
  const _TemplateEditor({
    required this.heading,
    required this.title,
    required this.body,
    required this.strings,
  });

  final String heading;
  final String title;
  final String body;
  final AppStrings strings;

  @override
  State<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<_TemplateEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.title);
    _body = TextEditingController(text: widget.body);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AlertDialog(
      title: Text(widget.heading),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                fieldKey: const Key('template-title'),
                controller: _title,
                label: strings.templateTitle,
              ),
              const SizedBox(height: 12),
              AppTextField(
                fieldKey: const Key('template-body'),
                controller: _body,
                label: strings.templateBody,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            final body = _body.text.trim();
            if (body.isEmpty) return;
            Navigator.pop(context, (title: _title.text.trim(), body: body));
          },
          child: Text(strings.save),
        ),
      ],
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({
    required this.template,
    required this.index,
    required this.lastIndex,
  });

  final AdviceTemplate template;
  final int index;
  final int lastIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final compactActions = Breakpoints.usesCompactActions(
      MediaQuery.sizeOf(context).width,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          template.title.trim().isEmpty ? template.body : template.title,
        ),
        subtitle: template.title.trim().isEmpty ? null : Text(template.body),
        trailing: compactActions
            ? PopupMenuButton<_AdviceAction>(
                onSelected: (action) async {
                  switch (action) {
                    case _AdviceAction.up:
                      await ref
                          .read(adviceListProvider.notifier)
                          .reorder(index, -1);
                    case _AdviceAction.down:
                      await ref
                          .read(adviceListProvider.notifier)
                          .reorder(index, 1);
                    case _AdviceAction.edit:
                      final screen = context
                          .findAncestorStateOfType<_AdviceScreenState>();
                      await screen?._edit(template);
                    case _AdviceAction.delete:
                      final ok = await confirmDestructive(
                        context,
                        strings: strings,
                        title: strings.deleteTemplateTitle,
                        body: strings.deleteTemplateBody,
                        confirmLabel: strings.delete,
                      );
                      if (ok) {
                        await ref
                            .read(adviceListProvider.notifier)
                            .delete(template.id);
                      }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _AdviceAction.up,
                    enabled: index > 0,
                    child: Text(strings.moveUp),
                  ),
                  PopupMenuItem(
                    value: _AdviceAction.down,
                    enabled: index < lastIndex,
                    child: Text(strings.moveDown),
                  ),
                  PopupMenuItem(
                    value: _AdviceAction.edit,
                    child: Text(strings.edit),
                  ),
                  PopupMenuItem(
                    value: _AdviceAction.delete,
                    child: Text(strings.delete),
                  ),
                ],
              )
            : Wrap(
                children: [
                  IconButton(
                    tooltip: strings.moveUp,
                    onPressed: index == 0
                        ? null
                        : () => ref
                              .read(adviceListProvider.notifier)
                              .reorder(index, -1),
                    icon: const Icon(AppIcons.arrowUp, size: 18),
                  ),
                  IconButton(
                    tooltip: strings.moveDown,
                    onPressed: index == lastIndex
                        ? null
                        : () => ref
                              .read(adviceListProvider.notifier)
                              .reorder(index, 1),
                    icon: const Icon(AppIcons.arrowDown, size: 18),
                  ),
                  IconButton(
                    tooltip: strings.edit,
                    onPressed: () async {
                      final screen = context
                          .findAncestorStateOfType<_AdviceScreenState>();
                      await screen?._edit(template);
                    },
                    icon: const Icon(AppIcons.edit3, size: 18),
                  ),
                  IconButton(
                    tooltip: strings.delete,
                    onPressed: () async {
                      final ok = await confirmDestructive(
                        context,
                        strings: strings,
                        title: strings.deleteTemplateTitle,
                        body: strings.deleteTemplateBody,
                        confirmLabel: strings.delete,
                      );
                      if (ok) {
                        await ref
                            .read(adviceListProvider.notifier)
                            .delete(template.id);
                      }
                    },
                    icon: const Icon(AppIcons.trash2, size: 18),
                  ),
                ],
              ),
      ),
    );
  }
}

enum _AdviceAction { up, down, edit, delete }
