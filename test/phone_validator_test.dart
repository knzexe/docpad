import 'package:docpad/core/utils/phone_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts international numbers without assuming one country', () {
    expect(isValidPhone('+880 1711 223344'), isTrue);
    expect(isValidPhone('+1 (202) 555-0100'), isTrue);
    expect(isValidPhone('01711-223344'), isTrue);
  });

  test('rejects letters and numbers outside 6 to 15 digits', () {
    expect(isValidPhone(''), isFalse);
    expect(isValidPhone('abc'), isFalse);
    expect(isValidPhone('12345'), isFalse);
    expect(isValidPhone('+1234567890123456'), isFalse);
    expect(isValidPhone('12345ext'), isFalse);
  });
}
