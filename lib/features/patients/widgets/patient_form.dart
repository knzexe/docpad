import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/patient.dart';
import '../../prescription/providers/editor_provider.dart';

class PatientForm extends ConsumerStatefulWidget {
  const PatientForm({super.key, required this.initial});

  final Patient initial;

  @override
  ConsumerState<PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends ConsumerState<PatientForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _age;
  late final TextEditingController _code;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  late DateTime _date;
  String? _sex;

  @override
  void initState() {
    super.initState();
    final patient = widget.initial;
    _name = TextEditingController(text: patient.name);
    _phone = TextEditingController(text: patient.phone);
    _age = TextEditingController(text: patient.age?.toString() ?? '');
    _code = TextEditingController(text: patient.patientCode ?? '');
    _address = TextEditingController(text: patient.address ?? '');
    _notes = TextEditingController(text: patient.identificationNotes ?? '');
    _date = patient.prescriptionDate;
    _sex = patient.sex;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _age.dispose();
    _code.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _emit() {
    final ageText = _age.text.trim();
    ref
        .read(editorProvider.notifier)
        .updatePatient(
          Patient(
            id: widget.initial.id,
            name: _name.text,
            phone: _phone.text,
            age: int.tryParse(ageText),
            sex: _sex,
            prescriptionDate: _date,
            address: _blank(_address.text),
            patientCode: _blank(_code.text),
            identificationNotes: _blank(_notes.text),
          ),
        );
  }

  String? _blank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _error(AppStrings strings, String key) {
    final code = ref.watch(editorProvider).fieldErrors[key];
    return switch (code) {
      'name' => strings.nameRequired,
      'phone' => strings.phoneRequired,
      'phone_invalid' => strings.phoneInvalid,
      'age' => strings.ageRequired,
      'age_invalid' => strings.ageInvalid,
      'sex' => strings.sexRequired,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final language = strings.languageCode;
    return SectionCard(
      title: strings.patientInformation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            fieldKey: const Key('patient-name'),
            controller: _name,
            label: strings.patientName,
            requiredField: true,
            errorText: _error(strings, 'name'),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          AppTextField(
            fieldKey: const Key('patient-phone'),
            controller: _phone,
            label: strings.phone,
            requiredField: true,
            keyboardType: TextInputType.phone,
            errorText: _error(strings, 'phone'),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          AppTextField(
            fieldKey: const Key('patient-age'),
            controller: _age,
            label: strings.age,
            requiredField: true,
            keyboardType: TextInputType.number,
            errorText: _error(strings, 'age'),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          Text(
            '${strings.sex} *',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            key: const Key('patient-sex'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in const [
                'female',
                'male',
                'intersex',
                'undisclosed',
              ])
                ChoiceChip(
                  label: Text(strings.sexLabel(option)),
                  selected: _sex == option,
                  onSelected: (_) {
                    setState(() => _sex = option);
                    _emit();
                  },
                ),
            ],
          ),
          if (_error(strings, 'sex') != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _error(strings, 'sex')!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            '${strings.prescriptionDate} *',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              setState(() => _date = picked);
              _emit();
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(formatDate(_date, languageCode: language)),
          ),
          const SizedBox(height: 18),
          Text(strings.optional, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          AppTextField(
            controller: _code,
            label: strings.patientId,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _address,
            label: strings.address,
            maxLines: 2,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _notes,
            label: strings.identificationNotes,
            maxLines: 2,
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}
