String textField(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return '';
  if (value is String) return value;
  throw FormatException('Expected text for $key');
}

String? optionalText(dynamic value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('Expected text');
  }
  return value.trim().isEmpty ? null : value;
}

DateTime requiredDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Expected a date for $key');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('Unreadable date for $key');
  }
  return parsed;
}

DateTime? optionalDate(dynamic value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('Expected a date');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw const FormatException('Unreadable date');
  }
  return parsed;
}

int? optionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw const FormatException('Expected a number');
}
