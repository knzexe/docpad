import '../../../core/utils/json_readers.dart';

const _unset = Object();

/// A brand record from `GET /api/v1/medicines/search` or
/// `GET /api/v1/medicines/{id}`.
///
/// The API field `name` is mapped to [brandName]. [sourceKind] is `fixture`
/// for the repository's default synthetic provider and `live` only when the
/// configured provider says so.
class MedExBrand {
  const MedExBrand({
    required this.id,
    required this.brandName,
    this.genericName,
    this.strength,
    this.dosageForm,
    this.manufacturer,
    this.sourceKind,
    this.sourceLabel,
    this.sourceRetrievedAt,
    this.activeIngredients = const [],
  });

  final String id;
  final String brandName;
  final String? genericName;
  final String? strength;
  final String? dosageForm;
  final String? manufacturer;
  final String? sourceKind;
  final String? sourceLabel;
  final String? sourceRetrievedAt;
  final List<String> activeIngredients;

  bool get isFixture => sourceKind == 'fixture';

  MedExBrand copyWith({
    String? id,
    String? brandName,
    Object? genericName = _unset,
    Object? strength = _unset,
    Object? dosageForm = _unset,
    Object? manufacturer = _unset,
    Object? sourceKind = _unset,
    Object? sourceLabel = _unset,
    Object? sourceRetrievedAt = _unset,
    List<String>? activeIngredients,
  }) {
    return MedExBrand(
      id: id ?? this.id,
      brandName: brandName ?? this.brandName,
      genericName: genericName == _unset
          ? this.genericName
          : genericName as String?,
      strength: strength == _unset ? this.strength : strength as String?,
      dosageForm: dosageForm == _unset
          ? this.dosageForm
          : dosageForm as String?,
      manufacturer: manufacturer == _unset
          ? this.manufacturer
          : manufacturer as String?,
      sourceKind: sourceKind == _unset
          ? this.sourceKind
          : sourceKind as String?,
      sourceLabel: sourceLabel == _unset
          ? this.sourceLabel
          : sourceLabel as String?,
      sourceRetrievedAt: sourceRetrievedAt == _unset
          ? this.sourceRetrievedAt
          : sourceRetrievedAt as String?,
      activeIngredients: activeIngredients ?? this.activeIngredients,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandName': brandName,
    'genericName': genericName,
    'strength': strength,
    'dosageForm': dosageForm,
    'manufacturer': manufacturer,
    'sourceKind': sourceKind,
    'sourceLabel': sourceLabel,
    'sourceRetrievedAt': sourceRetrievedAt,
    'activeIngredients': activeIngredients,
  };

  factory MedExBrand.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final brandName = json['brandName'];
    if (id is! String || id.isEmpty || brandName is! String) {
      throw const FormatException('Medicine identity is missing');
    }
    return MedExBrand(
      id: id,
      brandName: brandName,
      genericName: optionalText(json['genericName']),
      strength: optionalText(json['strength']),
      dosageForm: optionalText(json['dosageForm']),
      manufacturer: optionalText(json['manufacturer']),
      sourceKind: optionalText(json['sourceKind']),
      sourceLabel: optionalText(json['sourceLabel']),
      sourceRetrievedAt: optionalText(json['sourceRetrievedAt']),
      activeIngredients: _stringList(json['activeIngredients']),
    );
  }
}

class MedExGeneric {
  const MedExGeneric({
    required this.id,
    required this.name,
    this.description,
    this.brandCount,
    this.sourceKind,
    this.sourceLabel,
    this.activeIngredients = const [],
  });

  final String id;
  final String name;
  final String? description;
  final int? brandCount;
  final String? sourceKind;
  final String? sourceLabel;
  final List<String> activeIngredients;

  bool get isFixture => sourceKind == 'fixture';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'brandCount': brandCount,
    'sourceKind': sourceKind,
    'sourceLabel': sourceLabel,
    'activeIngredients': activeIngredients,
  };

  factory MedExGeneric.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
      throw const FormatException('Generic identity is missing');
    }
    return MedExGeneric(
      id: id,
      name: name.trim(),
      description: optionalText(json['description']),
      brandCount: optionalInt(json['brandCount']),
      sourceKind: optionalText(json['sourceKind']),
      sourceLabel: optionalText(json['sourceLabel']),
      activeIngredients: _stringList(json['activeIngredients']),
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('Expected a list of text');
  }
  return [
    for (final item in value)
      if (item is String)
        item
      else
        throw const FormatException('Expected text'),
  ];
}
