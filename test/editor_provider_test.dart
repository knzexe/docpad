import 'package:docpad/data/local/key_value_store.dart';
import 'package:docpad/data/repository_providers.dart';
import 'package:docpad/features/patients/models/patient.dart';
import 'package:docpad/features/patients/repositories/patient_repository.dart';
import 'package:docpad/features/prescription/models/prescribed_medicine.dart';
import 'package:docpad/features/prescription/providers/editor_provider.dart';
import 'package:docpad/features/prescription/repositories/prescription_repository.dart';
import 'package:docpad/features/settings/repositories/profile_repository.dart';
import 'package:docpad/features/settings/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late PrescriptionRepository prescriptions;

  setUp(() {
    prescriptions = PrescriptionRepository(MemoryStore());
    container = ProviderContainer(
      overrides: [
        prescriptionRepositoryProvider.overrideWithValue(prescriptions),
        patientRepositoryProvider.overrideWithValue(
          PatientRepository(MemoryStore()),
        ),
        profileRepositoryProvider.overrideWithValue(
          ProfileRepository(MemoryStore()),
        ),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'finalize requires patient fields and keeps the draft on screen',
    () async {
      final editor = container.read(editorProvider.notifier);
      editor.startNew();
      final saved = await editor.finalize();
      final state = container.read(editorProvider);

      expect(saved, isFalse);
      expect(state.prescription, isNotNull);
      expect(state.prescription!.isDraft, isTrue);
      expect(state.fieldErrors['name'], 'name');
      expect(state.fieldErrors['phone'], 'phone');
      expect(await prescriptions.getAll(), isEmpty);
    },
  );

  test('two prescriptions keep separate ids when saved', () async {
    final editor = container.read(editorProvider.notifier);
    editor.startNew();
    editor.updatePatient(_patient('First'));
    final firstId = container.read(editorProvider).prescription!.id;
    expect(await editor.saveDraft(), isTrue);

    editor.startNew();
    editor.updatePatient(_patient('Second'));
    final secondId = container.read(editorProvider).prescription!.id;
    expect(await editor.saveDraft(), isTrue);

    final all = await prescriptions.getAll();
    expect(all.map((item) => item.id), containsAll([firstId, secondId]));
    expect(
      all.map((item) => item.patient.name),
      containsAll(['First', 'Second']),
    );
  });

  test(
    'medicines can be added, reordered, and removed without suggested doses',
    () {
      final editor = container.read(editorProvider.notifier);
      editor.startNew();
      editor.addMedicine(_line('a', 'First line'));
      editor.addMedicine(_line('b', 'Second line'));
      editor.moveMedicine(1, -1);
      var names = container
          .read(editorProvider)
          .prescription!
          .medicines
          .map((item) => item.id);
      expect(names, ['b', 'a']);

      editor.removeMedicine('b');
      names = container
          .read(editorProvider)
          .prescription!
          .medicines
          .map((item) => item.id);
      expect(names, ['a']);
      expect(
        container.read(editorProvider).prescription!.medicines.single.dose,
        'typed dose',
      );
    },
  );
}

Patient _patient(String name) {
  return Patient(
    id: 'patient-$name',
    name: name,
    phone: '01700000000',
    age: 30,
    sex: 'female',
    prescriptionDate: DateTime.utc(2026, 11, 1),
  );
}

PrescribedMedicine _line(String id, String doseLabel) {
  return PrescribedMedicine(
    id: id,
    medicineId: 'med-$id',
    brandName: doseLabel,
    dose: 'typed dose',
    frequency: 'typed frequency',
    duration: 'typed duration',
    route: '',
    timing: '',
    instructions: '',
    quantity: '',
  );
}
