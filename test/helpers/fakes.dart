import 'dart:async';

import 'package:dio/dio.dart';
import 'package:docpad/core/errors/app_exception.dart';
import 'package:docpad/features/medicine/models/catalog_page.dart';
import 'package:docpad/features/medicine/models/medex_brand.dart';
import 'package:docpad/features/medicine/services/medex_api_service.dart';

class FakeCatalog implements MedicineCatalogApi {
  FakeCatalog({this.error, this.page, CatalogHealth? health})
    : health =
          health ??
          const CatalogHealth(
            status: 'ok',
            version: '0.1.0',
            providerName: 'Synthetic Development Fixtures',
            kind: 'fixture',
            live: false,
          );

  Object? error;
  MedicineSearchPage? page;
  final CatalogHealth health;
  int searchCalls = 0;
  Completer<void>? gate;

  static const fixtureBrand = MedExBrand(
    id: 'med-fixture-1',
    brandName: 'FixtureBrand',
    genericName: 'FixtureGeneric',
    strength: '500 mg',
    dosageForm: 'Tablet',
    manufacturer: 'Fixture Labs',
    sourceKind: 'fixture',
    sourceLabel: 'Synthetic Development Fixtures',
  );

  static MedicineSearchPage fixturePage() {
    return const MedicineSearchPage(
      items: [fixtureBrand],
      page: 1,
      limit: 20,
      total: 1,
      totalPages: 1,
      hasNext: false,
      source: CatalogSource(
        kind: 'fixture',
        provider: 'fixture',
        providerName: 'Synthetic Development Fixtures',
        retrievedAt: '2026-01-01T00:00:00.000Z',
      ),
    );
  }

  @override
  Future<CatalogHealth> checkHealth() async => health;

  @override
  Future<List<MedExBrand>> searchMedicines({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    return (await searchMedicinesPage(
      query: query,
      page: page,
      limit: limit,
      cancelToken: cancelToken,
    )).items;
  }

  @override
  Future<MedicineSearchPage> searchMedicinesPage({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    searchCalls += 1;
    final pending = gate;
    if (pending != null) await pending.future;
    if (error != null) throw error!;
    return this.page ??
        const MedicineSearchPage(
          items: [],
          page: 1,
          limit: 20,
          total: 0,
          totalPages: 0,
          hasNext: false,
          source: CatalogSource(
            kind: 'fixture',
            providerName: 'Synthetic Development Fixtures',
          ),
        );
  }

  @override
  Future<MedExBrand> getMedicineDetails(
    String id, {
    CancelToken? cancelToken,
  }) async {
    final items = page?.items ?? const <MedExBrand>[];
    for (final item in items) {
      if (item.id == id) return item;
    }
    throw const AppException(
      'That catalog record was not found.',
      code: 'not_found',
    );
  }

  @override
  Future<List<dynamic>> searchGenerics({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    return (await searchGenericsPage(
      query: query,
      page: page,
      limit: limit,
      cancelToken: cancelToken,
    )).items;
  }

  @override
  Future<GenericSearchPage> searchGenericsPage({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    return const GenericSearchPage(
      items: [],
      page: 1,
      limit: 20,
      total: 0,
      totalPages: 0,
      hasNext: false,
      source: CatalogSource(kind: 'fixture'),
    );
  }
}
