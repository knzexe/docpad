import '../../../core/errors/app_exception.dart';
import '../models/catalog_page.dart';
import '../models/medex_brand.dart';

Map<String, dynamic> asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const AppException(
    'The catalog returned an unexpected response.',
    code: 'invalid_response',
  );
}

MedicineSearchPage<MedExBrand> parseMedicineSearch(dynamic body) {
  final map = asJsonMap(body);
  final data = map['data'];
  final meta = map['meta'];
  if (data is! List || meta is! Map) {
    throw const AppException(
      'The catalog returned an unexpected response.',
      code: 'invalid_response',
    );
  }
  final source = _source(map['source']);
  return MedicineSearchPage(
    items: [
      for (final item in data) medexBrandFromApi(asJsonMap(item), source),
    ],
    page: _requiredInt(meta, 'page'),
    limit: _requiredInt(meta, 'limit'),
    total: _requiredInt(meta, 'total'),
    totalPages: _requiredInt(meta, 'totalPages'),
    hasNext: _requiredBool(meta, 'hasNext'),
    source: source,
  );
}

MedExBrand parseMedicineDetails(dynamic body) {
  final map = asJsonMap(body);
  final data = map['data'];
  if (data is! Map) {
    throw const AppException(
      'The catalog returned an unexpected response.',
      code: 'invalid_response',
    );
  }
  return medexBrandFromApi(asJsonMap(data), _source(map['source']));
}

GenericSearchPage parseGenericSearch(dynamic body) {
  final map = asJsonMap(body);
  final data = map['data'];
  final meta = map['meta'];
  if (data is! List || meta is! Map) {
    throw const AppException(
      'The catalog returned an unexpected response.',
      code: 'invalid_response',
    );
  }
  final source = _source(map['source']);
  return GenericSearchPage(
    items: [for (final item in data) _genericFromApi(asJsonMap(item), source)],
    page: _requiredInt(meta, 'page'),
    limit: _requiredInt(meta, 'limit'),
    total: _requiredInt(meta, 'total'),
    totalPages: _requiredInt(meta, 'totalPages'),
    hasNext: _requiredBool(meta, 'hasNext'),
    source: source,
  );
}

CatalogHealth parseHealth(dynamic body) {
  final map = asJsonMap(body);
  final provider = map['provider'];
  if (provider is! Map) {
    throw const AppException(
      'The catalog health response was missing provider information.',
      code: 'invalid_response',
    );
  }
  final providerMap = Map<String, dynamic>.from(provider);
  final kind = providerMap['kind'];
  final live = providerMap['live'];
  if (kind is! String || live is! bool) {
    throw const AppException(
      'The catalog health response was missing provider information.',
      code: 'invalid_response',
    );
  }
  return CatalogHealth(
    status: map['status'] is String ? map['status'] as String : '',
    version: map['version'] is String ? map['version'] as String : '',
    providerName: providerMap['name'] is String
        ? providerMap['name'] as String
        : '',
    kind: kind,
    live: live,
  );
}

MedExBrand medexBrandFromApi(
  Map<String, dynamic> json,
  CatalogSource envelope,
) {
  final id = json['id'];
  final name = json['name'];
  if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
    throw const AppException(
      'A catalog record was missing its id or name.',
      code: 'invalid_response',
    );
  }
  final source = json['source'] == null ? envelope : _source(json['source']);
  return MedExBrand(
    id: id,
    brandName: name.trim(),
    genericName: _apiText(json['generic']),
    strength: _apiText(json['strength']),
    dosageForm: _apiText(json['dosageForm']),
    manufacturer: _apiText(json['manufacturerName']),
    sourceKind: source.kind,
    sourceLabel: source.providerName,
    sourceRetrievedAt: source.retrievedAt,
    activeIngredients: _apiTextList(json['activeIngredients']),
  );
}

MedExGeneric _genericFromApi(
  Map<String, dynamic> json,
  CatalogSource envelope,
) {
  final id = json['id'];
  final name = json['name'];
  if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
    throw const AppException(
      'A catalog record was missing its id or name.',
      code: 'invalid_response',
    );
  }
  final source = json['source'] == null ? envelope : _source(json['source']);
  final count = json['brandCount'];
  return MedExGeneric(
    id: id,
    name: name.trim(),
    description: _apiText(json['description']),
    brandCount: count is num ? count.toInt() : null,
    sourceKind: source.kind,
    sourceLabel: source.providerName,
    activeIngredients: _apiTextList(json['activeIngredients']),
  );
}

CatalogSource _source(dynamic value) {
  if (value is! Map) {
    throw const AppException(
      'The catalog response was missing source information.',
      code: 'invalid_response',
    );
  }
  final map = Map<String, dynamic>.from(value);
  final kind = map['kind'];
  if (kind != null && kind is! String) {
    throw const AppException(
      'The catalog response had an unreadable source.',
      code: 'invalid_response',
    );
  }
  return CatalogSource(
    kind: kind as String?,
    provider: map['provider'] is String ? map['provider'] as String : null,
    providerName: map['providerName'] is String
        ? map['providerName'] as String
        : null,
    retrievedAt: map['retrievedAt'] is String
        ? map['retrievedAt'] as String
        : null,
  );
}

String? _apiText(dynamic value) {
  if (value == null) return null;
  if (value is! String) {
    throw const AppException(
      'The catalog returned an unexpected field.',
      code: 'invalid_response',
    );
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _apiTextList(dynamic value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const AppException(
      'The catalog returned an unexpected field.',
      code: 'invalid_response',
    );
  }
  return [
    for (final item in value)
      if (item is String)
        item
      else
        throw const AppException(
          'The catalog returned an unexpected field.',
          code: 'invalid_response',
        ),
  ];
}

int _requiredInt(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw const AppException(
    'The catalog returned an unexpected response.',
    code: 'invalid_response',
  );
}

bool _requiredBool(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw const AppException(
    'The catalog returned an unexpected response.',
    code: 'invalid_response',
  );
}
