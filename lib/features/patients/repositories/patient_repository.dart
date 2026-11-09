import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../../data/local/json_records.dart';
import '../../../data/local/key_value_store.dart';
import '../models/patient.dart';

class PatientRepository {
  PatientRepository(this._store);

  final KeyValueStore _store;

  Future<List<Patient>> getAll() async {
    final items = [
      for (final json in readAllRecords(_store, 'read-patient')) _parse(json),
    ]..sort((a, b) => b.prescriptionDate.compareTo(a.prescriptionDate));
    return items;
  }

  Future<Patient?> getById(String id) async {
    final raw = _store.read(id);
    if (raw == null) return null;
    return _parse(decodeRecord(raw, 'read-patient'));
  }

  Future<void> upsert(Patient patient) {
    return _store.write(patient.id, jsonEncode(patient.toJson()));
  }

  Future<void> delete(String id) => _store.delete(id);

  Future<void> clear() => _store.clear();

  Patient _parse(Map<String, dynamic> json) {
    try {
      return Patient.fromJson(json);
    } catch (_) {
      throw const AppException(
        'A saved patient record could not be read. It was not deleted.',
        code: 'storage',
      );
    }
  }
}
