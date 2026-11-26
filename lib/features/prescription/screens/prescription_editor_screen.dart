import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/widgets/feedback_widgets.dart';
import '../../advice/widgets/advice_picker.dart';
import '../../medicine/widgets/medicine_search_panel.dart';
import '../../patients/models/patient.dart';
import '../../patients/widgets/patient_form.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/prescription.dart';
import '../providers/editor_provider.dart';
import '../widgets/clinical_form.dart';
import '../widgets/follow_up_section.dart';
import '../widgets/prescribed_medicine_list.dart';

class PrescriptionEditorScreen extends ConsumerStatefulWidget {
  const PrescriptionEditorScreen({
    super.key,
    required this.prescriptionId,
    this.prefilled,
  });

  final String? prescriptionId;
  final Patient? prefilled;

  @override
  ConsumerState<PrescriptionEditorScreen> createState() =>
      _PrescriptionEditorScreenState();
}

class _PrescriptionEditorScreenState
    extends ConsumerState<PrescriptionEditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void didUpdateWidget(covariant PrescriptionEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prescriptionId != widget.prescriptionId) {
      _open();
    }
  }

  void _open() {
    ref
        .read(editorProvider.notifier)
        .openFromRoute(id: widget.prescriptionId, prefilled: widget.prefilled);
  }

  Future<void> _leave() async {
    final editor = ref.read(editorProvider);
    final strings = ref.read(stringsProvider);
    if (!editor.dirty) {
      if (mounted) context.go('/');
      return;
    }
    final choice = await confirmLeave(context, strings: strings);
    if (!mounted) return;
    if (choice == LeaveChoice.cancel) return;
    if (choice == LeaveChoice.save) {
      final saved = await ref.read(editorProvider.notifier).saveDraft();
      if (!saved || !mounted) return;
    } else {
      await ref.read(editorProvider.notifier).discardEdits();
    }
    if (mounted) context.go('/');
  }

  Future<void> _delete() async {
    final strings = ref.read(stringsProvider);
    final ok = await confirmDestructive(
      context,
      strings: strings,
      title: strings.deletePrescription,
      body: strings.deletePrescriptionBody,
      confirmLabel: strings.delete,
    );
    if (!ok || !mounted) return;
    final deleted = await ref.read(editorProvider.notifier).deleteCurrent();
    if (deleted && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final editor = ref.watch(editorProvider);
    final compactActions = Breakpoints.usesCompactActions(
      MediaQuery.sizeOf(context).width,
    );
    ref.listen(editorProvider, (previous, next) {
      if (next.notice == 'saved' && previous?.notice != 'saved') {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.saved)));
      }
      if (next.saveError == 'failed' && previous?.saveError != 'failed') {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.saveFailed)));
      }
    });

    final prescription = editor.prescription;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: strings.back,
            onPressed: _leave,
            icon: const Icon(AppIcons.chevronLeft),
          ),
          title: Text(
            prescription?.isDraft ?? true ? strings.draft : strings.finalized,
          ),
          actions: [
            if (prescription != null) ...[
              if (compactActions)
                IconButton(
                  key: const Key('save-draft'),
                  tooltip: editor.saving ? strings.saving : strings.saveDraft,
                  onPressed: editor.saving
                      ? null
                      : () => ref.read(editorProvider.notifier).saveDraft(),
                  icon: editor.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                )
              else
                TextButton(
                  key: const Key('save-draft'),
                  onPressed: editor.saving
                      ? null
                      : () => ref.read(editorProvider.notifier).saveDraft(),
                  child: Text(
                    editor.saving ? strings.saving : strings.saveDraft,
                  ),
                ),
              if (compactActions)
                IconButton(
                  key: const Key('open-preview'),
                  tooltip: strings.preview,
                  onPressed: () =>
                      context.push('/prescription/${prescription.id}/preview'),
                  icon: const Icon(Icons.visibility_outlined),
                )
              else
                TextButton(
                  key: const Key('open-preview'),
                  onPressed: () =>
                      context.push('/prescription/${prescription.id}/preview'),
                  child: Text(strings.preview),
                ),
              IconButton(
                tooltip: strings.delete,
                onPressed: _delete,
                icon: const Icon(AppIcons.trash2),
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: editor.loading
              ? const Center(child: CircularProgressIndicator())
              : editor.missing
              ? Center(child: Text(strings.missingPrescription))
              : editor.loadError || prescription == null
              ? Center(child: Text(strings.couldNotOpen))
              : _EditorBody(prescription: prescription),
        ),
      ),
    );
  }
}

class _EditorBody extends ConsumerWidget {
  const _EditorBody({required this.prescription});

  final Prescription prescription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final editor = ref.watch(editorProvider);
    final left = <Widget>[
      const OfflineBanner(),
      if (editor.returnedToDraft) InfoBanner(message: strings.returnedToDraft),
      if (editor.fieldErrors.isNotEmpty)
        InfoBanner(message: strings.missingFields, danger: true),
      PatientForm(
        key: ValueKey('patient-${prescription.id}'),
        initial: prescription.patient,
      ),
      const SizedBox(height: 16),
      ClinicalForm(
        key: ValueKey('clinical-${prescription.id}'),
        initial: prescription,
      ),
      const SizedBox(height: 16),
      const AdvicePicker(),
      const SizedBox(height: 16),
      const FollowUpSection(),
    ];
    final right = <Widget>[
      MedicineSearchPanel(
        onBrand: (brand) async {
          final medicine = await showMedicineEntry(context, brand: brand);
          if (medicine != null) {
            ref.read(editorProvider.notifier).addMedicine(medicine);
          }
        },
      ),
      const SizedBox(height: 16),
      const PrescribedMedicineList(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.xxl,
        );
        if (Breakpoints.usesEditorColumns(constraints.maxWidth)) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.editorMaxWidth,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      key: const Key('editor-left'),
                      padding: padding,
                      children: left,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      key: const Key('editor-right'),
                      padding: padding,
                      children: right,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          key: const Key('editor-left'),
          padding: padding,
          children: [...left, const SizedBox(height: 16), ...right],
        );
      },
    );
  }
}
