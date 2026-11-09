import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';

import 'package:uuid/uuid.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feedback_widgets.dart';
import '../../prescription/models/prescribed_medicine.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/medex_brand.dart';
import '../providers/medicine_providers.dart';

class MedicineSearchPanel extends ConsumerStatefulWidget {
  const MedicineSearchPanel({super.key, required this.onBrand});

  final ValueChanged<MedExBrand> onBrand;

  @override
  ConsumerState<MedicineSearchPanel> createState() =>
      _MedicineSearchPanelState();
}

class _MedicineSearchPanelState extends ConsumerState<MedicineSearchPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final state = ref.watch(medicineSearchProvider);
    final health = ref.watch(catalogHealthProvider).asData?.value;
    final notifier = ref.read(medicineSearchProvider.notifier);
    final showDemo =
        (health?.isFixture ?? false) ||
        (state.source?.isFixture ?? false) ||
        state.brands.any((item) => item.isFixture) ||
        state.generics.any((item) => item.isFixture);
    final showLive =
        !showDemo &&
        (state.source?.isLive ?? false) &&
        state.query.trim().isNotEmpty;

    return SectionCard(
      title: strings.medicineSearch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDemo)
            InfoBanner(message: '${strings.demoTitle}. ${strings.demoBody}'),
          if (showLive) InfoBanner(message: strings.liveBody),
          if (state.fromCache && state.cachedAt != null)
            InfoBanner(
              message:
                  '${strings.cachedLead} ${strings.cachedAt(describeAge(state.cachedAt!))} ${strings.notVerified}.',
            ),
          if (state.detailWarning)
            InfoBanner(message: strings.detailsUnavailable),
          SegmentedButton<CatalogMode>(
            segments: [
              ButtonSegment(
                value: CatalogMode.brands,
                label: Text(strings.brands),
              ),
              ButtonSegment(
                value: CatalogMode.generics,
                label: Text(strings.generics),
              ),
            ],
            selected: {state.mode},
            onSelectionChanged: (value) => notifier.setMode(value.first),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('medicine-search'),
            controller: _controller,
            decoration: InputDecoration(
              hintText: strings.searchHint,
              prefixIcon: const Icon(AppIcons.search, size: 18),
            ),
            onChanged: notifier.setQuery,
          ),
          if (state.mode == CatalogMode.generics) ...[
            const SizedBox(height: 10),
            Text(
              strings.genericsNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            InfoBanner(message: state.error!.message, danger: true)
          else if (state.query.trim().isNotEmpty &&
              ((state.mode == CatalogMode.brands && state.brands.isEmpty) ||
                  (state.mode == CatalogMode.generics &&
                      state.generics.isEmpty)))
            Text(
              strings.noResults,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (state.mode == CatalogMode.brands) ...[
            for (final brand in state.brands)
              _BrandTile(
                brand: brand,
                strings: strings,
                onTap: () => widget.onBrand(brand),
              ),
          ] else ...[
            for (final generic in state.generics)
              _GenericTile(generic: generic),
          ],
          if (state.hasNext && !state.loading)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: state.loadingMore ? null : notifier.loadMore,
                child: Text(
                  state.loadingMore ? strings.loading : strings.loadMore,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({
    required this.brand,
    required this.strings,
    required this.onTap,
  });

  final MedExBrand brand;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = [
      if (brand.strength != null) brand.strength!,
      if (brand.dosageForm != null) brand.dosageForm!,
    ].join(' / ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: InkWell(
          key: Key('result-${brand.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        brand.brandName,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (brand.isFixture) _SourceChip(label: strings.demoTitle),
                  ],
                ),
                if (brand.genericName != null)
                  Text(brand.genericName!, style: theme.textTheme.bodyMedium),
                if (detail.isNotEmpty)
                  Text(detail, style: theme.textTheme.bodySmall),
                if (brand.manufacturer != null)
                  Text(
                    '${strings.manufacturer}: ${brand.manufacturer}',
                    style: theme.textTheme.bodySmall,
                  ),
                Text(
                  '${strings.sourceLabel}: ${brand.sourceKind ?? strings.notRecorded}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenericTile extends StatelessWidget {
  const _GenericTile({required this.generic});

  final MedExGeneric generic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(generic.name),
        subtitle: Text(
          [
            if (generic.isFixture) 'DEMO DATA',
            if (generic.description != null) generic.description!,
          ].join(' | '),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8A5A00),
        ),
      ),
    );
  }
}

