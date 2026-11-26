import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloud/clinic_sync_service.dart';
import 'local/encrypted_backup_service.dart';
import '../features/advice/repositories/advice_repository.dart';
import '../features/medicine/repositories/medicine_repository.dart';
import '../features/patients/repositories/patient_repository.dart';
import '../features/pdf/services/prescription_pdf_service.dart';
import '../features/prescription/repositories/prescription_repository.dart';
import '../features/settings/repositories/profile_repository.dart';
import '../features/settings/repositories/settings_repository.dart';

final clinicSyncServiceProvider = Provider<ClinicSyncService>((ref) {
  final service = ClinicSyncService.unconfigured();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final encryptedBackupServiceProvider = Provider<EncryptedBackupService>((ref) {
  throw StateError('EncryptedBackupService was not initialized.');
});

final clinicSyncStatusProvider = StreamProvider<ClinicSyncStatus>((ref) async* {
  final service = ref.watch(clinicSyncServiceProvider);
  yield service.status;
  yield* service.statusChanges;
});

final clinicDataChangesProvider = StreamProvider<ClinicDataChange>((ref) {
  return ref.watch(clinicSyncServiceProvider).changes;
});

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

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  throw StateError('MedicineRepository was not initialized.');
});

final pdfServiceProvider = Provider<PrescriptionPdfService>((ref) {
  return PrescriptionPdfService();
});
