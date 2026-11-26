import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_log.dart';
import '../../../data/repository_providers.dart';
import '../models/medicine_catalog_item.dart';
import '../services/local_medicine_catalog.dart';
import '../services/medicine_catalog.dart';

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
  });

  final String query;
  final CatalogMode mode;
  final List<MedicineCatalogItem> brands;
  final List<MedicineGeneric> generics;
  final bool loading;
  final bool loadingMore;
  final AppException? error;
  final bool hasNext;
  final int page;

  MedicineSearchState copyWith({
    String? query,
    CatalogMode? mode,
    List<MedicineCatalogItem>? brands,
    List<MedicineGeneric>? generics,
    bool? loading,
    bool? loadingMore,
    Object? error = _unset,
    bool? hasNext,
    int? page,
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
    );
  }
}

final medicineSearchProvider =
    NotifierProvider<MedicineSearchNotifier, MedicineSearchState>(
      MedicineSearchNotifier.new,
    );

class MedicineSearchNotifier extends Notifier<MedicineSearchState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  MedicineSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const MedicineSearchState();
  }

  void setMode(CatalogMode mode) {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode);
    if (state.query.trim().isNotEmpty) {
      unawaited(_search(page: 1, append: false));
    }
  }

  void setQuery(String query) {
    _debounce?.cancel();
    _requestId++;
    if (query.trim().isEmpty) {
      state = MedicineSearchState(query: query, mode: state.mode);
      return;
    }
    state = state.copyWith(query: query, error: null);
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

  Future<void> _search({required int page, required bool append}) async {
    final query = state.query.trim();
    final mode = state.mode;
    if (query.isEmpty) return;
    final requestId = ++_requestId;
    state = state.copyWith(loading: !append, loadingMore: append, error: null);
    try {
      final catalog = ref.read(medicineCatalogProvider);
      if (mode == CatalogMode.brands) {
        final result = await catalog.searchMedicinesPage(
          query: query,
          page: page,
        );
        if (requestId != _requestId) return;
        state = state.copyWith(
          brands: append ? [...state.brands, ...result.items] : result.items,
          loading: false,
          loadingMore: false,
          hasNext: result.hasNext,
          page: result.page,
        );
      } else {
        final result = await catalog.searchGenerics(query: query);
        if (requestId != _requestId) return;
        state = state.copyWith(
          generics: append ? [...state.generics, ...result] : result,
          loading: false,
          loadingMore: false,
          hasNext: false,
          page: 1,
        );
      }
    } catch (error) {
      if (requestId != _requestId) return;
      AppLog.error('medicine-search', error);
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        brands: append ? state.brands : const [],
        generics: append ? state.generics : const [],
        error: error is AppException
            ? error
            : const AppException(
                'Could not search the local medicine library.',
                code: 'local_search',
              ),
      );
    }
  }
}

final medicineCatalogProvider = Provider<MedicineCatalog>((ref) {
  return LocalMedicineCatalog(ref.watch(medicineRepositoryProvider));
});
