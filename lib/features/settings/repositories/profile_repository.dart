import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_log.dart';
import '../../../data/local/json_records.dart';
import '../../../data/local/key_value_store.dart';
import '../models/doctor_profile.dart';

class ProfileRepository {
  ProfileRepository(this._store);

  final KeyValueStore _store;
  static const _key = 'doctor';

  DoctorProfile read() {
    final raw = _store.read(_key);
    if (raw == null) return DoctorProfile.empty;
    try {
      return DoctorProfile.fromJson(decodeRecord(raw, 'read-profile'));
    } catch (error) {
      AppLog.error('read-profile', error);
      throw const AppException(
        'The doctor profile could not be read. It was not deleted.',
        code: 'storage',
      );
    }
  }

  Future<void> save(DoctorProfile profile) {
    return _store.write(_key, jsonEncode(profile.toJson()));
  }

  Future<void> clear() => _store.delete(_key);
}
