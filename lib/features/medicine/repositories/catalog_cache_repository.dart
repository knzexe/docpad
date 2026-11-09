import 'dart:convert';

import '../../../data/local/json_records.dart';
import '../../../data/local/key_value_store.dart';
import '../models/catalog_page.dart';
import '../models/medex_brand.dart';

class CatalogCacheRepository {
  CatalogCacheRepository(this._store);

  final KeyValueStore _store;

  String _key(String query, int page) => '${query.trim().toLowerCase()}::$page';

  Future<CachedMedicineSearch?> read({
    required String query,
    required int page,
  }) async {
    final raw = _store.read(_key(query, page));
    if (raw == null) return null;
    try {
      return CachedMedicineSearch.fromJson(decodeRecord(raw, 'read-cache'));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(CachedMedicineSearch entry) {
    return _store.write(
      _key(entry.query, entry.page),
      jsonEncode(entry.toJson()),
    );
  }

  Future<void> clear() => _store.clear();

  static const dghsCatalogKey = 'dghs::catalog';
  static const dghsSeenKey = 'dghs::seen';

  Future<List<MedExBrand>> readDghsCatalog() async {
    final raw = _store.read(dghsCatalogKey);
    if (raw == null) return const [];
    try {
      final json = decodeRecord(raw, 'read-dghs');
      final items = json['items'];
      if (items is! List) return const [];
      return [
        for (final item in items)
          if (item is Map) MedExBrand.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> readDghsSeen() async {
    final raw = _store.read(dghsSeenKey);
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw);
      if (json is! List) return {};
      return {for (final id in json) if (id is String) id};
    } catch (_) {
      return {};
    }
  }

  Future<void> writeDghsCatalog(List<MedExBrand> items, Set<String> seen) async {
    await _store.write(
      dghsCatalogKey,
      jsonEncode({
        'items': [for (final item in items) item.toJson()],
      }),
    );
    await _store.write(dghsSeenKey, jsonEncode(seen.toList()));
  }
}
