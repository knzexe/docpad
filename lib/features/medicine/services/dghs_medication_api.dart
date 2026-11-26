import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../settings/models/tr_credentials.dart';
import '../models/catalog_page.dart';
import '../models/medex_brand.dart';
import '../repositories/catalog_cache_repository.dart';
import 'dghs_parser.dart';
import 'medex_api_service.dart';

/// DGHS Shared Health Record medication terminology.
///
/// The public atom feed lists drug identifiers. Each record is loaded with
/// `GET /openmrs/ws/rest/v1/tr/drugs/{id}` and HTTP basic authentication.
class DghsMedicationApi implements MedicineCatalogApi {
  DghsMedicationApi({
    required this.dio,
    required this.credentials,
    required this.cache,
  });

  final Dio dio;
  final Future<TrCredentials> Function() credentials;
  final CatalogCacheRepository cache;

  static const _source = CatalogSource(
    kind: 'live',
    provider: 'dghs-tr',
    providerName: dghsProviderName,
  );

  @override
  Future<CatalogHealth> checkHealth() async {
    await _feedText('/openmrs/ws/atomfeed/medication/recent');
    return const CatalogHealth(
      status: 'ok',
      version: 'medication',
      providerName: dghsProviderName,
      kind: 'live',
      live: true,
    );
  }

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
  Future<MedicineSearchPage<MedExBrand>> searchMedicinesPage({
    required String query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final brands = await _matching(query, cancelToken);
    return _page(brands, page: page, limit: limit);
  }

  @override
  Future<MedExBrand> getMedicineDetails(
    String id, {
    CancelToken? cancelToken,
  }) async {
    final snapshot = await cache.readDghsCatalog();
    for (final item in snapshot) {
      if (item.id == id) return item;
    }
    final auth = await _authorization();
    final brand = await _fetchDrug(id, auth, cancelToken);
    final seen = await cache.readDghsSeen()
      ..add(id);
    final items = [...await cache.readDghsCatalog()];
    if (brand != null && items.every((item) => item.id != brand.id)) {
      items.add(brand);
    }
    await cache.writeDghsCatalog(items, seen);
    if (brand == null) {
      throw const AppException(
        'That catalog record was not found.',
        code: 'not_found',
      );
    }
    return brand;
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
    final brands = await _matching(query, cancelToken);
    final seen = <String>{};
    final generics = <MedExGeneric>[];
    for (final brand in brands) {
      final name = brand.genericName;
      if (name == null || !seen.add(name)) continue;
      generics.add(
        MedExGeneric(
          id: brand.id,
          name: name,
          sourceKind: 'live',
          sourceLabel: dghsProviderName,
        ),
      );
    }
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit.clamp(1, 100);
    final start = (safePage - 1) * safeLimit;
    final slice = start >= generics.length
        ? const <MedExGeneric>[]
        : generics.skip(start).take(safeLimit).toList();
    final totalPages = generics.isEmpty
        ? 0
        : (generics.length / safeLimit).ceil();
    return GenericSearchPage(
      items: slice,
      page: safePage,
      limit: safeLimit,
      total: generics.length,
      totalPages: totalPages,
      hasNext: safePage < totalPages,
      source: _source,
    );
  }

  Future<List<MedExBrand>> _matching(
    String query,
    CancelToken? cancelToken,
  ) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty || needle.length > 200) {
      throw const AppException(
        'Enter a catalog search between 1 and 200 characters.',
        code: 'validation_error',
      );
    }
    final catalog = await _catalog(cancelToken);
    return [
      for (final brand in catalog)
        if (_matches(brand, needle)) brand,
    ];
  }

  bool _matches(MedExBrand brand, String needle) {
    return brand.brandName.toLowerCase().contains(needle) ||
        (brand.genericName?.toLowerCase().contains(needle) ?? false) ||
        (brand.strength?.toLowerCase().contains(needle) ?? false) ||
        (brand.dosageForm?.toLowerCase().contains(needle) ?? false);
  }

  Future<List<MedExBrand>> _catalog(CancelToken? cancelToken) async {
    final ids = await _allDrugIds(cancelToken);
    final storedItems = await cache.readDghsCatalog();
    final seen = await cache.readDghsSeen();
    final byId = <String, MedExBrand>{
      for (final item in storedItems) item.id: item,
    };
    final missing = [
      for (final id in ids)
        if (!byId.containsKey(id) && !seen.contains(id)) id,
    ];
    if (missing.isNotEmpty) {
      final auth = await _authorization();
      for (var index = 0; index < missing.length; index += 6) {
        final end = index + 6 > missing.length ? missing.length : index + 6;
        final batch = missing.sublist(index, end);
        final fetched = await Future.wait([
          for (final id in batch) _fetchDrug(id, auth, cancelToken),
        ]);
        for (var i = 0; i < batch.length; i++) {
          seen.add(batch[i]);
          final brand = fetched[i];
          if (brand != null) byId[brand.id] = brand;
        }
        await cache.writeDghsCatalog(byId.values.toList(), seen);
      }
    }
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<Set<String>> _allDrugIds(CancelToken? cancelToken) async {
    final recent = await _feedText(
      '/openmrs/ws/atomfeed/medication/recent',
      cancelToken,
    );
    final pending = {...dghsFeedPages(recent), 1};
    final seenPages = <int>{};
    final ids = dghsDrugIdsFromFeed(recent);
    while (pending.isNotEmpty && seenPages.length < 20) {
      final page = pending.first;
      pending.remove(page);
      if (!seenPages.add(page)) continue;
      try {
        final xml = await _feedText(
          '/openmrs/ws/atomfeed/medication/$page',
          cancelToken,
        );
        ids.addAll(dghsDrugIdsFromFeed(xml));
        pending.addAll(dghsFeedPages(xml));
      } on AppException catch (error) {
        if (error.code == 'not_found' || error.code == 'http') continue;
        rethrow;
      }
    }
    return ids;
  }

  Future<String> _authorization() async {
    final login = await credentials();
    final header = login.authorizationHeader;
    if (header == null) {
      throw const AppException(
        'The DGHS terminology registry requires a TR API CONSUMER username and password. Save them in Settings.',
        code: 'unauthorized',
      );
    }
    return header;
  }

  Future<MedExBrand?> _fetchDrug(
    String id,
    String authorization,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await dio.get<dynamic>(
        '/openmrs/ws/rest/v1/tr/drugs/$id',
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Accept': 'application/json',
            'Authorization': authorization,
          },
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      return dghsBrandFromMedication(response.data);
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) rethrow;
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        throw const AppException(
          'The terminology registry rejected the TR login. Check the username and password in Settings.',
          code: 'unauthorized',
        );
      }
      if (error.response?.statusCode == 404) return null;
      throw _map(error);
    }
  }

  Future<String> _feedText(String path, [CancelToken? cancelToken]) async {
    try {
      final response = await dio.get<String>(
        path,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.plain,
          headers: const {'Accept': 'application/atom+xml, application/xml'},
        ),
      );
      final body = response.data;
      if (body == null || body.isEmpty) {
        throw const AppException(
          'The terminology feed was empty.',
          code: 'invalid_response',
        );
      }
      return body;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) rethrow;
      throw _map(error);
    }
  }

  MedicineSearchPage<MedExBrand> _page(
    List<MedExBrand> brands, {
    required int page,
    required int limit,
  }) {
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit.clamp(1, 100);
    final start = (safePage - 1) * safeLimit;
    final slice = start >= brands.length
        ? const <MedExBrand>[]
        : brands.skip(start).take(safeLimit).toList();
    final totalPages = brands.isEmpty ? 0 : (brands.length / safeLimit).ceil();
    return MedicineSearchPage(
      items: slice,
      page: safePage,
      limit: safeLimit,
      total: brands.length,
      totalPages: totalPages,
      hasNext: safePage < totalPages,
      source: _source,
    );
  }

  AppException _map(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          'The catalog request timed out. Drafts on this device are unchanged.',
          code: 'timeout',
        );
      case DioExceptionType.connectionError:
        return const AppException(
          'Could not reach the medicine catalog. Check the address and your network. Drafts on this device are unchanged.',
          code: 'offline',
        );
      default:
        final status = error.response?.statusCode;
        if (status == 404) {
          return const AppException(
            'That catalog record was not found.',
            code: 'not_found',
          );
        }
        return const AppException(
          'The catalog returned an error.',
          code: 'http',
        );
    }
  }
}
