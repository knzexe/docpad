import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('dashboard starts empty and opens a new prescription', (
    tester,
  ) async {
    await pumpDocPad(tester);

    expect(find.text('Raifa Medicine & SS Health Care'), findsWidgets);
    expect(find.text('Dr. Morsalin Bin Sakhawat'), findsWidgets);
    expect(find.text('No prescriptions yet'), findsOneWidget);
    expect(find.text('Create the first prescription'), findsOneWidget);
    expect(find.textContaining('patients today'), findsNothing);

    await tester.tap(find.byKey(const Key('new-prescription')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('patient-name')), findsOneWidget);
    expect(find.text('Draft'), findsWidgets);
  });

  testWidgets('mobile uses a bottom bar and desktop uses a rail', (
    tester,
  ) async {
    await pumpDocPad(tester, size: const Size(400, 800));
    expect(find.byKey(const Key('nav-bar')), findsOneWidget);
    expect(find.byKey(const Key('nav-rail')), findsNothing);

    await pumpDocPad(tester, size: const Size(1280, 800));
    expect(find.byKey(const Key('nav-rail')), findsOneWidget);
    expect(find.byKey(const Key('nav-bar')), findsNothing);
  });

  testWidgets('prescription layouts adapt across phone, tablet, and desktop', (
    tester,
  ) async {
    const sizes = [
      Size(320, 800),
      Size(600, 900),
      Size(800, 900),
      Size(1024, 768),
      Size(1100, 768),
      Size(1200, 800),
      Size(1440, 900),
    ];
    await pumpDocPad(tester, size: sizes.first);

    for (final size in sizes) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-prescription')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('open-preview')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('preview-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
