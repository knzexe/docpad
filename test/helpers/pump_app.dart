import 'package:docpad/core/providers/connectivity_provider.dart';
import 'package:docpad/data/local/key_value_store.dart';
import 'package:docpad/data/repository_providers.dart';
import 'package:docpad/features/advice/repositories/advice_repository.dart';
import 'package:docpad/features/medicine/providers/medicine_providers.dart';
import 'package:docpad/features/medicine/repositories/catalog_cache_repository.dart';
import 'package:docpad/features/patients/repositories/patient_repository.dart';
import 'package:docpad/features/prescription/repositories/prescription_repository.dart';
import 'package:docpad/features/settings/repositories/profile_repository.dart';
import 'package:docpad/features/settings/repositories/settings_repository.dart';
import 'package:docpad/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'fakes.dart';

class TestHarness {
  TestHarness({
    required this.prescriptions,
    required this.patients,
    required this.advice,
    required this.cache,
    required this.catalog,
  });

  final PrescriptionRepository prescriptions;
  final PatientRepository patients;
  final AdviceRepository advice;
  final CatalogCacheRepository cache;
  final FakeCatalog catalog;
}

Future<TestHarness> pumpDocPad(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
  FakeCatalog? catalog,
  CatalogCacheRepository? cache,
}) async {
  await initializeDateFormatting('en');
  await initializeDateFormatting('bn');
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final harness = TestHarness(
    prescriptions: PrescriptionRepository(MemoryStore()),
    patients: PatientRepository(MemoryStore()),
    advice: AdviceRepository(MemoryStore()),
    cache: cache ?? CatalogCacheRepository(MemoryStore()),
    catalog: catalog ?? FakeCatalog(),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(
          ProfileRepository(MemoryStore()),
        ),
        prescriptionRepositoryProvider.overrideWithValue(harness.prescriptions),
        patientRepositoryProvider.overrideWithValue(harness.patients),
        adviceRepositoryProvider.overrideWithValue(harness.advice),
        catalogCacheRepositoryProvider.overrideWithValue(harness.cache),
        medicineApiProvider.overrideWithValue(harness.catalog),
        onlineProvider.overrideWith((ref) => Stream<bool>.value(true)),
      ],
      child: const DocPadApp(),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

/// Search is debounced. [pumpAndSettle] can return before that timer when no
/// frame is scheduled, so catalog tests advance the clock explicitly.
Future<void> flushSearch(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Future<void> reveal(
  WidgetTester tester,
  Finder target, {
  Key scrollKey = const Key('editor-left'),
}) async {
  final list = find.byKey(scrollKey);
  for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(list, const Offset(0, -320));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}
