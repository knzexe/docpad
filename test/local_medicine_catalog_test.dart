import 'package:docpad/data/local/key_value_store.dart';
import 'package:docpad/features/medicine/models/medicine.dart';
import 'package:docpad/features/medicine/repositories/medicine_repository.dart';
import 'package:docpad/features/medicine/services/local_medicine_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final timestamp = DateTime.utc(2026, 1, 1);

  Medicine medicine({
    required String id,
    required String brand,
    String? generic,
  }) {
    return Medicine(
      id: id,
      brandName: brand,
      genericName: generic,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  test('searches and paginates the saved local medicine library', () async {
    final repository = MedicineRepository(MemoryStore());
    await repository.upsert(medicine(id: '1', brand: 'Alpha One'));
    await repository.upsert(medicine(id: '2', brand: 'Alpha Two'));
    await repository.upsert(medicine(id: '3', brand: 'Beta'));

    final catalog = LocalMedicineCatalog(repository);
    final firstPage = await catalog.searchMedicinesPage(
      query: 'alpha',
      page: 1,
      limit: 1,
    );
    final secondPage = await catalog.searchMedicinesPage(
      query: 'alpha',
      page: 2,
      limit: 1,
    );

    expect(firstPage.items.single.brandName, 'Alpha One');
    expect(firstPage.hasNext, isTrue);
    expect(secondPage.items.single.brandName, 'Alpha Two');
    expect(secondPage.hasNext, isFalse);
  });

  test('deduplicates generic names case-insensitively', () async {
    final repository = MedicineRepository(MemoryStore());
    await repository.upsert(
      medicine(id: '1', brand: 'Brand One', generic: 'Amoxicillin'),
    );
    await repository.upsert(
      medicine(id: '2', brand: 'Brand Two', generic: 'amoxicillin'),
    );

    final result = await LocalMedicineCatalog(repository)
        .searchGenerics(query: 'amox');

    expect(result, hasLength(1));
    expect(result.single.name, 'Amoxicillin');
  });
}
