import 'dart:convert';

import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/app_log.dart';
import '../../features/advice/repositories/advice_repository.dart';
import '../../features/medicine/repositories/catalog_cache_repository.dart';
import '../../features/medicine/repositories/medicine_repository.dart';
import '../../features/patients/repositories/patient_repository.dart';
import '../../features/prescription/repositories/prescription_repository.dart';
import '../../features/settings/repositories/profile_repository.dart';
import '../../features/settings/repositories/settings_repository.dart';
import '../repository_providers.dart';
import 'key_value_store.dart';

class AppInitializer {
  static Future<List<Override>> create() async {
    final preferences = await SharedPreferences.getInstance();
    final key = await _loadKey();
    await Hive.initFlutter();
    final cipher = HiveAesCipher(key);

    Future<KeyValueStore> open(String name) async {
      final box = await Hive.openBox<String>(name, encryptionCipher: cipher);
      return HiveBoxStore(box);
    }

    return [
      settingsRepositoryProvider.overrideWithValue(
        PreferencesSettingsRepository(preferences),
      ),
      profileRepositoryProvider.overrideWithValue(
        ProfileRepository(await open('profile')),
      ),
      prescriptionRepositoryProvider.overrideWithValue(
        PrescriptionRepository(await open('prescriptions')),
      ),
      patientRepositoryProvider.overrideWithValue(
        PatientRepository(await open('patients')),
      ),
      adviceRepositoryProvider.overrideWithValue(
        AdviceRepository(await open('advice')),
      ),
      catalogCacheRepositoryProvider.overrideWithValue(
        CatalogCacheRepository(await open('catalog_cache')),
      ),
      medicineRepositoryProvider.overrideWithValue(
        MedicineRepository(await open('medicines')),
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
