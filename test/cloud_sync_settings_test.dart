import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('settings clearly shows when cloud sync is not configured', (
    tester,
  ) async {
    await pumpDocPad(tester, size: const Size(390, 844));
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();

    expect(find.text('Clinic cloud sync'), findsOneWidget);
    expect(find.textContaining('Cloud sync is not configured'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });
}
