import 'dart:async';

import 'package:docpad/features/medicine/models/catalog_page.dart';
import 'package:docpad/features/medicine/models/medicine_catalog_item.dart';
import 'package:docpad/features/medicine/services/medicine_catalog.dart';

class FakeCatalog implements MedicineCatalog {
  FakeCatalog({this.error, this.page});

  Object? error;
  MedicineSearchPage<MedicineCatalogItem>? page;
  int searchCalls = 0;
  Completer<void>? gate;

  static const fixtureBrand = MedicineCatalogItem(
    id: 'med-fixture-1',
    brandName: 'FixtureBrand',
    genericName: 'FixtureGeneric',
    strength: '500 mg',
    dosageForm: 'Tablet',
    manufacturer: 'Fixture Labs',
    sourceKind: 'fixture',
  );

  static MedicineSearchPage<MedicineCatalogItem> fixturePage() {
    return const MedicineSearchPage(
      items: [fixtureBrand],
      page: 1,
      hasNext: false,
    );
  }

  @override
  Future<MedicineSearchPage<MedicineCatalogItem>> searchMedicinesPage({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    searchCalls += 1;
    final pending = gate;
    if (pending != null) await pending.future;
    if (error != null) throw error!;
    return this.page ??
        const MedicineSearchPage(items: [], page: 1, hasNext: false);
  }

  @override
  Future<List<MedicineGeneric>> searchGenerics({required String query}) async =>
      const [];
}
