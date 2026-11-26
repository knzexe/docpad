import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/constants/clinic_branding.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/dates.dart';
import '../../../data/repository_providers.dart';
import '../../settings/models/doctor_profile.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/prescription.dart';
import '../providers/editor_provider.dart';

class PrescriptionPreviewScreen extends ConsumerStatefulWidget {
  const PrescriptionPreviewScreen({super.key, required this.prescriptionId});

  final String prescriptionId;

  @override
  ConsumerState<PrescriptionPreviewScreen> createState() =>
      _PrescriptionPreviewScreenState();
}

class _PrescriptionPreviewScreenState
    extends ConsumerState<PrescriptionPreviewScreen> {
  String? _busy;

  Future<Prescription?> _savedPrescription() async {
    final current = ref.read(editorProvider).prescription;
    if (current == null || current.id != widget.prescriptionId) return null;
    final saved = await ref.read(editorProvider.notifier).saveDraft();
    if (!saved) return null;
    final latest = ref.read(editorProvider).prescription;
    if (latest == null || latest.id != widget.prescriptionId) return null;
    return latest;
  }

  Future<void> _export() async {
    final strings = ref.read(stringsProvider);
    setState(() => _busy = 'pdf');
    try {
      final prescription = await _savedPrescription();
      if (prescription == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.saveFailed)));
        return;
      }
      final bytes = await ref
          .read(pdfServiceProvider)
          .generatePrescriptionPdf(prescription);
      final stem = prescription.id.length <= 8
          ? prescription.id
          : prescription.id.substring(0, 8);
      final uri = await FilePicker.saveFile(
        fileName: '${ClinicBranding.filePrefix}-$stem.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      if (!mounted) return;
      final message = uri == null ? strings.exportCancelled : strings.pdfSaved;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.pdfFailed)));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _print() async {
    final strings = ref.read(stringsProvider);
    setState(() => _busy = 'print');
    try {
      final prescription = await _savedPrescription();
      if (prescription == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.saveFailed)));
        return;
      }
      await ref.read(pdfServiceProvider).previewAndPrint(prescription);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.printCompleted)));
    } catch (error) {
      if (!mounted) return;
      final cancelled =
          error is AppException && error.code == 'print_cancelled';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cancelled ? strings.printCancelled : strings.printFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _finalize() async {
    final strings = ref.read(stringsProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.finalize),
        content: Text(strings.finalizeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.finalize),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final saved = await ref.read(editorProvider.notifier).finalize();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? strings.saved : strings.missingFields)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final editor = ref.watch(editorProvider);
    final compactActions = Breakpoints.usesCompactActions(
      MediaQuery.sizeOf(context).width,
    );
    final prescription = editor.prescription?.id == widget.prescriptionId
        ? editor.prescription
        : null;
    final profile = ref.watch(profileProvider);
    final shown = prescription?.copyWith(header: profile);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('preview-back'),
          tooltip: strings.back,
          onPressed: () => context.pop(),
          icon: const Icon(AppIcons.chevronLeft),
        ),
        title: Text(strings.preview),
        actions: [
          if (shown != null) ...[
            if (compactActions)
              IconButton(
                key: const Key('finalize'),
                tooltip: strings.finalize,
                onPressed: _busy == null ? _finalize : null,
                icon: const Icon(Icons.task_alt_outlined),
              )
            else
              TextButton(
                key: const Key('finalize'),
                onPressed: _busy == null ? _finalize : null,
                child: Text(strings.finalize),
              ),
            if (compactActions)
              IconButton(
                key: const Key('export-pdf'),
                tooltip: _busy == 'pdf' ? strings.saving : strings.exportPdf,
                onPressed: _busy == null ? _export : null,
                icon: const Icon(Icons.file_download_outlined),
              )
            else
              TextButton(
                key: const Key('export-pdf'),
                onPressed: _busy == null ? _export : null,
                child: Text(
                  _busy == 'pdf' ? strings.saving : strings.exportPdf,
                ),
              ),
            if (compactActions)
              IconButton(
                key: const Key('print-pdf'),
                tooltip: _busy == 'print' ? strings.saving : strings.print,
                onPressed: _busy == null ? _print : null,
                icon: const Icon(Icons.print_outlined),
              )
            else
              TextButton(
                key: const Key('print-pdf'),
                onPressed: _busy == null ? _print : null,
                child: Text(_busy == 'print' ? strings.saving : strings.print),
              ),
          ],
        ],
      ),
      body: shown == null
          ? Center(child: Text(strings.missingPrescription))
          : _Paper(prescription: shown),
    );
  }
}

