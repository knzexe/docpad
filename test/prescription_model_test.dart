import 'package:docpad/features/patients/models/patient.dart';
import 'package:docpad/features/prescription/models/prescribed_medicine.dart';
import 'package:docpad/features/prescription/models/prescription.dart';
import 'package:docpad/features/settings/models/doctor_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prescription json round trip preserves clinical text and order', () {
    final created = DateTime.utc(2026, 11, 1, 8);
    final original = Prescription(
      id: 'rx-1',
      patient: Patient(
        id: 'p1',
        name: 'Amina Rahman',
        phone: '01700000000',
        age: 34,
        sex: 'female',
        prescriptionDate: created,
      ),
      chiefComplaint: 'Headache',
      history: 'Two days',
      medicalHistory: 'None recorded by the doctor',
      investigationNotes: '',
      examinationNotes: 'Alert',
      assessment: 'Entered by the doctor',
      medicines: const [
        PrescribedMedicine(
          id: 'line-1',
          medicineId: 'med-fixture-1',
          brandName: 'FixtureBrand',
          genericName: 'FixtureGeneric',
          strength: '500 mg',
          dosageForm: 'Tablet',
          sourceKind: 'fixture',
          dose: '1 tablet',
          frequency: 'three times daily',
          duration: '3 days',
          route: 'oral',
          timing: 'after food',
          instructions: 'as written',
          quantity: '9',
        ),
      ],
      advice: const ['Rest'],
      nextVisit: DateTime.utc(2026, 11, 8),
      createdAt: created,
      updatedAt: created,
      isDraft: true,
      documentLanguage: 'bn',
      header: const DoctorProfile(name: 'Dr Example'),
    );

    final restored = Prescription.fromJson(original.toJson());

    expect(restored.id, 'rx-1');
    expect(restored.patient.name, 'Amina Rahman');
    expect(restored.medicalHistory, 'None recorded by the doctor');
    expect(restored.medicines.single.sourceKind, 'fixture');
    expect(restored.medicines.single.dose, '1 tablet');
    expect(restored.advice, ['Rest']);
    expect(restored.isDraft, isTrue);
    expect(restored.documentLanguage, 'bn');
    expect(restored.header?.name, 'Dr Example');
    expect(restored.nextVisit, isNotNull);
    expect(restored.bodyKey(), original.bodyKey());
  });
}
