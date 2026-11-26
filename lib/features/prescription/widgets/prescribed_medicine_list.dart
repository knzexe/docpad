import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feedback_widgets.dart';
import '../../medicine/models/medicine_catalog_item.dart';
import '../../medicine/widgets/medicine_search_panel.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/prescribed_medicine.dart';
import '../providers/editor_provider.dart';

class PrescribedMedicineList extends ConsumerWidget {
  const PrescribedMedicineList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final medicines =
        ref.watch(editorProvider).prescription?.medicines ?? const [];
    return SectionCard(
      title: strings.prescribedMedicines,
      child: medicines.isEmpty
          ? Text(
              strings.emptyMedicines,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : Column(
              children: [
                for (var index = 0; index < medicines.length; index++)
                  _MedicineRow(
                    index: index,
                    item: medicines[index],
                    last: index == medicines.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _MedicineRow extends ConsumerWidget {
  const _MedicineRow({
    required this.index,
    required this.item,
    required this.last,
  });

  final int index;
  final PrescribedMedicine item;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final catalog = [
      if (item.genericName != null) item.genericName!,
      if (item.strength != null) item.strength!,
      if (item.dosageForm != null) item.dosageForm!,
    ].join(' | ');
    return Card(
      margin: EdgeInsets.only(bottom: last ? 0 : AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.brandName, style: theme.textTheme.titleMedium),
            if (catalog.isNotEmpty)
              Text(catalog, style: theme.textTheme.bodySmall),
            if (item.sourceKind == 'fixture')
              Text(strings.demoTitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text('${strings.dose}: ${item.dose}'),
            Text('${strings.frequency}: ${item.frequency}'),
            Text('${strings.duration}: ${item.duration}'),
            if (item.instructions.trim().isNotEmpty)
              Text('${strings.specialInstructions}: ${item.instructions}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: strings.moveUp,
                  onPressed: index == 0
                      ? null
                      : () => ref
                            .read(editorProvider.notifier)
                            .moveMedicine(index, -1),
                  icon: const Icon(AppIcons.arrowUp, size: 18),
                ),
                IconButton(
                  tooltip: strings.moveDown,
                  onPressed: last
                      ? null
                      : () => ref
                            .read(editorProvider.notifier)
                            .moveMedicine(index, 1),
                  icon: const Icon(AppIcons.arrowDown, size: 18),
                ),
                IconButton(
                  tooltip: strings.edit,
                  onPressed: () async {
                    final updated = await showMedicineEntry(
                      context,
                      brand: MedicineCatalogItem(
                        id: item.medicineId,
                        brandName: item.brandName,
                        genericName: item.genericName,
                        strength: item.strength,
                        dosageForm: item.dosageForm,
                        manufacturer: item.manufacturer,
                        sourceKind: item.sourceKind,
                      ),
                      existing: item,
                    );
                    if (updated != null) {
                      ref.read(editorProvider.notifier).updateMedicine(updated);
                    }
                  },
                  icon: const Icon(AppIcons.edit3, size: 18),
                ),
                IconButton(
                  tooltip: strings.remove,
                  onPressed: () async {
                    final ok = await confirmDestructive(
                      context,
                      strings: strings,
                      title: strings.removeMedicineTitle,
                      body: strings.removeMedicineBody,
                      confirmLabel: strings.remove,
                    );
                    if (ok) {
                      ref.read(editorProvider.notifier).removeMedicine(item.id);
                    }
                  },
                  icon: Icon(
                    AppIcons.trash2,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
