import '../../../core/errors/app_exception.dart';
import '../models/medex_brand.dart';
import 'medex_parser.dart';

const dghsProviderName = 'DGHS Terminology Registry';

final _drugId = RegExp(
  r'/openmrs/ws/rest/v1/tr/drugs/([0-9a-fA-F-]{32,})',
);
final _feedPage = RegExp(r'/openmrs/ws/atomfeed/medication/(\d+)');

/// Drug UUIDs published in a medication atom feed page.
Set<String> dghsDrugIdsFromFeed(String xml) {
  return {for (final match in _drugId.allMatches(xml)) match.group(1)!};
}

/// Archive page numbers linked from a medication feed document.
Set<int> dghsFeedPages(String xml) {
  return {
    for (final match in _feedPage.allMatches(xml)) int.parse(match.group(1)!),
  };
}

/// Maps one DGHS medication record from
/// `GET /openmrs/ws/rest/v1/tr/drugs/{identifier}`.
///
/// Retired records return null. Missing fields stay null.
MedExBrand? dghsBrandFromMedication(dynamic body) {
  final map = asJsonMap(body);
  final id = map['id'];
  final name = map['name'];
  if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
    throw const AppException(
      'A terminology record was missing its id or name.',
      code: 'invalid_response',
    );
  }
  String? strength;
  var retired = false;
  final extensions = map['extension'];
  if (extensions is List) {
    for (final item in extensions) {
      if (item is! Map) continue;
      final url = item['url']?.toString() ?? '';
      final value = item['valueString'];
      if (value is! String) continue;
      if (url.contains('MedicationStrength')) strength = _blank(value);
      if (url.contains('MedicationRetired') && value.trim() == 'true') {
        retired = true;
      }
    }
  }
  if (retired) return null;
  return MedExBrand(
    id: id,
    brandName: name.trim(),
    genericName: _firstDisplay(map['code']),
    strength: strength,
    dosageForm: _firstDisplay(
      map['product'] is Map ? (map['product'] as Map)['form'] : null,
    ),
    sourceKind: 'live',
    sourceLabel: dghsProviderName,
  );
}

String? _firstDisplay(dynamic node) {
  if (node is! Map) return null;
  final coding = node['coding'];
  if (coding is! List) return null;
  for (final item in coding) {
    if (item is! Map) continue;
    final display = item['display'];
    if (display is String && display.trim().isNotEmpty) return display.trim();
  }
  return null;
}

String? _blank(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
