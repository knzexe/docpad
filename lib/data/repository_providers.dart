import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/advice/repositories/advice_repository.dart';
import '../features/medicine/repositories/catalog_cache_repository.dart';
import '../features/medicine/repositories/medicine_repository.dart';
import '../features/patients/repositories/patient_repository.dart';
import '../features/pdf/services/prescription_pdf_service.dart';
import '../features/prescription/repositories/prescription_repository.dart';
import '../features/settings/repositories/profile_repository.dart';
import '../features/settings/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw StateError('SettingsRepository was not initialized.');
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw StateError('ProfileRepository was not initialized.');
});

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  throw StateError('PrescriptionRepository was not initialized.');
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  throw StateError('PatientRepository was not initialized.');
});

final adviceRepositoryProvider = Provider<AdviceRepository>((ref) {
  throw StateError('AdviceRepository was not initialized.');
});

final catalogCacheRepositoryProvider = Provider<CatalogCacheRepository>((ref) {
  throw StateError('CatalogCacheRepository was not initialized.');
});

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  throw StateError('MedicineRepository was not initialized.');
});

final pdfServiceProvider = Provider<PrescriptionPdfService>((ref) {
  return PrescriptionPdfService();
});
