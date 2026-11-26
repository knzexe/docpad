import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/clinic_branding.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/utils/dates.dart';
import '../../prescription/models/prescription.dart';
import '../../prescription/models/prescribed_medicine.dart';
import '../../settings/models/doctor_profile.dart';

class PrescriptionPdfService {
  Future<pw.ThemeData>? _theme;

  Future<Uint8List> generatePrescriptionPdf(Prescription prescription) async {
    try {
      final bytes = await _render(prescription, includeLogo: true);
      _assertPdf(bytes);
      return bytes;
    } catch (error) {
      if (prescription.header?.logoBase64?.isNotEmpty ?? false) {
        try {
          final bytes = await _render(prescription, includeLogo: false);
          _assertPdf(bytes);
          return bytes;
        } catch (inner) {
          AppLog.error('pdf', inner);
        }
      } else {
        AppLog.error('pdf', error);
      }
      throw const AppException('The PDF could not be created.', code: 'pdf');
    }
  }

  Future<void> previewAndPrint(Prescription prescription) async {
    try {
      final printed = await Printing.layoutPdf(
        name: fileStem(prescription),
        format: PdfPageFormat.a4,
        onLayout: (_) => generatePrescriptionPdf(prescription),
      );
      if (!printed) {
        throw const AppException(
          'Printing was cancelled.',
          code: 'print_cancelled',
        );
      }
    } on AppException {
      rethrow;
    } catch (error) {
      AppLog.error('print', error);
      throw const AppException(
        'Printing did not complete.',
        code: 'print_failed',
      );
    }
  }

