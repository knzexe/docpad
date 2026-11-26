import '../local/key_value_store.dart';
import 'clinic_sync_service.dart';

class CloudSyncedKeyValueStore implements KeyValueStore {
  const CloudSyncedKeyValueStore({
    required this._local,
    required this._syncService,
    required this._collection,
  });

  final KeyValueStore _local;
  final ClinicSyncService _syncService;
  final String _collection;

  @override
  List<String> get keys => _local.keys;

  @override
  String? read(String key) => _local.read(key);

  @override
  Future<void> write(String key, String value) async {
    await _local.write(key, value);
    await _syncService.recordLocalWrite(_collection, key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _syncService.recordLocalDelete(_collection, key);
    await _local.delete(key);
  }

  @override
  Future<void> clear() async {
    await _syncService.recordLocalDeletes(_collection, _local.keys);
    await _local.clear();
  }
}
