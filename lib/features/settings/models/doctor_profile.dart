import '../../../core/utils/json_readers.dart';
import '../../../core/constants/clinic_branding.dart';

const _unset = Object();

class DoctorProfile {
  const DoctorProfile({
    this.name = '',
    this.designation = '',
    this.registrationNumber = '',
    this.clinicName = '',
    this.clinicAddress = '',
    this.contact = '',
    this.headerExtra = '',
    this.logoBase64,
  });

  static const empty = DoctorProfile();
  static const clinicDefault = DoctorProfile(
    name: 'Dr. Morsalin Bin Sakhawat',
    designation:
        'MBBS (DU), CCD (BIRDEM), PGT (Medicine)\nEMO & Emergency Incharge (Doctor)',
    clinicName: ClinicBranding.name,
    clinicAddress:
        '27/9/5 Meradia, South Banasree, Dhaka-1219, Farazy Hospital Building-2',
    contact: '01682897670',
    headerExtra: ClinicBranding.branch,
  );

  final String name;
  final String designation;
  final String registrationNumber;
  final String clinicName;
  final String clinicAddress;
  final String contact;
  final String headerExtra;
  final String? logoBase64;

  bool get hasVisibleHeader =>
      name.trim().isNotEmpty ||
      designation.trim().isNotEmpty ||
      registrationNumber.trim().isNotEmpty ||
      clinicName.trim().isNotEmpty ||
      clinicAddress.trim().isNotEmpty ||
      contact.trim().isNotEmpty ||
      headerExtra.trim().isNotEmpty ||
      (logoBase64 != null && logoBase64!.isNotEmpty);

  DoctorProfile copyWith({
    String? name,
    String? designation,
    String? registrationNumber,
    String? clinicName,
    String? clinicAddress,
    String? contact,
    String? headerExtra,
    Object? logoBase64 = _unset,
  }) {
    return DoctorProfile(
      name: name ?? this.name,
      designation: designation ?? this.designation,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      contact: contact ?? this.contact,
      headerExtra: headerExtra ?? this.headerExtra,
      logoBase64: logoBase64 == _unset
          ? this.logoBase64
          : logoBase64 as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'designation': designation,
    'registrationNumber': registrationNumber,
    'clinicName': clinicName,
    'clinicAddress': clinicAddress,
    'contact': contact,
    'headerExtra': headerExtra,
    'logoBase64': logoBase64,
  };

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      name: textField(json, 'name'),
      designation: textField(json, 'designation'),
      registrationNumber: textField(json, 'registrationNumber'),
      clinicName: textField(json, 'clinicName'),
      clinicAddress: textField(json, 'clinicAddress'),
      contact: textField(json, 'contact'),
      headerExtra: textField(json, 'headerExtra'),
      logoBase64: optionalText(json['logoBase64']),
    );
  }
}
