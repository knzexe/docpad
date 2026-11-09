import '../../../core/utils/json_readers.dart';

const _unset = Object();

class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.phone,
    required this.prescriptionDate,
    this.age,
    this.sex,
    this.address,
    this.patientCode,
    this.identificationNotes,
  });

  final String id;
  final String name;
  final String phone;
  final int? age;
  final String? sex;
  final DateTime prescriptionDate;
  final String? address;
  final String? patientCode;
  final String? identificationNotes;

  Patient copyWith({
    String? id,
    String? name,
    String? phone,
    Object? age = _unset,
    Object? sex = _unset,
    DateTime? prescriptionDate,
    Object? address = _unset,
    Object? patientCode = _unset,
    Object? identificationNotes = _unset,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      age: age == _unset ? this.age : age as int?,
      sex: sex == _unset ? this.sex : sex as String?,
      prescriptionDate: prescriptionDate ?? this.prescriptionDate,
      address: address == _unset ? this.address : address as String?,
      patientCode: patientCode == _unset
          ? this.patientCode
          : patientCode as String?,
      identificationNotes: identificationNotes == _unset
          ? this.identificationNotes
          : identificationNotes as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'age': age,
    'sex': sex,
    'prescriptionDate': prescriptionDate.toIso8601String(),
    'address': address,
    'patientCode': patientCode,
    'identificationNotes': identificationNotes,
  };

  factory Patient.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Patient id is missing');
    }
    return Patient(
      id: id,
      name: textField(json, 'name'),
      phone: textField(json, 'phone'),
      age: optionalInt(json['age']),
      sex: optionalText(json['sex']),
      prescriptionDate: requiredDate(json, 'prescriptionDate'),
      address: optionalText(json['address']),
      patientCode: optionalText(json['patientCode']),
      identificationNotes: optionalText(json['identificationNotes']),
    );
  }
}
