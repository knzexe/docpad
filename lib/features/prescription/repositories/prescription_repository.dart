import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../../data/local/json_records.dart';
import '../../../data/local/key_value_store.dart';
import '../models/prescription.dart';

class PrescriptionRepository {
  PrescriptionRepository(this._store);

  final KeyValueStore _store;

  Future<List<Prescription>> getAll() async {
    final items = [
      for (final json in readAllRecords(_store, 'read-prescription'))
        _parse(json),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<Prescription?> getById(String id) async {
    final raw = _store.read(id);
    if (raw == null) return null;
    return _parse(decodeRecord(raw, 'read-prescription'));
  }

  Future<void> save(Prescription prescription) {
    return _store.write(prescription.id, jsonEncode(prescription.toJson()));
  }

  Future<void> delete(String id) => _store.delete(id);

  Future<void> clear() => _store.clear();

  Prescription _parse(Map<String, dynamic> json) {
    try {
      return Prescription.fromJson(json);
    } catch (error) {
      if (error is AppException) rethrow;
      throw const AppException(
        'A saved prescription could not be read. It was not deleted.',
        code: 'storage',
      );
    }
  }
}
