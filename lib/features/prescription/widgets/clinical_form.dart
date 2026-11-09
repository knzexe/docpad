import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/prescription.dart';
import '../providers/editor_provider.dart';

class ClinicalForm extends ConsumerStatefulWidget {
  const ClinicalForm({super.key, required this.initial});

  final Prescription initial;

  @override
  ConsumerState<ClinicalForm> createState() => _ClinicalFormState();
}

class _ClinicalFormState extends ConsumerState<ClinicalForm> {
  late final TextEditingController _complaint;
  late final TextEditingController _history;
  late final TextEditingController _medical;
  late final TextEditingController _investigation;
  late final TextEditingController _examination;
  late final TextEditingController _assessment;

  @override
  void initState() {
    super.initState();
    final rx = widget.initial;
    _complaint = TextEditingController(text: rx.chiefComplaint);
    _history = TextEditingController(text: rx.history);
    _medical = TextEditingController(text: rx.medicalHistory);
    _investigation = TextEditingController(text: rx.investigationNotes);
    _examination = TextEditingController(text: rx.examinationNotes);
    _assessment = TextEditingController(text: rx.assessment);
  }

  @override
  void dispose() {
    _complaint.dispose();
    _history.dispose();
    _medical.dispose();
    _investigation.dispose();
    _examination.dispose();
    _assessment.dispose();
    super.dispose();
  }

  void _emit() {
    ref
        .read(editorProvider.notifier)
        .updateClinical(
          chiefComplaint: _complaint.text,
          history: _history.text,
          medicalHistory: _medical.text,
          investigationNotes: _investigation.text,
          examinationNotes: _examination.text,
          assessment: _assessment.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    return SectionCard(
      title: strings.clinicalAssessment,
      subtitle: strings.clinicalHint,
      child: Column(
        children: [
          _field(
            strings.chiefComplaint,
            _complaint,
            fieldKey: const Key('chief-complaint'),
          ),
          _field(strings.history, _history),
          _field(strings.medicalHistory, _medical),
          _field(strings.investigationNotes, _investigation),
          _field(strings.examinationNotes, _examination),
          _field(strings.assessment, _assessment),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    Key? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          AppTextField(
            fieldKey: fieldKey,
            controller: controller,
            label: label,
            maxLines: 4,
            minLines: 3,
            onChanged: (_) {
              setState(_emit);
            },
          ),
          CharacterHint(
            length: controller.text.length,
            label: ref.read(stringsProvider).characters(controller.text.length),
          ),
        ],
      ),
    );
  }
}
