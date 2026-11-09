import 'package:flutter/foundation.dart';

/// Logs the operation and error type only. Patient names, phone numbers,
/// clinical notes, and catalog payloads are never written here.
class AppLog {
  static void error(String operation, Object error) {
    debugPrint('DocPad error during $operation (${error.runtimeType})');
  }
}
