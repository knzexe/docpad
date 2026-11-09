import 'package:dio/dio.dart';

import '../models/catalog_page.dart';
import '../models/medex_brand.dart';
import '../models/medicine.dart';
import '../repositories/medicine_repository.dart';
import 'medex_api_service.dart';

class LocalMedicineApi implements MedicineCatalogApi {
  LocalMedicineApi(this.repository);

  final MedicineRepository repository;

  static const _source = CatalogSource(
    kind: 'local',
    provider: 'docpad-library',
    providerName: 'My Medicine Library',
  );

  @override
  Future<CatalogHealth> checkHealth() async => const CatalogHealth(
    status: 'ok',
    version: 'local',
    providerName: 'My Medicine Library',
    kind: 'local',
    live: false,
  );

  @override
  Future<List<MedExBrand>> searchMedicines({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async => (await searchMedicinesPage(query: query, page: page, limit: limit)).items;

  @override
  Future<MedicineSearchPage> searchMedicinesPage({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final all = await repository.getAll();
    final needle = query.trim().toLowerCase();
    final matches = all.where((item) {
      return item.brandName.toLowerCase().contains(needle) ||
          (item.genericName?.toLowerCase().contains(needle) ?? false);
    }).map(_toBrand).toList();
    final safeLimit = limit.clamp(1, 100);
    final safePage = page < 1 ? 1 : page;
    final start = (safePage - 1) * safeLimit;
    final items = start >= matches.length
        ? const <MedExBrand>[]
        : matches.sublist(start, (start + safeLimit).clamp(0, matches.length));
    final totalPages = matches.isEmpty ? 1 : (matches.length + safeLimit - 1) ~/ safeLimit;
    return MedicineSearchPage(
      items: items,
      page: safePage,
      limit: safeLimit,
      total: matches.length,
      totalPages: totalPages,
      hasNext: safePage < totalPages,
      source: _source,
    );
  }

  @override
  Future<MedExBrand> getMedicineDetails(
    String id, {
    CancelToken? cancelToken,
  }) async {
    final item = (await repository.getAll()).where((medicine) => medicine.id == id).firstOrNull;
    if (item == null) throw StateError('Medicine was not found in the local library.');
    return _toBrand(item);
  }

  @override
  Future<List<dynamic>> searchGenerics({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async => (await searchGenericsPage(query: query, page: page, limit: limit)).items;

  @override
  Future<GenericSearchPage> searchGenericsPage({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final all = await repository.getAll();
    final needle = query.trim().toLowerCase();
    final seen = <String, MedExGeneric>{};
    for (final item in all) {
      final generic = item.genericName;
      if (generic != null && generic.toLowerCase().contains(needle)) {
        seen.putIfAbsent(
          generic.toLowerCase(),
          () => MedExGeneric(
            id: generic.toLowerCase(),
            name: generic,
            sourceKind: 'local',
            sourceLabel: 'My Medicine Library',
          ),
        );
      }
    }
    final items = seen.values.toList();
    return GenericSearchPage(
      items: items,
      page: 1,
      limit: items.length,
      total: items.length,
      totalPages: 1,
      hasNext: false,
      source: _source,
    );
  }

  static MedExBrand _toBrand(Medicine item) => MedExBrand(
    id: item.id,
    brandName: item.brandName,
    genericName: item.genericName,
    strength: item.strength,
    dosageForm: item.dosageForm,
    manufacturer: item.manufacturer,
    sourceKind: 'local',
    sourceLabel: 'My Medicine Library',
  );
}
