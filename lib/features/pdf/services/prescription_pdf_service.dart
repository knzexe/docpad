import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/errors/app_exception.dart';
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
    final doctor = prescription.header ?? DoctorProfile.empty;
    final doc = pw.Document(
      title: fileStem(prescription),
      author: doctor.name.trim().isEmpty ? 'DocPad' : doctor.name.trim(),
    );
    final logo = includeLogo ? _logo(doctor.logoBase64) : null;

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
        footer: (context) => _footer(context, strings),
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
          _patientBlock(prescription, strings),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey600, thickness: 0.4),
          _labeled(
            strings.chiefComplaint,
            prescription.chiefComplaint,
            strings,
          ),
          _labeled(strings.history, prescription.history, strings),
          _labeled(
            strings.medicalHistory,
            prescription.medicalHistory,
            strings,
          ),
          _labeled(
            strings.examinationNotes,
            prescription.examinationNotes,
            strings,
          ),
          _labeled(strings.assessment, prescription.assessment, strings),
          _labeled(
            strings.investigationNotes,
            prescription.investigationNotes,
            strings,
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey600, thickness: 0.4),
          pw.SizedBox(height: 8),
          pw.Text(
            strings.rx,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 6),
          if (prescription.medicines.isEmpty)
            pw.Text(
              strings.noMedicinesRecorded,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            )
          else
            ...prescription.medicines.indexed.map(
              (entry) => _medicine(entry.$1 + 1, entry.$2, strings),
            ),
          pw.SizedBox(height: 8),
          pw.Text(
            strings.advicePdf,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 4),
          if (prescription.advice
              .where((item) => item.trim().isNotEmpty)
              .isEmpty)
            pw.Text(
              strings.notRecorded,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            )
          else
            ...prescription.advice
                .where((item) => item.trim().isNotEmpty)
                .indexed
                .map(
                  (entry) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      '${entry.$1 + 1}. ${_printable(entry.$2)}',
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
                    ),
                  ),
                ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${strings.nextVisit}: ${prescription.nextVisit == null ? strings.notRecorded : formatDate(prescription.nextVisit!, languageCode: prescription.documentLanguage)}',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 18),
          _signature(doctor, strings),
          pw.SizedBox(height: 12),
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

  pw.Widget _footer(pw.Context context, AppStrings strings) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        strings.page(context.pageNumber, context.pagesCount),
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
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
      if (doctor.clinicName.trim().isNotEmpty) doctor.clinicName.trim(),
      if (doctor.clinicAddress.trim().isNotEmpty) doctor.clinicAddress.trim(),
      if (doctor.contact.trim().isNotEmpty) doctor.contact.trim(),
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
    final rows = [
      [
        strings.patientName,
        patient.name.trim().isEmpty ? strings.notRecorded : patient.name,
      ],
      [
        strings.age,
        patient.age == null ? strings.notRecorded : '${patient.age}',
      ],
      [strings.sex, strings.sexLabel(patient.sex)],
      [
        strings.phone,
        patient.phone.trim().isEmpty ? strings.notRecorded : patient.phone,
      ],
      [
        strings.prescriptionDate,
        formatDate(
          patient.prescriptionDate,
          languageCode: prescription.documentLanguage,
        ),
      ],
      if (patient.patientCode?.trim().isNotEmpty ?? false)
        [strings.patientId, patient.patientCode!],
      if (patient.address?.trim().isNotEmpty ?? false)
        [strings.address, patient.address!],
      if (patient.identificationNotes?.trim().isNotEmpty ?? false)
        [strings.identificationNotes, patient.identificationNotes!],
    ];
    return pw.Column(
      children: [
        for (final row in rows)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 130,
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    _printable(row[1]),
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _labeled(String label, String value, AppStrings strings) {
    final empty = value.trim().isEmpty;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _printable(empty ? strings.notRecorded : value),
            style: pw.TextStyle(
              fontSize: 11,
              lineSpacing: 2,
              color: empty ? PdfColors.grey700 : PdfColors.black,
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
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$index. ${_printable(item.brandName)}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (generic.isNotEmpty)
            pw.Text(generic, style: const pw.TextStyle(fontSize: 10)),
          if (form.isNotEmpty)
            pw.Text(form, style: const pw.TextStyle(fontSize: 10)),
          _line(strings.dose, item.dose, strings),
          _line(strings.frequency, item.frequency, strings),
          _line(strings.duration, item.duration, strings),
          _line(strings.route, item.route, strings),
          _line(strings.timing, item.timing, strings),
          _line(strings.specialInstructions, item.instructions, strings),
          _line(strings.quantity, item.quantity, strings),
        ],
      ),
    );
  }

  pw.Widget _line(String label, String value, AppStrings strings) {
    final shown = value.trim().isEmpty ? strings.notRecorded : value.trim();
    return pw.Text(
      '$label: ${_printable(shown)}',
      style: const pw.TextStyle(fontSize: 10, lineSpacing: 1),
    );
  }

  pw.Widget _signature(DoctorProfile doctor, AppStrings strings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
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

  pw.Widget? _logo(String? base64Value) {
    if (base64Value == null || base64Value.isEmpty) return null;
    try {
      final bytes = base64Decode(base64Value);
      return pw.Container(
        width: 42,
        height: 42,
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
    return 'DocPad-$suffix';
  }
}

const _ink = PdfColor.fromInt(0xFF176B5B);

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
