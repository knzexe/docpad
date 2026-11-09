import 'dart:async';

import 'package:docpad/core/errors/app_exception.dart';
import 'package:docpad/data/local/key_value_store.dart';
import 'package:docpad/features/medicine/models/catalog_page.dart';
import 'package:docpad/features/medicine/repositories/catalog_cache_repository.dart';
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

      expect(find.textContaining('DEMO DATA'), findsWidgets);
      await tester.enterText(find.byKey(const Key('medicine-search')), 'fix');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      catalog.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('FixtureBrand'), findsOneWidget);
      expect(
        find.textContaining('not a verified MedEx database'),
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
    expect(
      find.text('No catalog records matched that search.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed search keeps entered patient text', (tester) async {
    final catalog = FakeCatalog(
      error: const AppException(
        'The catalog request did not complete. Your prescription text is still on this screen.',
        code: 'network',
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

  testWidgets('a failed search shows a cached fixture with its age', (
    tester,
  ) async {
    final cache = CatalogCacheRepository(MemoryStore());
    await cache.write(
      CachedMedicineSearch(
        query: 'fix',
        page: 1,
        items: const [FakeCatalog.fixtureBrand],
        hasNext: false,
        source: const CatalogSource(
          kind: 'fixture',
          providerName: 'Synthetic Development Fixtures',
        ),
        cachedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    );
    await pumpDocPad(
      tester,
      catalog: FakeCatalog(
        error: const AppException('offline', code: 'offline'),
      ),
      cache: cache,
    );
    await openEditor(tester);
    await tester.enterText(find.byKey(const Key('medicine-search')), 'fix');
    await flushSearch(tester);

    expect(find.text('FixtureBrand'), findsOneWidget);
    expect(find.textContaining('not a current catalog'), findsOneWidget);
    expect(find.textContaining('12 min ago'), findsOneWidget);
    expect(find.textContaining('Not verified MedEx records'), findsOneWidget);
    expect(find.textContaining('DEMO DATA'), findsWidgets);
  });
}
