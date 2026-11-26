import 'package:docpad/features/medicine/models/medicine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('medicine library actions fit a narrow mobile screen', (
    tester,
  ) async {
    final harness = await pumpDocPad(tester, size: const Size(320, 800));
    final now = DateTime(2026);
    await harness.medicines.upsert(
      Medicine(
        id: 'medicine-1',
        brandName: 'Paracetamol',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.tap(find.byKey(const Key('nav-medicines')));
    await tester.pumpAndSettle();
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('add-medicine')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Add to prescription'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
