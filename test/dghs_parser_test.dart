import 'package:docpad/features/medicine/services/dghs_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a DGHS medication record and skips retired ones', () {
    final brand = dghsBrandFromMedication({
      'resourceType': 'Medication',
      'id': '11111111-1111-1111-1111-111111111111',
      'name': 'Resadol Tablet',
      'code': {
        'coding': [
          {'display': 'Paracetamol, combinations excl. psycholeptics'},
        ],
      },
      'product': {
        'form': {
          'coding': [
            {'display': 'Tablet dose form'},
          ],
        },
      },
      'extension': [
        {
          'url': 'https://example.test/MedicationStrength',
          'valueString': '325 mg + 37.5 mg',
        },
        {
          'url': 'https://example.test/MedicationRetired',
          'valueString': 'false',
        },
      ],
    });

    expect(brand, isNotNull);
    expect(brand!.brandName, 'Resadol Tablet');
    expect(brand.genericName, 'Paracetamol, combinations excl. psycholeptics');
    expect(brand.strength, '325 mg + 37.5 mg');
    expect(brand.dosageForm, 'Tablet dose form');
    expect(brand.sourceKind, 'live');
    expect(brand.sourceLabel, 'DGHS Terminology Registry');
    expect(brand.manufacturer, isNull);

    final retired = dghsBrandFromMedication({
      'id': '22222222-2222-2222-2222-222222222222',
      'name': 'Old Tablet',
      'extension': [
        {
          'url': 'https://example.test/MedicationRetired',
          'valueString': 'true',
        },
      ],
    });
    expect(retired, isNull);
  });

  test('reads drug ids and archive pages from the atom feed', () {
    const xml = '''
<feed>
  <link href="/openmrs/ws/atomfeed/medication/2"/>
  <entry>
    <content src="/openmrs/ws/rest/v1/tr/drugs/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"/>
  </entry>
</feed>
''';
    expect(
      dghsDrugIdsFromFeed(xml),
      {'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'},
    );
    expect(dghsFeedPages(xml), {2});
  });
}
