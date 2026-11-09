import 'dart:convert';

import '../../../core/utils/json_readers.dart';
import '../../patients/models/patient.dart';
import '../../settings/models/doctor_profile.dart';
import 'prescribed_medicine.dart';

const _unset = Object();

class Prescription {
  const Prescription({
    required this.id,
    required this.patient,
    required this.chiefComplaint,
    required this.history,
    required this.medicalHistory,
    required this.investigationNotes,
    required this.examinationNotes,
    required this.assessment,
    required this.medicines,
    required this.advice,
    required this.createdAt,
    required this.updatedAt,
    required this.isDraft,
    required this.documentLanguage,
    this.nextVisit,
    this.header,
  });

  final String id;
  final Patient patient;
  final String chiefComplaint;
  final String history;
  final String medicalHistory;
  final String investigationNotes;
  final String examinationNotes;
  final String assessment;
  final List<PrescribedMedicine> medicines;
  final List<String> advice;
  final DateTime? nextVisit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDraft;
  final String documentLanguage;
  final DoctorProfile? header;

  bool get hasContent {
    return patient.name.trim().isNotEmpty ||
        patient.phone.trim().isNotEmpty ||
        patient.age != null ||
        (patient.sex != null && patient.sex!.isNotEmpty) ||
        (patient.address?.trim().isNotEmpty ?? false) ||
        (patient.patientCode?.trim().isNotEmpty ?? false) ||
        (patient.identificationNotes?.trim().isNotEmpty ?? false) ||
        chiefComplaint.trim().isNotEmpty ||
        history.trim().isNotEmpty ||
        medicalHistory.trim().isNotEmpty ||
        investigationNotes.trim().isNotEmpty ||
        examinationNotes.trim().isNotEmpty ||
        assessment.trim().isNotEmpty ||
        medicines.isNotEmpty ||
        advice.any((item) => item.trim().isNotEmpty) ||
        nextVisit != null;
  }

  bool get usesFixtureCatalog =>
      medicines.any((item) => item.sourceKind == 'fixture');

  Prescription copyWith({
    String? id,
    Patient? patient,
    String? chiefComplaint,
    String? history,
    String? medicalHistory,
    String? investigationNotes,
    String? examinationNotes,
    String? assessment,
    List<PrescribedMedicine>? medicines,
    List<String>? advice,
    Object? nextVisit = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDraft,
    String? documentLanguage,
    Object? header = _unset,
  }) {
    return Prescription(
      id: id ?? this.id,
      patient: patient ?? this.patient,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      history: history ?? this.history,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      investigationNotes: investigationNotes ?? this.investigationNotes,
      examinationNotes: examinationNotes ?? this.examinationNotes,
      assessment: assessment ?? this.assessment,
      medicines: medicines ?? this.medicines,
      advice: advice ?? this.advice,
      nextVisit: nextVisit == _unset ? this.nextVisit : nextVisit as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDraft: isDraft ?? this.isDraft,
      documentLanguage: documentLanguage ?? this.documentLanguage,
      header: header == _unset ? this.header : header as DoctorProfile?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient': patient.toJson(),
    'chiefComplaint': chiefComplaint,
    'history': history,
    'medicalHistory': medicalHistory,
    'investigationNotes': investigationNotes,
    'examinationNotes': examinationNotes,
    'assessment': assessment,
    'medicines': medicines.map((item) => item.toJson()).toList(),
    'advice': advice,
    'nextVisit': nextVisit?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDraft': isDraft,
    'documentLanguage': documentLanguage,
    'header': header?.toJson(),
  };

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Prescription id is missing');
    }
    final patientJson = json['patient'];
    if (patientJson is! Map) {
      throw const FormatException('Prescription patient is missing');
    }
    final medicineJson = json['medicines'];
    if (medicineJson is! List) {
      throw const FormatException('Prescription medicines are missing');
    }
    final adviceJson = json['advice'];
    if (adviceJson is! List) {
      throw const FormatException('Prescription advice is missing');
    }
    final headerJson = json['header'];
    return Prescription(
      id: id,
      patient: Patient.fromJson(Map<String, dynamic>.from(patientJson)),
      chiefComplaint: textField(json, 'chiefComplaint'),
      history: textField(json, 'history'),
      medicalHistory: textField(json, 'medicalHistory'),
      investigationNotes: textField(json, 'investigationNotes'),
      examinationNotes: textField(json, 'examinationNotes'),
      assessment: textField(json, 'assessment'),
      medicines: [
        for (final item in medicineJson)
          if (item is Map)
            PrescribedMedicine.fromJson(Map<String, dynamic>.from(item))
          else
            throw const FormatException('Medicine entry is unreadable'),
      ],
      advice: [
        for (final item in adviceJson)
          if (item is String)
            item
          else
            throw const FormatException('Advice entry is unreadable'),
      ],
      nextVisit: optionalDate(json['nextVisit']),
      createdAt: requiredDate(json, 'createdAt'),
      updatedAt: requiredDate(json, 'updatedAt'),
      isDraft: json['isDraft'] is bool ? json['isDraft'] as bool : true,
      documentLanguage: json['documentLanguage'] == 'bn' ? 'bn' : 'en',
      header: headerJson is Map
          ? DoctorProfile.fromJson(Map<String, dynamic>.from(headerJson))
          : null,
    );
  }

  String contentKey() => jsonEncode(_contentJson(includeDraft: true));

  String bodyKey() => jsonEncode(_contentJson(includeDraft: false));

  Map<String, dynamic> _contentJson({required bool includeDraft}) {
    final json = toJson()
      ..remove('updatedAt')
      ..remove('createdAt')
      ..remove('header')
      ..remove('documentLanguage');
    if (!includeDraft) json.remove('isDraft');
    return json;
  }
}
