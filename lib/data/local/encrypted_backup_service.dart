import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:hive/hive.dart';

import '../../core/utils/app_log.dart';
import 'key_value_store.dart';

class EncryptedBackupException implements Exception {
  const EncryptedBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EncryptedBackupContents {
  EncryptedBackupContents._(
    Map<String, Map<String, String>> collections,
    this.createdAt,
  ) : _collections = Map.unmodifiable({
        for (final entry in collections.entries)
          entry.key: Map<String, String>.unmodifiable(entry.value),
      });

  final Map<String, Map<String, String>> _collections;
  final DateTime createdAt;

  int get recordCount => _collections.entries
      .where((entry) => entry.key != 'profile')
      .fold(0, (total, entry) => total + entry.value.length);
}

class EncryptedBackupService {
  EncryptedBackupService({required Map<String, KeyValueStore> stores})
    : _stores = Map.unmodifiable(stores) {
    if (_stores.keys.toSet().difference(_collections.toSet()).isNotEmpty ||
        _collections.any((collection) => !_stores.containsKey(collection))) {
      throw ArgumentError.value(stores.keys, 'stores');
    }
  }

  static const minimumPasswordLength = 12;
  static const maxBackupBytes = 128 * 1024 * 1024;
  static const _format = 'docpad-encrypted-backup';
  static const _version = 1;
  static const _iterations = 210000;
  static const List<String> _collections = [
    'profile',
    'prescriptions',
    'patients',
    'advice',
    'medicines',
  ];

  static final _cipher = AesGcm.with256bits();
  static final _keyDerivation = Pbkdf2.hmacSha256(
    iterations: _iterations,
    bits: 256,
  );
  static final _random = Random.secure();

  final Map<String, KeyValueStore> _stores;

  Future<Uint8List> createBackup(String password) async {
    _validateNewPassword(password);
    late final Map<String, Map<String, String>> collections;
    try {
      collections = _snapshot();
    } on FormatException {
      throw const EncryptedBackupException(
        'Local records could not be validated. No backup was created.',
      );
    }

    final cleartext = utf8.encode(
      jsonEncode({
        'schema_version': _version,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'collections': collections,
      }),
    );
    if (cleartext.length > maxBackupBytes) {
      throw const EncryptedBackupException(
        'The backup is too large to export.',
      );
    }

    final salt = _secureRandomBytes(16);
    final nonce = _secureRandomBytes(_cipher.nonceLength);
    final key = await _deriveKey(password, salt);
    final encrypted = await _cipher.encrypt(
      cleartext,
      secretKey: key,
      nonce: nonce,
    );
    final envelope = utf8.encode(
      jsonEncode({
        'format': _format,
        'version': _version,
        'cipher': 'AES-256-GCM',
        'kdf': 'PBKDF2-HMAC-SHA256',
        'iterations': _iterations,
        'salt': base64Url.encode(salt),
        'nonce': base64Url.encode(nonce),
        'mac': base64Url.encode(encrypted.mac.bytes),
        'ciphertext': base64Url.encode(encrypted.cipherText),
      }),
    );
    if (envelope.length > maxBackupBytes) {
      throw const EncryptedBackupException(
        'The backup is too large to export.',
      );
    }
    return Uint8List.fromList(envelope);
  }

  Future<EncryptedBackupContents> decryptBackup(
    Uint8List bytes,
    String password,
  ) async {
    if (bytes.isEmpty || bytes.length > maxBackupBytes) {
      throw const EncryptedBackupException(
        'The selected backup file is empty or too large.',
      );
    }

    late final Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException('envelope');
      envelope = Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const EncryptedBackupException(
        'This is not a valid DocPad backup file.',
      );
    } on TypeError {
      throw const EncryptedBackupException(
        'This is not a valid DocPad backup file.',
      );
    }

    if (envelope['format'] != _format ||
        envelope['version'] != _version ||
        envelope['cipher'] != 'AES-256-GCM' ||
        envelope['kdf'] != 'PBKDF2-HMAC-SHA256' ||
        envelope['iterations'] != _iterations) {
      throw const EncryptedBackupException(
        'This backup format is not supported by this app version.',
      );
    }

    final salt = _decodeBytes(envelope['salt'], expectedLength: 16);
    final nonce = _decodeBytes(
      envelope['nonce'],
      expectedLength: _cipher.nonceLength,
    );
    final mac = _decodeBytes(
      envelope['mac'],
      expectedLength: _cipher.macAlgorithm.macLength,
    );
    final ciphertext = _decodeBytes(
      envelope['ciphertext'],
      maximumLength: maxBackupBytes,
    );
    if (ciphertext.isEmpty) {
      throw const EncryptedBackupException(
        'This is not a valid DocPad backup file.',
      );
    }

