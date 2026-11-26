import 'dart:async';

import 'package:docpad/core/errors/app_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  Future<void> openEditor(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('new-prescription')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'search shows a loading state, then fixture results as demo data',
    (tester) async {
      final catalog = FakeCatalog(page: FakeCatalog.fixturePage());
      catalog.gate = Completer<void>();
      await pumpDocPad(tester, catalog: catalog);
      await openEditor(tester);

      await tester.enterText(find.byKey(const Key('medicine-search')), 'fix');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      catalog.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('FixtureBrand'), findsOneWidget);
      expect(
        find.textContaining('not verified medicine information'),
        findsWidgets,
      );
      expect(find.textContaining('Source: fixture'), findsOneWidget);
    },
  );

  testWidgets('an empty catalog result stays empty', (tester) async {
    final catalog = FakeCatalog();
    await pumpDocPad(tester, catalog: catalog);
    await openEditor(tester);
    await tester.enterText(find.byKey(const Key('medicine-search')), 'zzz');
    await flushSearch(tester);

    expect(catalog.searchCalls, 1);
    expect(find.text('No medicines matched that search.'), findsOneWidget);
  });

  testWidgets('a manually entered medicine is saved and prescribed', (
    tester,
  ) async {
    final harness = await pumpDocPad(tester, size: const Size(320, 800));
    await openEditor(tester);

    await reveal(tester, find.byKey(const Key('add-medicine-manually')));
    await tester.tap(find.byKey(const Key('add-medicine-manually')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('library-medicine-brand')),
      'Custom medicine',
    );
    await tester.tap(find.text('Save medicine'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('dose-field')), '1 tablet');
    await tester.enterText(
      find.byKey(const Key('frequency-field')),
      'Twice daily',
    );
    await tester.enterText(find.byKey(const Key('duration-field')), '5 days');
    await tester.ensureVisible(find.byKey(const Key('add-medicine-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-medicine-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dose-field')), findsNothing);
    expect(find.text('Custom medicine'), findsOneWidget);
    expect(find.textContaining('Dose: 1 tablet'), findsOneWidget);
    expect(
      (await harness.medicines.getAll()).single.brandName,
      'Custom medicine',
    );
  });

  testWidgets('a failed local search keeps entered patient text', (
    tester,
  ) async {
    final catalog = FakeCatalog(
      error: const AppException(
        'The local medicine library could not be read. Your prescription text is still on this screen.',
        code: 'local_storage',
      ),
    );
    await pumpDocPad(tester, catalog: catalog);
    await openEditor(tester);
    await tester.enterText(
      find.byKey(const Key('patient-name')),
      'Amina Rahman',
    );
    await tester.enterText(find.byKey(const Key('medicine-search')), 'fix');
    await flushSearch(tester);

    expect(catalog.searchCalls, greaterThan(0));
    expect(
      find.textContaining('Your prescription text is still on this screen.'),
      findsOneWidget,
    );
    expect(find.text('Amina Rahman'), findsOneWidget);
  });
}
