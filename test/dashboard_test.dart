import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('dashboard starts empty and opens a new prescription', (
    tester,
  ) async {
    await pumpDocPad(tester);

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
}
