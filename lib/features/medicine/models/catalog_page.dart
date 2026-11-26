import 'medex_brand.dart';

class MedicineSearchPage<T> {
  const MedicineSearchPage({
    required this.items,
    required this.page,
    required this.hasNext,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 0,
    this.source = const CatalogSource(),
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final CatalogSource source;
}

class GenericSearchPage {
  const GenericSearchPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.source,
  });

  final List<MedExGeneric> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final CatalogSource source;
}

class CatalogSource {
  const CatalogSource({
    this.provider,
    this.providerName,
    this.kind,
    this.retrievedAt,
  });

  final String? provider;
  final String? providerName;
  final String? kind;
  final String? retrievedAt;
}

class CatalogHealth {
  const CatalogHealth({
    required this.status,
    required this.version,
    required this.providerName,
    required this.kind,
    required this.live,
  });

  final String status;
  final String version;
  final String providerName;
  final String kind;
  final bool live;

  bool get isFixture => kind == 'fixture';
}
