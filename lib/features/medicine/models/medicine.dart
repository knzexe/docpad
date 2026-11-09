import '../../../core/utils/json_readers.dart';

const _unset = Object();

class Medicine {
  const Medicine({
    required this.id,
    required this.brandName,
    this.genericName,
    this.strength,
    this.dosageForm,
    this.manufacturer,
    this.category,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String brandName;
  final String? genericName;
  final String? strength;
  final String? dosageForm;
  final String? manufacturer;
  final String? category;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine copyWith({
    String? id,
    String? brandName,
    Object? genericName = _unset,
    Object? strength = _unset,
    Object? dosageForm = _unset,
    Object? manufacturer = _unset,
    Object? category = _unset,
    Object? notes = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      brandName: brandName ?? this.brandName,
      genericName: genericName == _unset ? this.genericName : genericName as String?,
      strength: strength == _unset ? this.strength : strength as String?,
      dosageForm: dosageForm == _unset ? this.dosageForm : dosageForm as String?,
      manufacturer: manufacturer == _unset ? this.manufacturer : manufacturer as String?,
      category: category == _unset ? this.category : category as String?,
      notes: notes == _unset ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandName': brandName,
    'genericName': genericName,
    'strength': strength,
    'dosageForm': dosageForm,
    'manufacturer': manufacturer,
    'category': category,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Medicine.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Medicine id is missing');
    }
    return Medicine(
      id: id,
      brandName: textField(json, 'brandName'),
      genericName: optionalText(json['genericName']),
      strength: optionalText(json['strength']),
      dosageForm: optionalText(json['dosageForm']),
      manufacturer: optionalText(json['manufacturer']),
      category: optionalText(json['category']),
      notes: optionalText(json['notes']),
      createdAt: requiredDate(json, 'createdAt'),
      updatedAt: requiredDate(json, 'updatedAt'),
    );
  }
}
