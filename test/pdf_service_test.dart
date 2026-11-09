import 'package:docpad/features/patients/models/patient.dart';
import 'package:docpad/features/pdf/services/prescription_pdf_service.dart';
import 'package:docpad/features/prescription/models/prescribed_medicine.dart';
import 'package:docpad/features/prescription/models/prescription.dart';
import 'package:docpad/features/settings/models/doctor_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'pdf generation succeeds for empty optional fields and long Bangla text',
    () async {
      final service = PrescriptionPdfService();
      final longNote = List.filled(
        12,
        'Clinical note entered by the doctor.',
      ).join(' ');
      final prescription = Prescription(
        id: 'rx-long',
        patient: Patient(
          id: 'p1',
          name: 'Amina Rahman',
          phone: '+880 1711 223344',
          age: null,
          sex: null,
          prescriptionDate: DateTime.utc(2026, 11, 1),
        ),
        chiefComplaint: '',
        history: longNote,
        medicalHistory: '',
        investigationNotes: '',
        examinationNotes: '',
        assessment: '',
        medicines: [
          for (var i = 0; i < 24; i++)
            PrescribedMedicine(
              id: 'line-$i',
              medicineId: 'med-$i',
              brandName:
                  'FixtureBrand $i with a deliberately long display name',
              genericName: 'FixtureGeneric',
              strength: '500 mg',
              dosageForm: 'Tablet',
              sourceKind: 'fixture',
              dose: 'entered by doctor',
              frequency: 'entered by doctor',
              duration: 'entered by doctor',
              route: '',
              timing: '',
              instructions: longNote,
              quantity: '',
            ),
        ],
        advice: const ['পর্যাপ্ত পানি পান করুন'],
        nextVisit: null,
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
        isDraft: true,
        documentLanguage: 'bn',
        header: const DoctorProfile(
          name: 'Dr Example',
          clinicName: 'Example Clinic',
        ),
      );

      final bytes = await service.generatePrescriptionPdf(prescription);

      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    },
  );
}
