import '../models/catalog_page.dart';
import '../models/medicine_catalog_item.dart';
import '../models/medicine.dart';
import '../repositories/medicine_repository.dart';
import 'medicine_catalog.dart';

class LocalMedicineCatalog implements MedicineCatalog {
  LocalMedicineCatalog(this.repository);

  final MedicineRepository repository;

  @override
  Future<MedicineSearchPage<MedicineCatalogItem>> searchMedicinesPage({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final all = await repository.getAll();
    final needle = query.trim().toLowerCase();
    final matches = all
        .where((item) {
          return item.brandName.toLowerCase().contains(needle) ||
              (item.genericName?.toLowerCase().contains(needle) ?? false);
        })
        .map(_toBrand)
        .toList();
    final safeLimit = limit.clamp(1, 100);
    final safePage = page < 1 ? 1 : page;
    final start = (safePage - 1) * safeLimit;
    final items = start >= matches.length
        ? const <MedicineCatalogItem>[]
        : matches.sublist(start, (start + safeLimit).clamp(0, matches.length));
    final totalPages = matches.isEmpty
        ? 1
        : (matches.length + safeLimit - 1) ~/ safeLimit;
    return MedicineSearchPage(
      items: items,
      page: safePage,
      limit: safeLimit,
      total: matches.length,
      totalPages: totalPages,
      hasNext: safePage < totalPages,
      source: const CatalogSource(
        kind: 'local',
        provider: 'docpad-library',
        providerName: 'My Medicine Library',
      ),
    );
  }

  @override
  Future<List<MedicineGeneric>> searchGenerics({required String query}) async {
    final all = await repository.getAll();
    final needle = query.trim().toLowerCase();
    final seen = <String, MedicineGeneric>{};
    for (final item in all) {
      final generic = item.genericName;
      if (generic != null && generic.toLowerCase().contains(needle)) {
        seen.putIfAbsent(
          generic.toLowerCase(),
          () => MedicineGeneric(name: generic, sourceKind: 'local'),
        );
      }
    }
    return seen.values.toList();
  }

  static MedicineCatalogItem _toBrand(Medicine item) => MedicineCatalogItem(
    id: item.id,
    brandName: item.brandName,
    genericName: item.genericName,
    strength: item.strength,
    dosageForm: item.dosageForm,
    manufacturer: item.manufacturer,
    sourceKind: 'local',
  );
}
