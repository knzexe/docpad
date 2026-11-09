import '../../../core/utils/json_readers.dart';

const _unset = Object();

class PrescribedMedicine {
  const PrescribedMedicine({
    required this.id,
    required this.medicineId,
    required this.brandName,
    required this.dose,
    required this.frequency,
    required this.duration,
    required this.route,
    required this.timing,
    required this.instructions,
    required this.quantity,
    this.genericName,
    this.strength,
    this.dosageForm,
    this.manufacturer,
    this.sourceKind,
  });

  final String id;
  final String medicineId;
  final String brandName;
  final String? genericName;
  final String? strength;
  final String? dosageForm;
  final String? manufacturer;
  final String? sourceKind;
  final String dose;
  final String frequency;
  final String duration;
  final String route;
  final String timing;
  final String instructions;
  final String quantity;

  PrescribedMedicine copyWith({
    String? id,
    String? medicineId,
    String? brandName,
    Object? genericName = _unset,
    Object? strength = _unset,
    Object? dosageForm = _unset,
    Object? manufacturer = _unset,
    Object? sourceKind = _unset,
    String? dose,
    String? frequency,
    String? duration,
    String? route,
    String? timing,
    String? instructions,
    String? quantity,
  }) {
    return PrescribedMedicine(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
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
      dose: dose ?? this.dose,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      route: route ?? this.route,
      timing: timing ?? this.timing,
      instructions: instructions ?? this.instructions,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicineId': medicineId,
    'brandName': brandName,
    'genericName': genericName,
    'strength': strength,
    'dosageForm': dosageForm,
    'manufacturer': manufacturer,
    'sourceKind': sourceKind,
    'dose': dose,
    'frequency': frequency,
    'duration': duration,
    'route': route,
    'timing': timing,
    'instructions': instructions,
    'quantity': quantity,
  };

  factory PrescribedMedicine.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final medicineId = json['medicineId'];
    if (id is! String || id.isEmpty || medicineId is! String) {
      throw const FormatException('Prescribed medicine identity is missing');
    }
    return PrescribedMedicine(
      id: id,
      medicineId: medicineId,
      brandName: textField(json, 'brandName'),
      genericName: optionalText(json['genericName']),
      strength: optionalText(json['strength']),
      dosageForm: optionalText(json['dosageForm']),
      manufacturer: optionalText(json['manufacturer']),
      sourceKind: optionalText(json['sourceKind']),
      dose: textField(json, 'dose'),
      frequency: textField(json, 'frequency'),
      duration: textField(json, 'duration'),
      route: textField(json, 'route'),
      timing: textField(json, 'timing'),
      instructions: textField(json, 'instructions'),
      quantity: textField(json, 'quantity'),
    );
  }
}
