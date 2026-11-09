import 'package:hive/hive.dart';

abstract class KeyValueStore {
  List<String> get keys;
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  List<String> get keys => _values.keys.toList();

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }
}

class HiveBoxStore implements KeyValueStore {
  HiveBoxStore(this._box);

  final Box<String> _box;

  @override
  List<String> get keys => [
    for (final key in _box.keys)
      if (key is String) key,
  ];

  @override
  String? read(String key) => _box.get(key);

  @override
  Future<void> write(String key, String value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> clear() => _box.clear();
}
