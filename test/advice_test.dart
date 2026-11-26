import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docpad/features/advice/models/advice_template.dart';

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

  testWidgets('advice actions fit a narrow mobile screen', (tester) async {
    final harness = await pumpDocPad(tester, size: const Size(320, 800));
    await harness.advice.save(
      AdviceTemplate(
        id: 'advice-1',
        title: 'Rest',
        body: 'Rest as needed',
        sortOrder: 0,
        updatedAt: DateTime(2026),
      ),
    );

    await tester.tap(find.byKey(const Key('nav-advice')));
    await tester.pumpAndSettle();
    expect(find.text('Rest'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Move down'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
