import 'medex_brand.dart';

class CatalogSource {
  const CatalogSource({
    required this.kind,
    this.provider,
    this.providerName,
    this.retrievedAt,
  });

  final String? kind;
  final String? provider;
  final String? providerName;
  final String? retrievedAt;

  bool get isFixture => kind == 'fixture';
  bool get isLive => kind == 'live';
}

class MedicineSearchPage {
  const MedicineSearchPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.source,
  });

  final List<MedExBrand> items;
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

  bool get isFixture => kind == 'fixture' || !live;
}

class CachedMedicineSearch {
  const CachedMedicineSearch({
    required this.query,
    required this.page,
    required this.items,
    required this.hasNext,
    required this.source,
    required this.cachedAt,
  });

  final String query;
  final int page;
  final List<MedExBrand> items;
  final bool hasNext;
  final CatalogSource source;
  final DateTime cachedAt;

  Map<String, dynamic> toJson() => {
    'query': query,
    'page': page,
    'items': items.map((item) => item.toJson()).toList(),
    'hasNext': hasNext,
    'source': {
      'kind': source.kind,
      'provider': source.provider,
      'providerName': source.providerName,
      'retrievedAt': source.retrievedAt,
    },
    'cachedAt': cachedAt.toIso8601String(),
  };

  factory CachedMedicineSearch.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final sourceJson = json['source'];
    if (itemsJson is! List || sourceJson is! Map) {
      throw const FormatException('Cached catalog entry is unreadable');
    }
    final source = Map<String, dynamic>.from(sourceJson);
    return CachedMedicineSearch(
      query: json['query'] as String? ?? '',
      page: json['page'] is int ? json['page'] as int : 1,
      items: [
        for (final item in itemsJson)
          if (item is Map)
            MedExBrand.fromJson(Map<String, dynamic>.from(item))
          else
            throw const FormatException('Cached medicine is unreadable'),
      ],
      hasNext: json['hasNext'] == true,
      source: CatalogSource(
        kind: source['kind'] as String?,
        provider: source['provider'] as String?,
        providerName: source['providerName'] as String?,
        retrievedAt: source['retrievedAt'] as String?,
      ),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }
}
