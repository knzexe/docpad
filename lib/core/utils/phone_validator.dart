/// Accepts international numbers without assuming one country's pattern.
/// Allows an optional leading +, digits, spaces, hyphens, and parentheses.
/// Requires 6 to 15 digits, which covers E.164 length without a country code.
bool isValidPhone(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return false;
  if (!RegExp(r'^\+?[0-9\s().-]+$').hasMatch(value)) return false;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 6 && digits.length <= 15;
}
