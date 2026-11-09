import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../../data/local/json_records.dart';
import '../../../data/local/key_value_store.dart';
import '../models/medicine.dart';

class MedicineRepository {
  MedicineRepository(this._store);

  final KeyValueStore _store;

  Future<List<Medicine>> getAll() async {
    final items = [
      for (final json in readAllRecords(_store, 'read-medicine')) _parse(json),
    ];
    items.sort((a, b) => a.brandName.toLowerCase().compareTo(b.brandName.toLowerCase()));
    return items;
  }

  Future<void> upsert(Medicine medicine) =>
      _store.write(medicine.id, jsonEncode(medicine.toJson()));

  Future<void> delete(String id) => _store.delete(id);

  Future<void> clear() => _store.clear();

  Medicine _parse(Map<String, dynamic> json) {
    try {
      return Medicine.fromJson(json);
    } catch (_) {
      throw const AppException(
        'A saved medicine record could not be read. It was not deleted.',
        code: 'storage',
      );
    }
  }
}
