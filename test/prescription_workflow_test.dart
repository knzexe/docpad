import 'package:docpad/features/pdf/services/prescription_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('prescription action bars fit a narrow mobile screen', (
    tester,
  ) async {
    await pumpDocPad(tester, size: const Size(320, 800));
    await tester.tap(find.byKey(const Key('new-prescription')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('open-preview')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finalize')), findsOneWidget);
    expect(find.byKey(const Key('export-pdf')), findsOneWidget);
    expect(find.byKey(const Key('print-pdf')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a doctor can document, save, reopen, and export a prescription',
    (tester) async {
      final harness = await pumpDocPad(
        tester,
        catalog: FakeCatalog(page: FakeCatalog.fixturePage()),
      );

      await tester.tap(find.byKey(const Key('new-prescription')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('patient-name')),
        'Amina Rahman',
      );
      await tester.enterText(
        find.byKey(const Key('patient-phone')),
        '+880 1711 223344',
      );
      await tester.enterText(find.byKey(const Key('patient-age')), '34');
      await tester.tap(find.text('Female'));
      await reveal(tester, find.byKey(const Key('chief-complaint')));
      await tester.enterText(
        find.byKey(const Key('chief-complaint')),
        'Headache for two days',
      );

      await tester.enterText(find.byKey(const Key('medicine-search')), 'fix');
      await flushSearch(tester);
      await tester.ensureVisible(find.byKey(const Key('result-med-fixture-1')));
      await tester.tap(find.byKey(const Key('result-med-fixture-1')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('dose-field')))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.textContaining('Type each value yourself'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('dose-field')), '1 tablet');
      await tester.enterText(
        find.byKey(const Key('frequency-field')),
        'three times daily',
      );
      await tester.enterText(find.byKey(const Key('duration-field')), '3 days');
      await tester.ensureVisible(find.byKey(const Key('add-medicine-confirm')));
      await tester.tap(find.byKey(const Key('add-medicine-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Dose: 1 tablet'), findsOneWidget);
      expect(find.textContaining('DEMO DATA'), findsWidgets);

      await reveal(tester, find.byKey(const Key('advice-custom')));
      await tester.enterText(
        find.byKey(const Key('advice-custom')),
        'Rest and drink water',
      );
      await reveal(tester, find.byKey(const Key('add-custom-advice')));
      await tester.tap(find.byKey(const Key('add-custom-advice')));
      await tester.pump();
      expect(find.text('1. Rest and drink water'), findsOneWidget);

      await tester.tap(find.byKey(const Key('save-draft')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Amina Rahman'), findsWidgets);
      expect(find.text('Draft'), findsWidgets);

      await tester.tap(find.text('Amina Rahman').first);
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('chief-complaint')));
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chief-complaint')))
            .controller!
            .text,
        'Headache for two days',
      );

      await tester.enterText(
        find.byKey(const Key('chief-complaint')),
        'Headache, now milder',
      );
      await tester.tap(find.byKey(const Key('open-preview')));
      await tester.pumpAndSettle();

      expect(find.textContaining('DRAFT'), findsWidgets);
      expect(find.textContaining('Amina Rahman'), findsWidgets);
      expect(find.textContaining('1 tablet'), findsWidgets);
      expect(find.textContaining('Rest and drink water'), findsWidgets);
      expect(find.textContaining('Headache, now milder'), findsWidgets);

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      final saved = await harness.prescriptions.getAll();
      expect(saved, hasLength(1));
      expect(saved.single.isDraft, isTrue);
      expect(saved.single.chiefComplaint, 'Headache, now milder');

      final bytes = await PrescriptionPdfService().generatePrescriptionPdf(
        saved.single,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    },
  );

  testWidgets('finalizing without patient fields stays on the draft', (
    tester,
  ) async {
    await pumpDocPad(tester);
    await tester.tap(find.byKey(const Key('new-prescription')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-preview')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finalize')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Finalize'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter the required patient fields before finalizing.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('preview-back')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the patient name.'), findsOneWidget);
  });
}
