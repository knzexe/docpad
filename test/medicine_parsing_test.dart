import 'package:docpad/core/errors/app_exception.dart';
import 'package:docpad/features/medicine/services/medex_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const envelope = {
    'data': [
      {
        'id': 'med-0001',
        'name': 'FixtureBrand',
        'generic': 'FixtureGeneric',
        'activeIngredients': ['FixtureGeneric'],
        'strength': '500 mg',
        'dosageForm': 'Tablet',
        'manufacturerId': 'mfr-0001',
        'manufacturerName': 'Fixture Labs',
        'package': 'Strip of 10 tablets',
        'priceBdt': 12.5,
        'categories': ['Demo'],
        'source': {
          'provider': 'fixture',
          'providerName': 'Synthetic Development Fixtures',
          'kind': 'fixture',
          'retrievedAt': '2026-01-01T00:00:00.000Z',
        },
      },
    ],
    'meta': {
      'page': 1,
      'limit': 20,
      'total': 1,
      'totalPages': 1,
      'hasNext': false,
      'hasPrev': false,
      'query': 'fix',
    },
    'source': {
      'provider': 'fixture',
      'providerName': 'Synthetic Development Fixtures',
      'kind': 'fixture',
      'retrievedAt': '2026-01-01T00:00:00.000Z',
    },
  };

  test('medicine search maps the v1 envelope without inventing fields', () {
    final page = parseMedicineSearch(envelope);
    final brand = page.items.single;

    expect(brand.id, 'med-0001');
    expect(brand.brandName, 'FixtureBrand');
    expect(brand.genericName, 'FixtureGeneric');
    expect(brand.strength, '500 mg');
    expect(brand.dosageForm, 'Tablet');
    expect(brand.manufacturer, 'Fixture Labs');
    expect(brand.sourceKind, 'fixture');
    expect(brand.isFixture, isTrue);
    expect(page.hasNext, isFalse);
    expect(page.total, 1);
    expect(page.source.providerName, 'Synthetic Development Fixtures');
    expect(brand.toJson()['brandName'], 'FixtureBrand');
  });

  test('medicine detail uses the data object and envelope source', () {
    final records = envelope['data']! as List<dynamic>;
    final brand = parseMedicineDetails({
      'data': records.first,
      'source': envelope['source'],
    });
    expect(brand.brandName, 'FixtureBrand');
    expect(brand.sourceKind, 'fixture');
  });

  test('a catalog record without a name is rejected', () {
    expect(
      () => parseMedicineSearch({
        'data': [
          {'id': 'med-1'},
        ],
        'meta': envelope['meta'],
        'source': envelope['source'],
      }),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'invalid_response',
        ),
      ),
    );
  });

  test('health reports a fixture provider as not live', () {
    final health = parseHealth({
      'status': 'ok',
      'version': '0.1.0',
      'provider': {
        'name': 'Synthetic Development Fixtures',
        'kind': 'fixture',
        'live': false,
      },
      'uptimeSeconds': 3,
      'timestamp': '2026-01-01T00:00:00.000Z',
    });
    expect(health.isFixture, isTrue);
    expect(health.live, isFalse);
    expect(health.providerName, 'Synthetic Development Fixtures');
  });

  test('generic search keeps description null when the API sends null', () {
    final page = parseGenericSearch({
      'data': [
        {
          'id': 'gen-0001',
          'name': 'FixtureGeneric',
          'activeIngredients': ['FixtureGeneric'],
          'description': null,
          'brandCount': 2,
          'source': envelope['source'],
        },
      ],
      'meta': envelope['meta'],
      'source': envelope['source'],
    });
    expect(page.items.single.description, isNull);
    expect(page.items.single.brandCount, 2);
    expect(page.items.single.isFixture, isTrue);
  });
}
