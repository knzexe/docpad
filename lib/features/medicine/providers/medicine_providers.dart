import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_log.dart';
import '../../../data/repository_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../models/catalog_page.dart';
import '../models/medex_brand.dart';
import '../services/local_medicine_api.dart';
import '../services/medex_api_service.dart';

enum CatalogMode { brands, generics }

const _unset = Object();

class MedicineSearchState {
  const MedicineSearchState({
    this.query = '',
    this.mode = CatalogMode.brands,
    this.brands = const [],
    this.generics = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.hasNext = false,
    this.page = 1,
    this.fromCache = false,
    this.cachedAt,
    this.source,
    this.detailWarning = false,
  });

  final String query;
  final CatalogMode mode;
  final List<MedExBrand> brands;
  final List<MedExGeneric> generics;
  final bool loading;
  final bool loadingMore;
  final AppException? error;
  final bool hasNext;
  final int page;
  final bool fromCache;
  final DateTime? cachedAt;
  final CatalogSource? source;
  final bool detailWarning;

  MedicineSearchState copyWith({
    String? query,
    CatalogMode? mode,
    List<MedExBrand>? brands,
    List<MedExGeneric>? generics,
    bool? loading,
    bool? loadingMore,
    Object? error = _unset,
    bool? hasNext,
    int? page,
    bool? fromCache,
    Object? cachedAt = _unset,
    Object? source = _unset,
    bool? detailWarning,
  }) {
    return MedicineSearchState(
      query: query ?? this.query,
      mode: mode ?? this.mode,
      brands: brands ?? this.brands,
      generics: generics ?? this.generics,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error == _unset ? this.error : error as AppException?,
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      fromCache: fromCache ?? this.fromCache,
      cachedAt: cachedAt == _unset ? this.cachedAt : cachedAt as DateTime?,
      source: source == _unset ? this.source : source as CatalogSource?,
      detailWarning: detailWarning ?? this.detailWarning,
    );
  }
}

final medicineSearchProvider =
    NotifierProvider<MedicineSearchNotifier, MedicineSearchState>(
      MedicineSearchNotifier.new,
    );

class MedicineSearchNotifier extends Notifier<MedicineSearchState> {
  Timer? _debounce;
  CancelToken? _cancel;
  int _requestId = 0;

  @override
  MedicineSearchState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _cancel?.cancel();
    });
    return const MedicineSearchState();
  }

  void setMode(CatalogMode mode) {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode, detailWarning: false);
    if (state.query.trim().isNotEmpty) {
      unawaited(_search(page: 1, append: false));
    }
  }

  void setQuery(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _cancel?.cancel();
      _requestId++;
      state = MedicineSearchState(query: query, mode: state.mode);
      return;
    }
    state = state.copyWith(query: query, error: null, detailWarning: false);
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_search(page: 1, append: false));
    });
  }

  Future<void> loadMore() {
    if (!state.hasNext || state.loading || state.loadingMore) {
      return Future.value();
    }
    return _search(page: state.page + 1, append: true);
  }

  Future<MedExBrand> resolveBrand(MedExBrand listed) async {
    try {
      final detailed = await ref
          .read(medicineApiProvider)
          .getMedicineDetails(listed.id);
      state = state.copyWith(detailWarning: false);
      return detailed;
    } catch (error) {
      AppLog.error('medicine-details', error);
      state = state.copyWith(detailWarning: true);
      return listed;
    }
  }

  Future<void> _search({required int page, required bool append}) async {
    final query = state.query.trim();
    final mode = state.mode;
    if (query.isEmpty) return;
    final requestId = ++_requestId;
    _cancel?.cancel();
    final cancel = CancelToken();
    _cancel = cancel;
    state = state.copyWith(loading: !append, loadingMore: append, error: null);
    try {
      final api = ref.read(medicineApiProvider);
      if (mode == CatalogMode.brands) {
        final result = await api.searchMedicinesPage(
          query: query,
          page: page,
          cancelToken: cancel,
        );
        if (requestId != _requestId) return;
        final items = append
            ? [...state.brands, ...result.items]
            : result.items;
        state = state.copyWith(
          brands: items,
          loading: false,
          loadingMore: false,
          hasNext: result.hasNext,
          page: result.page,
          fromCache: false,
          cachedAt: null,
          source: result.source,
        );
        if (!append || page == 1) {
          await ref
              .read(catalogCacheRepositoryProvider)
              .write(
                CachedMedicineSearch(
                  query: query,
                  page: result.page,
                  items: result.items,
                  hasNext: result.hasNext,
                  source: result.source,
                  cachedAt: DateTime.now(),
                ),
              );
        }
      } else {
        final result = await api.searchGenericsPage(
          query: query,
          page: page,
          cancelToken: cancel,
        );
        if (requestId != _requestId) return;
        state = state.copyWith(
          generics: append
              ? [...state.generics, ...result.items]
              : result.items,
          loading: false,
          loadingMore: false,
          hasNext: result.hasNext,
          page: result.page,
          fromCache: false,
          cachedAt: null,
          source: result.source,
        );
      }
    } on CancelledRequest {
      return;
    } catch (error) {
      if (requestId != _requestId) return;
      if (!append && mode == CatalogMode.brands) {
        final cached = await ref
            .read(catalogCacheRepositoryProvider)
            .read(query: query, page: page);
        if (requestId != _requestId) return;
        if (cached != null) {
          state = state.copyWith(
            brands: cached.items,
            loading: false,
            loadingMore: false,
            hasNext: cached.hasNext,
            page: cached.page,
            fromCache: true,
            cachedAt: cached.cachedAt,
            source: cached.source,
            error: null,
          );
          return;
        }
      }
      AppLog.error('medicine-search', error);
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        brands: append ? state.brands : const [],
        generics: append ? state.generics : const [],
        error: error is AppException
            ? error
            : const AppException(
                'Could not complete the catalog request.',
                code: 'network',
              ),
      );
    }
  }
}

final catalogHealthProvider =
    AsyncNotifierProvider<CatalogHealthNotifier, CatalogHealth?>(
      CatalogHealthNotifier.new,
    );

class CatalogHealthNotifier extends AsyncNotifier<CatalogHealth?> {
  @override
  Future<CatalogHealth?> build() async {
    ref.watch(settingsProvider.select((value) => value.medexBaseUrl));
    return _load();
  }

  Future<CatalogHealth?> refresh() async {
    state = const AsyncLoading();
    final value = await _load();
    state = AsyncData(value);
    return value;
  }

  Future<CatalogHealth?> _load() async {
    try {
      return await ref.read(medicineApiProvider).checkHealth();
    } catch (error) {
      AppLog.error('catalog-health', error);
      return null;
    }
  }
}

final medicineApiProvider = Provider<MedicineCatalogApi>((ref) {
  return LocalMedicineApi(ref.watch(medicineRepositoryProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(
    settingsProvider.select((value) => value.medexBaseUrl),
  );
  final dio = createDio(baseUrl);
  ref.onDispose(() => dio.close(force: true));
  return dio;
});
