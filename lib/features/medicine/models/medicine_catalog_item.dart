/// A medicine record displayed by local medicine-library search.
class MedicineCatalogItem {
  const MedicineCatalogItem({
    required this.id,
    required this.brandName,
    this.genericName,
    this.strength,
    this.dosageForm,
    this.manufacturer,
    this.sourceKind,
  });

  final String id;
  final String brandName;
  final String? genericName;
  final String? strength;
  final String? dosageForm;
  final String? manufacturer;
  final String? sourceKind;

  bool get isFixture => sourceKind == 'fixture';
}

class MedicineGeneric {
  const MedicineGeneric({required this.name, this.sourceKind});

  final String name;
  final String? sourceKind;

  bool get isFixture => sourceKind == 'fixture';
}