  Future<Uint8List> _render(
    Prescription prescription, {
    required bool includeLogo,
  }) async {
    final theme = await _loadTheme();
    final strings = AppStrings(prescription.documentLanguage);
    final doctor = prescription.header ?? DoctorProfile.clinicDefault;
    final clinicalSections = <(String, String)>[
      (strings.chiefComplaint, prescription.chiefComplaint),
      (strings.history, prescription.history),
      (strings.medicalHistory, prescription.medicalHistory),
      (strings.examinationNotes, prescription.examinationNotes),
      (strings.assessment, prescription.assessment),
      (strings.investigationNotes, prescription.investigationNotes),
    ].where((section) => section.$2.trim().isNotEmpty).toList();
    final doc = pw.Document(
      title: fileStem(prescription),
      author: doctor.name.trim().isEmpty
          ? ClinicBranding.name
          : doctor.name.trim(),
    );
    final logo = includeLogo ? await _logo(doctor.logoBase64) : null;

    doc.addPage(
      pw.MultiPage(
        maxPages: 80,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 36, 42, 46),
          theme: theme,
          buildBackground: (context) => _watermark(prescription),
        ),
        header: (context) => _runningHeader(context, prescription, strings),
        footer: (context) => _footer(context, doctor, strings),
        build: (context) => [
          _doctorHeader(doctor, logo, strings),
          pw.SizedBox(height: 8),
          pw.Divider(color: _ink, thickness: 0.8),
          if (prescription.isDraft) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              strings.draftBanner,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _panel,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: _accent, width: 0.6),
            ),
            child: _patientBlock(prescription, strings),
          ),
          pw.SizedBox(height: 8),
          if (clinicalSections.isNotEmpty) ...[
            _sectionHeading(strings.clinicalNotes),
            pw.SizedBox(height: 4),
            for (final section in clinicalSections)
              _labeled(section.$1, section.$2),
            pw.SizedBox(height: 12),
          ],
          _sectionHeading(strings.rx),
          pw.SizedBox(height: 6),
          if (prescription.medicines.isEmpty)
            pw.Text(
              strings.noMedicinesRecorded,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            )
          else
            ...prescription.medicines.indexed.map(
              (entry) => _medicine(entry.$1 + 1, entry.$2, strings),
            ),
          pw.SizedBox(height: 12),
          _sectionHeading(strings.advicePdf),
          pw.SizedBox(height: 5),
          if (prescription.advice
              .where((item) => item.trim().isNotEmpty)
              .isEmpty)
            pw.Text(
              strings.notRecorded,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            )
          else
            ...prescription.advice
                .where((item) => item.trim().isNotEmpty)
                .indexed
                .map(
                  (entry) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 18,
                          child: pw.Text(
                            '${entry.$1 + 1}.',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _accent,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            _printable(entry.$2),
                            style: const pw.TextStyle(
                              fontSize: 10,
                              lineSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          pw.SizedBox(height: 10),
          _nextVisit(prescription, strings),
          pw.SizedBox(height: 16),
          _signature(doctor, strings),
          pw.SizedBox(height: 10),
          pw.Text(
            strings.prescriberNote,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          if (prescription.usesFixtureCatalog) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              strings.fixturePdfNote,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }

  Future<pw.ThemeData> _loadTheme() {
    return _theme ??= () async {
      final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
      );
      final bengali = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf'),
      );
      final bengaliBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf'),
      );
      return pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: regular,
        boldItalic: bold,
        fontFallback: [bengali, bengaliBold],
      );
    }();
  }

  pw.Widget _watermark(Prescription prescription) {
    if (!prescription.isDraft) return pw.SizedBox();
    return pw.Center(
      child: pw.Transform.rotate(
        angle: -0.5,
        child: pw.Text(
          'DRAFT',
          style: pw.TextStyle(
            fontSize: 72,
            color: PdfColors.grey300,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _runningHeader(
    pw.Context context,
    Prescription prescription,
    AppStrings strings,
  ) {
    if (context.pageNumber == 1) return pw.SizedBox();
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.4),
        ),
      ),
      child: pw.Text(
        '${_printable(prescription.patient.name)} | ${strings.prescription}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
      ),
    );
  }

  pw.Widget _footer(
    pw.Context context,
    DoctorProfile doctor,
    AppStrings strings,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _accent, width: 0.7)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (doctor.clinicAddress.trim().isNotEmpty)
                  pw.Text(
                    _printable(doctor.clinicAddress.trim()),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                if (doctor.contact.trim().isNotEmpty)
                  pw.Text(
                    doctor.contact.trim(),
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: _ink,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          pw.Text(
            strings.page(context.pageNumber, context.pagesCount),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _doctorHeader(
    DoctorProfile doctor,
    pw.Widget? logo,
    AppStrings strings,
  ) {
    final lines = <String>[
      if (doctor.designation.trim().isNotEmpty) doctor.designation.trim(),
      if (doctor.registrationNumber.trim().isNotEmpty)
        '${strings.registrationNumber}: ${doctor.registrationNumber.trim()}',
      if (doctor.headerExtra.trim().isNotEmpty) doctor.headerExtra.trim(),
    ];
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null) ...[logo, pw.SizedBox(width: 10)],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                doctor.clinicName.trim().isEmpty
                    ? ClinicBranding.name
                    : doctor.clinicName.trim(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                ClinicBranding.tagline,
                style: const pw.TextStyle(fontSize: 9, color: _accent),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                doctor.name.trim().isEmpty
                    ? strings.doctorNameMissingPdf
                    : doctor.name.trim(),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
                textAlign: pw.TextAlign.center,
              ),
              for (final line in lines)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    _printable(line),
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _patientBlock(Prescription prescription, AppStrings strings) {
    final patient = prescription.patient;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: _patientCell(
                strings.patientName,
                patient.name.trim().isEmpty
                    ? strings.notRecorded
                    : patient.name,
                emphasized: true,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: _patientCell(
                strings.age,
                patient.age == null ? strings.notRecorded : '${patient.age}',
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: _patientCell(strings.sex, strings.sexLabel(patient.sex)),
            ),
            pw.Expanded(
              flex: 3,
              child: _patientCell(
                strings.prescriptionDate,
                formatDate(
                  patient.prescriptionDate,
                  languageCode: prescription.documentLanguage,
                ),
              ),
            ),
          ],
        ),
        if (patient.phone.trim().isNotEmpty ||
            patient.patientCode?.trim().isNotEmpty == true ||
            patient.address?.trim().isNotEmpty == true) ...[
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (patient.phone.trim().isNotEmpty)
                pw.Expanded(
                  flex: 2,
                  child: _patientCell(strings.phone, patient.phone),
                ),
              if (patient.patientCode?.trim().isNotEmpty ?? false)
                pw.Expanded(
                  flex: 2,
                  child: _patientCell(strings.patientId, patient.patientCode!),
                ),
              if (patient.address?.trim().isNotEmpty ?? false)
                pw.Expanded(
                  flex: 3,
                  child: _patientCell(strings.address, patient.address!),
                ),
            ],
          ),
        ],
        if (patient.identificationNotes?.trim().isNotEmpty ?? false) ...[
          pw.SizedBox(height: 8),
          _patientCell(
            strings.identificationNotes,
            patient.identificationNotes!,
          ),
        ],
      ],
    );
  }

  pw.Widget _patientCell(
    String label,
    String value, {
    bool emphasized = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          _printable(value),
          style: pw.TextStyle(
            fontSize: emphasized ? 12 : 10,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionHeading(String label) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(child: pw.Container(height: 0.8, color: _accent)),
      ],
    );
  }

  pw.Widget _labeled(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _printable(value.trim()),
                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _medicine(int index, PrescribedMedicine item, AppStrings strings) {
    final form = [
      if (item.strength?.trim().isNotEmpty ?? false) item.strength!.trim(),
      if (item.dosageForm?.trim().isNotEmpty ?? false) item.dosageForm!.trim(),
    ].join(' / ');
    final generic = item.genericName?.trim() ?? '';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 22,
                  height: 22,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: _accent,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    '$index',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _printable(item.brandName),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      if (generic.isNotEmpty)
                        pw.Text(
                          _printable(generic),
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey800,
                          ),
                        ),
                      if (form.isNotEmpty)
                        pw.Text(
                          _printable(form),
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey800,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Container(height: 0.5, color: PdfColors.grey300),
            pw.SizedBox(height: 4),
            _line(strings.dose, item.dose, strings),
            _line(strings.frequency, item.frequency, strings),
            _line(strings.duration, item.duration, strings),
            _line(strings.route, item.route, strings),
            _line(strings.timing, item.timing, strings),
            _line(strings.specialInstructions, item.instructions, strings),
            _line(strings.quantity, item.quantity, strings),
          ],
        ),
      ),
    );
  }

  pw.Widget _line(String label, String value, AppStrings strings) {
    final shown = value.trim().isEmpty ? strings.notRecorded : value.trim();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 88,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _printable(shown),
              style: const pw.TextStyle(fontSize: 9, lineSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _nextVisit(Prescription prescription, AppStrings strings) {
    final date = prescription.nextVisit == null
        ? strings.notRecorded
        : formatDate(
            prescription.nextVisit!,
            languageCode: prescription.documentLanguage,
          );
    return pw.Row(
      children: [
        pw.Text(
          '${strings.nextVisit}:',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(date, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  pw.Widget _signature(DoctorProfile doctor, AppStrings strings) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 180,
          padding: const pw.EdgeInsets.only(top: 16),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.black, width: 0.6),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                doctor.name.trim().isEmpty
                    ? strings.doctorNameMissingPdf
                    : doctor.name.trim(),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (doctor.designation.trim().isNotEmpty)
                pw.Text(
                  doctor.designation.trim(),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              pw.Text(
                strings.signature,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<pw.Widget?> _logo(String? base64Value) async {
    try {
      final bytes = base64Value == null || base64Value.isEmpty
          ? (await rootBundle.load(ClinicBranding.logoAsset)).buffer
                .asUint8List()
          : base64Decode(base64Value);
      return pw.Container(
        width: 62,
        height: 62,
        child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
      );
    } catch (error) {
      AppLog.error('pdf-logo', error);
      return null;
    }
  }

  void _assertPdf(Uint8List bytes) {
    if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const AppException('The PDF could not be created.', code: 'pdf');
    }
  }

  static String fileStem(Prescription prescription) {
    final suffix = prescription.id.length <= 8
        ? prescription.id
        : prescription.id.substring(0, 8);
    return '${ClinicBranding.filePrefix}-$suffix';
  }
}

const _ink = PdfColor.fromInt(0xFF173E67);
const _accent = PdfColor.fromInt(0xFF087F8C);
const _panel = PdfColor.fromInt(0xFFEAF6F2);

String _printable(String value) {
  final buffer = StringBuffer();
  var run = 0;
  for (final rune in value.runes) {
    buffer.writeCharCode(rune);
    final whitespace = rune == 0x20 || rune == 0x0A || rune == 0x09;
    if (whitespace) {
      run = 0;
    } else {
      run += 1;
      if (run >= 40) {
        buffer.write('\n');
        run = 0;
      }
    }
  }
  return buffer.toString();
}