class _Paper extends ConsumerWidget {
  const _Paper({required this.prescription});

  final dynamic prescription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final rx = prescription;
    final doctor = rx.header ?? const DoctorProfile();
    final theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.page,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.compact),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (rx.isDraft)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        strings.draftBanner,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  Text(
                    doctor.name.trim().isEmpty
                        ? strings.doctorNameMissingPdf
                        : doctor.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  for (final line in [
                    doctor.designation,
                    if (doctor.registrationNumber.trim().isNotEmpty)
                      '${strings.registrationNumber}: ${doctor.registrationNumber}',
                    doctor.clinicName,
                    doctor.clinicAddress,
                    doctor.contact,
                    doctor.headerExtra,
                  ].where((line) => line.trim().isNotEmpty))
                    Text(line, textAlign: TextAlign.center),
                  const Divider(height: 28),
                  _row(strings.patientName, rx.patient.name, strings),
                  _row(strings.age, rx.patient.age?.toString(), strings),
                  _row(strings.sex, strings.sexLabel(rx.patient.sex), strings),
                  _row(strings.phone, rx.patient.phone, strings),
                  _row(
                    strings.prescriptionDate,
                    formatDate(
                      rx.patient.prescriptionDate,
                      languageCode: strings.languageCode,
                    ),
                    strings,
                  ),
                  const Divider(height: 28),
                  _block(strings.chiefComplaint, rx.chiefComplaint, strings),
                  _block(strings.history, rx.history, strings),
                  _block(strings.medicalHistory, rx.medicalHistory, strings),
                  _block(
                    strings.examinationNotes,
                    rx.examinationNotes,
                    strings,
                  ),
                  _block(strings.assessment, rx.assessment, strings),
                  _block(
                    strings.investigationNotes,
                    rx.investigationNotes,
                    strings,
                  ),
                  const Divider(height: 28),
                  Text(strings.rx, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (rx.medicines.isEmpty)
                    Text(strings.noMedicinesRecorded)
                  else
                    for (var i = 0; i < rx.medicines.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${i + 1}. ${rx.medicines[i].brandName}\n${strings.dose}: ${rx.medicines[i].dose}\n${strings.frequency}: ${rx.medicines[i].frequency}\n${strings.duration}: ${rx.medicines[i].duration}',
                        ),
                      ),
                  const SizedBox(height: 8),
                  Text(strings.advicePdf, style: theme.textTheme.titleMedium),
                  if (rx.advice.isEmpty)
                    Text(strings.notRecorded)
                  else
                    for (var i = 0; i < rx.advice.length; i++)
                      Text('${i + 1}. ${rx.advice[i]}'),
                  const SizedBox(height: 12),
                  Text(
                    '${strings.nextVisit}: ${rx.nextVisit == null ? strings.notRecorded : formatDate(rx.nextVisit, languageCode: strings.languageCode)}',
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 160,
                          height: 1,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          doctor.name.trim().isEmpty
                              ? strings.doctorNameMissingPdf
                              : doctor.name,
                        ),
                        Text(strings.signature),
                      ],
                    ),
                  ),
                  if (rx.usesFixtureCatalog) ...[
                    const SizedBox(height: 16),
                    Text(
                      strings.fixturePdfNote,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String? value, dynamic strings) {
    final shown = (value == null || value.trim().isEmpty)
        ? strings.notRecorded as String
        : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $shown'),
    );
  }

  Widget _block(String label, String value, dynamic strings) {
    final shown = value.trim().isEmpty ? strings.notRecorded as String : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label\n$shown'),
    );
  }
}
