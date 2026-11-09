import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/common_widgets.dart';
import '../models/medicine.dart';
import '../providers/medicine_library_provider.dart';

class MedicineLibraryScreen extends ConsumerWidget {
  const MedicineLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicines = ref.watch(medicineLibraryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medicine Library'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              key: const Key('add-medicine'),
              onPressed: () => showMedicineLibraryForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add new medicine'),
            ),
          ),
        ],
      ),
      body: medicines.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load medicines: $error')),
        data: (items) => _MedicineList(items: items),
      ),
    );
  }
}

class _MedicineList extends StatefulWidget {
  const _MedicineList({required this.items});

  final List<Medicine> items;

  @override
  State<_MedicineList> createState() => _MedicineListState();
}

class _MedicineListState extends State<_MedicineList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final items = widget.items.where((item) {
      return query.isEmpty ||
          item.brandName.toLowerCase().contains(query) ||
          (item.genericName?.toLowerCase().contains(query) ?? false);
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          key: const Key('medicine-library-search'),
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search by brand or generic name',
          ),
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const EmptyState(
            icon: Icons.medication_outlined,
            title: 'No medicines found',
            body: 'Add medicines manually to build your private library.',
          )
        else
          for (final item in items) _MedicineCard(item: item),
      ],
    );
  }
}

class _MedicineCard extends ConsumerWidget {
  const _MedicineCard({required this.item});

  final Medicine item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        subtitle: Text([
          if (details.isNotEmpty) details,
          if (item.manufacturer != null) item.manufacturer!,
          if (item.category != null) item.category!,
        ].join('\n')),
        isThreeLine: details.isNotEmpty,
        trailing: Wrap(
          children: [
            IconButton(
              tooltip: 'Add to prescription',
              onPressed: () => context.go('/prescription/new'),
              icon: const Icon(Icons.add_circle_outline),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: () => showMedicineLibraryForm(context, initial: item),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(medicineLibraryProvider.notifier).remove(item.id);
    }
  }
}

Future<void> showMedicineLibraryForm(
  BuildContext context, {
  Medicine? initial,
}) async {
  await showDialog<void>(
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
    for (final controller in [_brand, _generic, _strength, _form, _manufacturer, _category, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add new medicine' : 'Edit medicine'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              AppTextField(controller: _brand, label: 'Brand name', requiredField: true),
              const SizedBox(height: 12),
              AppTextField(controller: _generic, label: 'Generic name'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: AppTextField(controller: _strength, label: 'Strength')),
                  const SizedBox(width: 12),
                  Expanded(child: AppTextField(controller: _form, label: 'Dosage form')),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _manufacturer, label: 'Manufacturer'),
              const SizedBox(height: 12),
              AppTextField(controller: _category, label: 'Category'),
              const SizedBox(height: 12),
              AppTextField(controller: _notes, label: 'Notes', maxLines: 3),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save medicine')),
      ],
    );
  }

  Future<void> _save() async {
    try {
      await ref.read(medicineLibraryProvider.notifier).save(
        id: widget.initial?.id,
        brandName: _brand.text,
        genericName: _generic.text,
        strength: _strength.text,
        dosageForm: _form.text,
        manufacturer: _manufacturer.text,
        category: _category.text,
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }
}
