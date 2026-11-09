/// Runtime configuration. The catalog base URL can be overridden in Settings.
class AppConfig {
  /// DGHS Shared Health Record terminology registry.
  /// https://en.info.shr.dghs.gov.bd/technical-support/medication-api/
  static const defaultMedexBaseUrl = String.fromEnvironment(
    'MEDEX_BASE_URL',
    defaultValue: 'https://tr.shrlive.dghs.gov.bd',
  );

  static const previousLocalCatalog = 'http://127.0.0.1:3000';

  static String normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Accepts only absolute http(s) URLs so the catalog client cannot be
  /// pointed at an empty or relative path by accident.
  static bool isValidBaseUrl(String raw) {
    final uri = Uri.tryParse(normalizeBaseUrl(raw));
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}
