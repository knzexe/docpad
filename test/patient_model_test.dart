import 'package:docpad/features/patients/models/patient.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('patient json round trip keeps optional fields nullable', () {
    final patient = Patient(
      id: 'p1',
      name: 'Amina Rahman',
      phone: '+880 1711 223344',
      age: 34,
      sex: 'female',
      prescriptionDate: DateTime.utc(2026, 11, 1),
      address: 'Dhaka',
      patientCode: 'EXT-1',
      identificationNotes: null,
    );

    final restored = Patient.fromJson(patient.toJson());

    expect(restored.id, patient.id);
    expect(restored.name, patient.name);
    expect(restored.phone, patient.phone);
    expect(restored.age, 34);
    expect(restored.sex, 'female');
    expect(restored.address, 'Dhaka');
    expect(restored.patientCode, 'EXT-1');
    expect(restored.identificationNotes, isNull);
    expect(restored.prescriptionDate.toUtc(), patient.prescriptionDate);
  });

  test('patient json rejects a record without an id', () {
    expect(
      () => Patient.fromJson({
        'name': 'No id',
        'phone': '123456',
        'prescriptionDate': '2026-11-01T00:00:00.000Z',
      }),
      throwsFormatException,
    );
  });
}