Future<PrescribedMedicine?> showMedicineEntry(
  BuildContext context, {
  required MedExBrand brand,
  PrescribedMedicine? existing,
}) {
  final mobile = MediaQuery.sizeOf(context).width < 720;
  final child = MedicineEntryForm(brand: brand, existing: existing);
  if (mobile) {
    final height = MediaQuery.sizeOf(context).height;
    return showModalBottomSheet<PrescribedMedicine>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * 0.92),
          child: child,
        ),
      ),
    );
  }
  return showDialog<PrescribedMedicine>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: child,
      ),
    ),
  );
}

class MedicineEntryForm extends ConsumerStatefulWidget {
  const MedicineEntryForm({super.key, required this.brand, this.existing});

  final MedExBrand brand;
  final PrescribedMedicine? existing;

  @override
  ConsumerState<MedicineEntryForm> createState() => _MedicineEntryFormState();
}

class _MedicineEntryFormState extends ConsumerState<MedicineEntryForm> {
  late final TextEditingController _dose;
  late final TextEditingController _frequency;
  late final TextEditingController _duration;
  late final TextEditingController _route;
  late final TextEditingController _timing;
  late final TextEditingController _instructions;
  late final TextEditingController _quantity;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _dose = TextEditingController(text: existing?.dose ?? '');
    _frequency = TextEditingController(text: existing?.frequency ?? '');
    _duration = TextEditingController(text: existing?.duration ?? '');
    _route = TextEditingController(text: existing?.route ?? '');
    _timing = TextEditingController(text: existing?.timing ?? '');
    _instructions = TextEditingController(text: existing?.instructions ?? '');
    _quantity = TextEditingController(text: existing?.quantity ?? '');
  }

  @override
  void dispose() {
    _dose.dispose();
    _frequency.dispose();
    _duration.dispose();
    _route.dispose();
    _timing.dispose();
    _instructions.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _submit(AppStrings strings) {
    if (_dose.text.trim().isEmpty ||
        _frequency.text.trim().isEmpty ||
        _duration.text.trim().isEmpty) {
      setState(() => _error = strings.requiredEntry);
      return;
    }
    final brand = widget.brand;
    final medicine = PrescribedMedicine(
      id: widget.existing?.id ?? const Uuid().v4(),
      medicineId: brand.id,
      brandName: brand.brandName,
      genericName: brand.genericName,
      strength: brand.strength,
      dosageForm: brand.dosageForm,
      manufacturer: brand.manufacturer,
      sourceKind: brand.sourceKind,
      dose: _dose.text.trim(),
      frequency: _frequency.text.trim(),
      duration: _duration.text.trim(),
      route: _route.text.trim(),
      timing: _timing.text.trim(),
      instructions: _instructions.text.trim(),
      quantity: _quantity.text.trim(),
    );
    Navigator.pop(context, medicine);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final brand = widget.brand;
    final catalog = [
      if (brand.genericName != null) brand.genericName!,
      if (brand.strength != null) brand.strength!,
      if (brand.dosageForm != null) brand.dosageForm!,
      if (brand.manufacturer != null) brand.manufacturer!,
    ].join(' | ');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.existing == null ? strings.addToPrescription : strings.edit,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            strings.catalogInfo,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(brand.brandName, style: Theme.of(context).textTheme.bodyLarge),
          if (catalog.isNotEmpty)
            Text(catalog, style: Theme.of(context).textTheme.bodySmall),
          if (brand.isFixture)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${strings.demoTitle}. ${strings.notVerified}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            strings.yourInstructions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            strings.instructionHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          AppTextField(
            fieldKey: const Key('dose-field'),
            controller: _dose,
            label: strings.dose,
            requiredField: true,
          ),
          const SizedBox(height: 12),
          AppTextField(
            fieldKey: const Key('frequency-field'),
            controller: _frequency,
            label: strings.frequency,
            requiredField: true,
          ),
          const SizedBox(height: 12),
          AppTextField(
            fieldKey: const Key('duration-field'),
            controller: _duration,
            label: strings.duration,
            requiredField: true,
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _route, label: strings.route),
          const SizedBox(height: 12),
          AppTextField(controller: _timing, label: strings.timing),
          const SizedBox(height: 12),
          AppTextField(
            controller: _instructions,
            label: strings.specialInstructions,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _quantity, label: strings.quantity),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('add-medicine-confirm'),
              onPressed: () => _submit(strings),
              child: Text(
                widget.existing == null
                    ? strings.addToPrescription
                    : strings.saveChanges,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
