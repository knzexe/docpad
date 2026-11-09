import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feedback_widgets.dart';
import '../../../core/widgets/responsive.dart';
import '../../patients/models/patient.dart';
import '../../prescription/providers/editor_provider.dart';
import '../../prescription/providers/record_providers.dart';
import '../../settings/providers/settings_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final profile = ref.watch(profileProvider);
    final prescriptions = ref.watch(prescriptionListProvider);
    final patients = ref.watch(patientListProvider);
    final language = strings.languageCode;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        PageWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name.trim().isEmpty
                    ? strings.appName
                    : profile.name.trim(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                formatDate(DateTime.now(), languageCode: language),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _Disclaimer(text: strings.disclaimer),
              const SizedBox(height: 16),
              prescriptions.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => _ErrorRetry(
                  message: strings.couldNotRead,
                  label: strings.retry,
                  onRetry: () =>
                      ref.read(prescriptionListProvider.notifier).refresh(),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: AppIcons.fileText,
                      title: strings.emptyTitle,
                      body: strings.emptyBody,
                      action: FilledButton.icon(
                        key: const Key('new-prescription'),
                        onPressed: () => _start(ref, context),
                        icon: const Icon(AppIcons.plus),
                        label: Text(strings.createFirst),
                      ),
                    );
                  }
                  final drafts = items
                      .where((item) => item.isDraft)
                      .take(5)
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            key: const Key('new-prescription'),
                            onPressed: () => _start(ref, context),
                            icon: const Icon(AppIcons.plus),
                            label: Text(strings.newPrescription),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/advice'),
                            child: Text(strings.adviceLibrary),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/settings'),
                            child: Text(strings.settings),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        strings.recentPrescriptions,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      for (final item in items.take(6))
                        _PrescriptionTile(
                          itemId: item.id,
                          name: item.patient.name,
                          date: item.patient.prescriptionDate,
                          draft: item.isDraft,
                        ),
                      const SizedBox(height: 22),
                      Text(
                        strings.drafts,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      if (drafts.isEmpty)
                        Text(
                          strings.noDrafts,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        for (final item in drafts)
                          _PrescriptionTile(
                            itemId: item.id,
                            name: item.patient.name,
                            date: item.patient.prescriptionDate,
                            draft: true,
                          ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              Text(
                strings.recentPatients,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              patients.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => Text(strings.couldNotRead),
                data: (items) {
                  if (items.isEmpty) {
                    return Text(
                      strings.noPatients,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return Column(
                    children: [
                      for (final patient in items.take(5))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            patient.name.trim().isEmpty
                                ? strings.notRecorded
                                : patient.name,
                          ),
                          subtitle: Text(
                            formatDate(
                              patient.prescriptionDate,
                              languageCode: language,
                            ),
                          ),
                          onTap: () => context.go('/patients'),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => context.go('/patients'),
                          child: Text(strings.seeAll),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _start(WidgetRef ref, BuildContext context) {
    ref.read(editorProvider.notifier).startNew();
    final id = ref.read(editorProvider).prescription?.id;
    if (id != null) context.go('/prescription/$id');
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({
    required this.message,
    required this.label,
    required this.onRetry,
  });

  final String message;
  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: Text(label)),
      ],
    );
  }
}

class _PrescriptionTile extends ConsumerWidget {
  const _PrescriptionTile({
    required this.itemId,
    required this.name,
    required this.date,
    required this.draft,
  });

  final String itemId;
  final String name;
  final DateTime date;
  final bool draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name.trim().isEmpty ? strings.notRecorded : name),
        subtitle: Text(formatDate(date, languageCode: strings.languageCode)),
        trailing: draft
            ? Text(strings.draft, style: Theme.of(context).textTheme.bodySmall)
            : const Icon(AppIcons.chevronRight, size: 18),
        onTap: () => context.go('/prescription/$itemId'),
      ),
    );
  }
}

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final patients = ref.watch(patientListProvider);
    final filter = _query.text.trim().toLowerCase();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PageWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.patients,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _query,
                decoration: InputDecoration(hintText: strings.searchPatients),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              patients.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(strings.couldNotRead),
                data: (items) {
                  final visible = items.where((patient) {
                    if (filter.isEmpty) return true;
                    return patient.name.toLowerCase().contains(filter) ||
                        patient.phone.toLowerCase().contains(filter);
                  }).toList();
                  if (visible.isEmpty) {
                    return EmptyState(
                      icon: AppIcons.users,
                      title: strings.patients,
                      body: strings.noPatients,
                    );
                  }
                  return Column(
                    children: [
                      for (final patient in visible)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              patient.name.trim().isEmpty
                                  ? strings.notRecorded
                                  : patient.name,
                            ),
                            subtitle: Text(
                              [
                                    if (patient.age != null)
                                      '${strings.age} ${patient.age}',
                                    strings.sexLabel(patient.sex),
                                    patient.phone,
                                  ]
                                  .where((part) => part.trim().isNotEmpty)
                                  .join(' | '),
                            ),
                            trailing:
                                Breakpoints.isMobile(
                                  MediaQuery.sizeOf(context).width,
                                )
                                ? null
                                : TextButton(
                                    onPressed: () => _newFor(patient),
                                    child: Text(strings.newForPatient),
                                  ),
                            onTap: () => _show(patient),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _newFor(Patient patient) {
    ref.read(editorProvider.notifier).startNew(prefilled: patient);
    final id = ref.read(editorProvider).prescription?.id;
    if (id != null) context.go('/prescription/$id');
  }

  Future<void> _show(Patient patient) async {
    final strings = ref.read(stringsProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patient.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${strings.phone}: ${patient.phone}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _newFor(patient);
                },
                child: Text(strings.newForPatient),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final ok = await confirmDestructive(
                    context,
                    strings: strings,
                    title: strings.deletePatientTitle,
                    body: strings.deletePatientBody,
                    confirmLabel: strings.delete,
                  );
                  if (!ok || !context.mounted) return;
                  await ref
                      .read(patientListProvider.notifier)
                      .delete(patient.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(strings.delete),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
