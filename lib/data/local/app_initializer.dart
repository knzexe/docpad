import 'dart:convert';

import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/app_log.dart';
import '../cloud/clinic_sync_service.dart';
import '../cloud/cloud_synced_key_value_store.dart';
import '../repository_providers.dart';
import '../../features/advice/repositories/advice_repository.dart';
import '../../features/medicine/repositories/medicine_repository.dart';
import '../../features/patients/repositories/patient_repository.dart';
import '../../features/prescription/repositories/prescription_repository.dart';
import '../../features/settings/repositories/profile_repository.dart';
import '../../features/settings/repositories/settings_repository.dart';
import 'encrypted_backup_service.dart';
import 'key_value_store.dart';

class AppInitializer {
  static Future<List<Override>> create({
    SupabaseClient? supabaseClient,
    String? cloudConfigurationError,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key = await _loadKey();
    await Hive.initFlutter();
    final cipher = HiveAesCipher(key);

    Future<KeyValueStore> open(String name) async {
      final box = await Hive.openBox<String>(name, encryptionCipher: cipher);
      return HiveBoxStore(box);
    }

    final stores = {
      'profile': await open('profile'),
      'prescriptions': await open('prescriptions'),
      'patients': await open('patients'),
      'advice': await open('advice'),
      'medicines': await open('medicines'),
    };
    final syncService = ClinicSyncService(
      client: supabaseClient,
      stores: stores,
      outbox: await open('sync_outbox'),
      configurationError: cloudConfigurationError,
    );
    final backupService = EncryptedBackupService(stores: stores);
    await syncService.initialize();

    KeyValueStore synced(String collection) {
      return CloudSyncedKeyValueStore(
        local: stores[collection]!,
        syncService: syncService,
        collection: collection,
      );
    }

    return [
      clinicSyncServiceProvider.overrideWithValue(syncService),
      encryptedBackupServiceProvider.overrideWithValue(backupService),
      settingsRepositoryProvider.overrideWithValue(
        PreferencesSettingsRepository(preferences),
      ),
      profileRepositoryProvider.overrideWithValue(
        ProfileRepository(synced('profile')),
      ),
      prescriptionRepositoryProvider.overrideWithValue(
        PrescriptionRepository(synced('prescriptions')),
      ),
      patientRepositoryProvider.overrideWithValue(
        PatientRepository(synced('patients')),
      ),
      adviceRepositoryProvider.overrideWithValue(
        AdviceRepository(synced('advice')),
      ),
      medicineRepositoryProvider.overrideWithValue(
        MedicineRepository(synced('medicines')),
      ),
    ];
  }

  static Future<List<int>> _loadKey() async {
    const storage = FlutterSecureStorage();
    try {
      final existing = await storage.read(key: 'docpad.hive_key');
      if (existing != null && existing.isNotEmpty) {
        final decoded = base64Url.decode(existing);
        if (decoded.length != 32) {
          throw const AppException(
            'The database key could not be read. Records were not opened and were not erased.',
            code: 'secure_storage',
          );
        }
        return decoded;
      }
      final created = Hive.generateSecureKey();
      await storage.write(
        key: 'docpad.hive_key',
        value: base64UrlEncode(created),
      );
      final saved = await storage.read(key: 'docpad.hive_key');
      if (saved == null) {
        throw const AppException(
          'The secure store did not keep the database key. Records were not opened.',
          code: 'secure_storage',
        );
      }
      return created;
    } catch (error) {
      if (error is AppException) rethrow;
      AppLog.error('secure-storage', error);
      throw const AppException(
        'The platform secure store could not be opened, so clinical records were not loaded.',
        code: 'secure_storage',
      );
    }
  }
}
