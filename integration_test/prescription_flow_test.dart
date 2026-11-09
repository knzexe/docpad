import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fakes.dart';
import '../test/helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create a local draft without a live catalog', (tester) async {
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
    await tester.tap(find.byKey(const Key('save-draft')));
    await tester.pumpAndSettle();

    final saved = await harness.prescriptions.getAll();
    expect(saved, hasLength(1));
    expect(saved.single.patient.name, 'Amina Rahman');
    expect(saved.single.isDraft, isTrue);
  });
}
