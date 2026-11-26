import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/medicine.dart';
import '../providers/medicine_library_provider.dart';

class MedicineLibraryScreen extends ConsumerWidget {
  const MedicineLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final medicines = ref.watch(medicineLibraryProvider);
    final compactActions = Breakpoints.usesCompactActions(
      MediaQuery.sizeOf(context).width,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Medicine Library',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: compactActions ? 8 : 16),
            child: compactActions
                ? IconButton(
                    key: const Key('add-medicine'),
                    tooltip: strings.addNewMedicine,
                    onPressed: () => showMedicineLibraryForm(context),
                    icon: const Icon(Icons.add),
                  )
                : FilledButton.icon(
                    key: const Key('add-medicine'),
                    onPressed: () => showMedicineLibraryForm(context),
                    icon: const Icon(Icons.add),
                    label: Text(strings.addNewMedicine),
                  ),
          ),
        ],
      ),
      body: medicines.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load medicines: $error')),
        data: (items) => _MedicineList(items: items),
      ),
    );
  }
}

class _MedicineList extends ConsumerStatefulWidget {
  const _MedicineList({required this.items});

  final List<Medicine> items;

  @override
  ConsumerState<_MedicineList> createState() => _MedicineListState();
}

class _MedicineListState extends ConsumerState<_MedicineList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final items = widget.items.where((item) {
      return query.isEmpty ||
          item.brandName.toLowerCase().contains(query) ||
          (item.genericName?.toLowerCase().contains(query) ?? false);
    }).toList();
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('medicine-library-search'),
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by brand or generic name',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            const EmptyState(
              icon: Icons.medication_outlined,
              title: 'No medicines found',
              body: 'Add medicines manually to build your private library.',
            )
          else
            for (final item in items) _MedicineCard(item: item),
        ],
      ),
    );
  }
}

class _MedicineCard extends ConsumerWidget {
  const _MedicineCard({required this.item});

  final Medicine item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compactActions = Breakpoints.usesCompactActions(
      MediaQuery.sizeOf(context).width,
    );
    final details = [
      if (item.genericName != null) item.genericName!,
      if (item.strength != null) item.strength!,
      if (item.dosageForm != null) item.dosageForm!,
    ].join(' | ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        title: Text(item.brandName),
        subtitle: Text(
          [
            if (details.isNotEmpty) details,
            if (item.manufacturer != null) item.manufacturer!,
            if (item.category != null) item.category!,
          ].join('\n'),
        ),
        isThreeLine: details.isNotEmpty,
        trailing: compactActions
            ? PopupMenuButton<_MedicineAction>(
                onSelected: (action) {
                  switch (action) {
                    case _MedicineAction.add:
                      context.go('/prescription/new');
                    case _MedicineAction.edit:
                      showMedicineLibraryForm(context, initial: item);
                    case _MedicineAction.delete:
                      _delete(context, ref);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _MedicineAction.add,
                    child: Text('Add to prescription'),
                  ),
                  PopupMenuItem(
                    value: _MedicineAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _MedicineAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              )
            : Wrap(
                children: [
                  IconButton(
                    tooltip: 'Add to prescription',
                    onPressed: () => context.go('/prescription/new'),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () =>
                        showMedicineLibraryForm(context, initial: item),
                    icon: const Icon(AppIcons.edit3),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _delete(context, ref),
                    icon: const Icon(AppIcons.trash2),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text('Remove ${item.brandName} from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(medicineLibraryProvider.notifier).remove(item.id);
    }
  }
}

enum _MedicineAction { add, edit, delete }

Future<Medicine?> showMedicineLibraryForm(
  BuildContext context, {
  Medicine? initial,
}) async {
  return showDialog<Medicine>(
    context: context,
    builder: (_) => _MedicineForm(initial: initial),
  );
}

class _MedicineForm extends ConsumerStatefulWidget {
  const _MedicineForm({this.initial});

  final Medicine? initial;

  @override
  ConsumerState<_MedicineForm> createState() => _MedicineFormState();
}

class _MedicineFormState extends ConsumerState<_MedicineForm> {
  late final TextEditingController _brand;
  late final TextEditingController _generic;
  late final TextEditingController _strength;
  late final TextEditingController _form;
  late final TextEditingController _manufacturer;
  late final TextEditingController _category;
  late final TextEditingController _notes;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _brand = TextEditingController(text: item?.brandName);
    _generic = TextEditingController(text: item?.genericName);
    _strength = TextEditingController(text: item?.strength);
    _form = TextEditingController(text: item?.dosageForm);
    _manufacturer = TextEditingController(text: item?.manufacturer);
    _category = TextEditingController(text: item?.category);
    _notes = TextEditingController(text: item?.notes);
  }

  @override
  void dispose() {
    for (final controller in [
      _brand,
      _generic,
      _strength,
      _form,
      _manufacturer,
      _category,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    return AlertDialog(
      title: Text(
        widget.initial == null ? strings.addNewMedicine : strings.editMedicine,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            children: [
              AppTextField(
                fieldKey: const Key('library-medicine-brand'),
                controller: _brand,
                label: strings.brandName,
                requiredField: true,
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _generic, label: strings.genericName),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _strength,
                      label: strings.strength,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _form,
                      label: strings.dosageForm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _manufacturer,
                label: strings.manufacturer,
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _category, label: strings.category),
              const SizedBox(height: 12),
              AppTextField(
                controller: _notes,
                label: strings.notes,
                maxLines: 3,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(strings.saveMedicine)),
      ],
    );
  }

  Future<void> _save() async {
    try {
      final saved = await ref
          .read(medicineLibraryProvider.notifier)
          .save(
            id: widget.initial?.id,
            brandName: _brand.text,
            genericName: _generic.text,
            strength: _strength.text,
            dosageForm: _form.text,
            manufacturer: _manufacturer.text,
            category: _category.text,
            notes: _notes.text,
          );
      if (mounted) Navigator.pop(context, saved);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }
}
