import 'dart:convert';

import '../../core/errors/app_exception.dart';
import '../../core/utils/app_log.dart';
import 'key_value_store.dart';

Map<String, dynamic> decodeRecord(String? raw, String operation) {
  if (raw == null) {
    throw const AppException(
      'A saved record could not be read. It was not deleted.',
      code: 'storage',
    );
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('record');
    }
    return Map<String, dynamic>.from(decoded);
  } catch (error) {
    if (error is AppException) rethrow;
    AppLog.error(operation, error);
    throw const AppException(
      'A saved record could not be read. It was not deleted.',
      code: 'storage',
    );
  }
}

List<Map<String, dynamic>> readAllRecords(
  KeyValueStore store,
  String operation,
) {
  return [
    for (final key in store.keys) decodeRecord(store.read(key), operation),
  ];
}
