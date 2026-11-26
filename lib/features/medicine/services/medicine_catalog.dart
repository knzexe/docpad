import '../models/catalog_page.dart';
import '../models/medicine_catalog_item.dart';

abstract class MedicineCatalog {
  Future<MedicineSearchPage> searchMedicinesPage({
    required String query,
    int page = 1,
    int limit = 20,
  });

  Future<List<MedicineGeneric>> searchGenerics({required String query});
}
