import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets(
    'advice templates can be created and selected on a prescription',
    (tester) async {
      await pumpDocPad(tester);

      await tester.tap(find.byKey(const Key('nav-advice')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add template'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('template-title')), 'Fluids');
      await tester.enterText(
        find.byKey(const Key('template-body')),
        'Drink water through the day',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Fluids'), findsOneWidget);
      expect(find.text('Drink water through the day'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-prescription')));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Fluids'));
      await tester.tap(find.text('Fluids'));
      await tester.pump();

      expect(find.text('1. Drink water through the day'), findsOneWidget);
    },
  );
}
