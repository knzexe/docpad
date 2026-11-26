import 'medicine_catalog_item.dart';

class MedicineSearchPage {
  const MedicineSearchPage({
    required this.items,
    required this.page,
    required this.hasNext,
  });

  final List<MedicineCatalogItem> items;
  final int page;
  final bool hasNext;
}