    final key = await _deriveKey(password, salt);
    late final List<int> cleartext;
    try {
      cleartext = await _cipher.decrypt(
        SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
      );
    } on SecretBoxAuthenticationError {
      throw const EncryptedBackupException(
        'The password is incorrect or the backup file is damaged.',
      );
    }
    return _parseContents(cleartext);
  }

  Future<void> restoreLocalData(EncryptedBackupContents backup) async {
    late final Map<String, Map<String, String>> original;
    try {
      original = _snapshot();
    } on FormatException {
      throw const EncryptedBackupException(
        'Existing local records could not be validated. Restore was stopped.',
      );
    }

    try {
      await _replaceStores(backup._collections);
    } on HiveError catch (error) {
      AppLog.error('encrypted-backup-restore', error);
      await _rollbackAfterFailure(original);
    }
  }

  Map<String, Map<String, String>> _snapshot() {
    return {
      for (final collection in _collections)
        collection: {
          for (final key in _stores[collection]!.keys)
            key: _readValidatedRecord(collection, key),
        },
    };
  }

  String _readValidatedRecord(String collection, String key) {
    final value = _stores[collection]!.read(key);
    if (value == null) {
      throw const FormatException('missing record');
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map) throw const FormatException('record');
    return value;
  }

  EncryptedBackupContents _parseContents(List<int> cleartext) {
    late final Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(utf8.decode(cleartext));
      if (decoded is! Map) throw const FormatException('payload');
      payload = Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const EncryptedBackupException(
        'The backup contents are invalid or damaged.',
      );
    } on TypeError {
      throw const EncryptedBackupException(
        'The backup contents are invalid or damaged.',
      );
    }

    final createdAtValue = payload['created_at'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;
    final rawCollections = payload['collections'];
    if (payload['schema_version'] != _version ||
        createdAt == null ||
        rawCollections is! Map ||
        rawCollections.length != _collections.length) {
      throw const EncryptedBackupException(
        'The backup contents are invalid or damaged.',
      );
    }

    final collections = <String, Map<String, String>>{};
    for (final name in _collections) {
      final rawRecords = rawCollections[name];
      if (rawRecords is! Map) {
        throw const EncryptedBackupException(
          'The backup contents are invalid or damaged.',
        );
      }
      final records = <String, String>{};
      for (final entry in rawRecords.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String ||
            key.isEmpty ||
            value is! String ||
            !_isJsonRecord(value)) {
          throw const EncryptedBackupException(
            'The backup contents are invalid or damaged.',
          );
        }
        records[key] = value;
      }
      collections[name] = records;
    }

    return EncryptedBackupContents._(collections, createdAt.toUtc());
  }

  bool _isJsonRecord(String value) {
    try {
      return jsonDecode(value) is Map;
    } on FormatException {
      return false;
    }
  }

  List<int> _decodeBytes(
    Object? value, {
    int? expectedLength,
    int? maximumLength,
  }) {
    if (value is! String) {
      throw const EncryptedBackupException(
        'The backup contents are invalid or damaged.',
      );
    }
    late final List<int> decoded;
    try {
      decoded = base64Url.decode(value);
    } on FormatException {
      throw const EncryptedBackupException(
        'The backup contents are invalid or damaged.',
      );
    }
    if ((expectedLength != null && decoded.length != expectedLength) ||
        (maximumLength != null && decoded.length > maximumLength)) {
      throw const EncryptedBackupException(
        'The backup contents are invalid or damaged.',
      );
    }
    return decoded;
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) {
    return _keyDerivation.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  Future<Never> _rollbackAfterFailure(
    Map<String, Map<String, String>> original,
  ) async {
    try {
      await _replaceStores(original);
    } on HiveError catch (error) {
      AppLog.error('encrypted-backup-rollback', error);
      throw const EncryptedBackupException(
        'Restore failed and automatic recovery was incomplete. Keep the app open and contact support.',
      );
    }
    throw const EncryptedBackupException(
      'Restore failed. The original local records were restored.',
    );
  }

  Future<void> _replaceStores(
    Map<String, Map<String, String>> collections,
  ) async {
    for (final collection in _collections) {
      await _stores[collection]!.clear();
      for (final entry in collections[collection]!.entries) {
        await _stores[collection]!.write(entry.key, entry.value);
      }
    }
  }

  Uint8List _secureRandomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }

  void _validateNewPassword(String password) {
    if (password.runes.length < minimumPasswordLength) {
      throw const EncryptedBackupException(
        'Use a backup password with at least 12 characters.',
      );
    }
  }
}
