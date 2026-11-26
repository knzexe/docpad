import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureSupabaseLocalStorage extends LocalStorage {
  const SecureSupabaseLocalStorage({
    this._storage = const FlutterSecureStorage(),
  });

  static const _sessionKey = 'docpad.supabase_session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return await _storage.read(key: _sessionKey) != null;
  }

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() {
    return _storage.delete(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return _storage.write(key: _sessionKey, value: persistSessionString);
  }
}
