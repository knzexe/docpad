import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../../data/local/json_records.dart';
import '../../../data/local/key_value_store.dart';
import '../models/advice_template.dart';

class AdviceRepository {
  AdviceRepository(this._store);

  final KeyValueStore _store;

  Future<List<AdviceTemplate>> getAll() async {
    final items =
        [for (final json in readAllRecords(_store, 'read-advice')) _parse(json)]
          ..sort((a, b) {
            final order = a.sortOrder.compareTo(b.sortOrder);
            if (order != 0) return order;
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          });
    return items;
  }

  Future<void> save(AdviceTemplate template) {
    return _store.write(template.id, jsonEncode(template.toJson()));
  }

  Future<void> delete(String id) => _store.delete(id);

  Future<void> clear() => _store.clear();

  AdviceTemplate _parse(Map<String, dynamic> json) {
    try {
      return AdviceTemplate.fromJson(json);
    } catch (_) {
      throw const AppException(
        'A saved advice template could not be read. It was not deleted.',
        code: 'storage',
      );
    }
  }
}
