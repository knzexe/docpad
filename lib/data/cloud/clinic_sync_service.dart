import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_log.dart';
import '../local/key_value_store.dart';

enum ClinicSyncPhase {
  disabled,
  signedOut,
  connecting,
  syncing,
  synced,
  differentClinic,
  error,
}

class ClinicSyncStatus {
  const ClinicSyncStatus({
    required this.phase,
    required this.pendingChanges,
    this.email,
  });

  final ClinicSyncPhase phase;
  final int pendingChanges;
  final String? email;
}

class ClinicDataChange {
  const ClinicDataChange(this.collection);

  final String collection;
}

class ClinicSyncService {
  factory ClinicSyncService({
    required SupabaseClient? client,
    required Map<String, KeyValueStore> stores,
    required KeyValueStore? outbox,
    String? configurationError,
  }) {
    return ClinicSyncService._(
      client: client,
      stores: stores,
      outbox: outbox,
      configurationError: configurationError,
    );
  }

  ClinicSyncService._({
    required this._client,
    required this._stores,
    required this._outbox,
    required this._configurationError,
  }) {
    _status = ClinicSyncStatus(
      phase: _configurationError != null
          ? ClinicSyncPhase.error
          : _client == null
          ? ClinicSyncPhase.disabled
          : ClinicSyncPhase.signedOut,
      pendingChanges: _pendingCount,
    );
  }

  factory ClinicSyncService.unconfigured() {
    return ClinicSyncService(client: null, stores: const {}, outbox: null);
  }

  static const _table = 'app_records';
  static const _membershipTable = 'clinic_members';
  static const _bindingKey = '__clinic_binding__';
  static const _collections = {
    'profile',
    'prescriptions',
    'patients',
    'advice',
    'medicines',
  };

  final SupabaseClient? _client;
  final Map<String, KeyValueStore> _stores;
  final KeyValueStore? _outbox;
  final String? _configurationError;
  final StreamController<ClinicSyncStatus> _statusController =
      StreamController<ClinicSyncStatus>.broadcast();
  final StreamController<ClinicDataChange> _changeController =
      StreamController<ClinicDataChange>.broadcast();

  late ClinicSyncStatus _status;
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String? _userId;
  String? _clinicId;
  bool _snapshotLoaded = false;
  bool _realtimeReady = false;
  Future<void> _authQueue = Future<void>.value();
  bool _flushing = false;
  bool _flushRequested = false;

  bool get isConfigured => _client != null;
  String? get configurationError => _configurationError;
  String? get currentEmail => _client?.auth.currentUser?.email;
  ClinicSyncStatus get status => _status;
  Stream<ClinicSyncStatus> get statusChanges => _statusController.stream;
  Stream<ClinicDataChange> get changes => _changeController.stream;

  Future<void> initialize() async {
    final client = _client;
    if (client == null) {
      _refreshPendingStatus();
      return;
    }
    _refreshPendingStatus();

    _authSubscription = client.auth.onAuthStateChange.listen(
      (state) => _scheduleAuthState(state.session?.user.id),
      onError: (Object error, StackTrace stackTrace) {
        AppLog.error('cloud-auth-state', error);
        _setStatus(ClinicSyncPhase.error);
      },
    );

    try {
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
        results,
      ) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          final userId = _client?.auth.currentUser?.id;
          if (userId != null) {
            unawaited(_scheduleAuthState(userId));
          } else {
            unawaited(_flushPending());
          }
        }
      });
    } catch (error) {
      AppLog.error('cloud-connectivity-listener', error);
    }

    final user = client.auth.currentUser;
    if (user != null) _scheduleAuthState(user.id);
  }

  Future<void> signIn({required String email, required String password}) async {
    final client = _requireClient();
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<bool> signUp({required String email, required String password}) async {
    final client = _requireClient();
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    return response.session != null;
  }

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
    await _scheduleAuthState(null);
  }

  Future<void> syncNow() async {
    final client = _requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before syncing workspace records.');
    }
    await _scheduleAuthState(user.id);
    if (_clinicId != null) await _flushPending();
  }

  Future<void> recordLocalWrite(
    String collection,
    String id,
    String value,
  ) async {
    if (!_collections.contains(collection)) return;
    await _queueMutation(
      collection: collection,
      id: id,
      payload: jsonDecode(value),
      deleted: false,
    );
  }

  Future<void> recordLocalDelete(String collection, String id) async {
    if (!_collections.contains(collection)) return;
    await _queueMutation(
      collection: collection,
      id: id,
      payload: null,
      deleted: true,
    );
  }

  Future<void> recordLocalDeletes(
    String collection,
    Iterable<String> ids,
  ) async {
    if (!_collections.contains(collection)) return;
    final outbox = _outbox;
    if (outbox == null) return;
    final clinicId = _clinicId ?? outbox.read(_bindingKey);
    if (clinicId == null) return;
    for (final id in ids) {
      await outbox.write(
        _outboxKey(collection, id),
        jsonEncode({
          'clinic_id': clinicId,
          'collection': collection,
          'record_id': id,
          'payload': null,
          'is_deleted': true,
        }),
      );
    }
    _refreshPendingStatus();
    if (_clinicId == clinicId) unawaited(_flushPending());
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    await _removeChannel();
    await _statusController.close();
    await _changeController.close();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        _configurationError ??
            'Supabase is not configured for this application.',
      );
    }
    return client;
  }

  Future<void> _scheduleAuthState(String? userId) {
    _authQueue = _authQueue.then((_) async {
      try {
        await _handleAuthState(userId);
      } catch (error) {
        AppLog.error('cloud-auth-state', error);
        _setStatus(ClinicSyncPhase.error);
      }
    });
    return _authQueue;
  }

  Future<void> _handleAuthState(String? userId) async {
    if (userId == null) {
      await _disconnect();
      return;
    }
    if (_userId == userId && _clinicId != null) {
      try {
        final clinicId = _clinicId!;
        if (!_realtimeReady) {
          await _removeChannel();
          await _subscribe(clinicId);
        }
        if (!_snapshotLoaded) {
          await _syncSnapshot(clinicId);
          _snapshotLoaded = true;
        }
        await _flushPending();
      } catch (error) {
        AppLog.error('cloud-reconnect', error);
        _setStatus(ClinicSyncPhase.error);
      }
      return;
    }

    await _disconnect();
    _userId = userId;
    _setStatus(ClinicSyncPhase.connecting);

    try {
      final client = _requireClient();
      final outbox = _outbox;
      if (outbox == null) {
        throw StateError('The encrypted sync queue is unavailable.');
      }
      final memberships = await client
          .from(_membershipTable)
          .select('clinic_id')
          .eq('user_id', userId)
          .limit(2);
      if (client.auth.currentUser?.id != userId) return;
      final boundClinic = outbox.read(_bindingKey);
      if (memberships.isEmpty && boundClinic != null) {
        _setStatus(ClinicSyncPhase.differentClinic);
        return;
      }
      final clinicId = memberships.isEmpty
          ? await _createPersonalClinic(client, userId)
          : _readClinicId(memberships);
      if (client.auth.currentUser?.id != userId) return;
      if (boundClinic != null && boundClinic != clinicId) {
        _setStatus(ClinicSyncPhase.differentClinic);
        return;
      }
      if (boundClinic == null) await outbox.write(_bindingKey, clinicId);
      _clinicId = clinicId;
      _snapshotLoaded = false;
      _realtimeReady = false;

      await _subscribe(clinicId);
      if (client.auth.currentUser?.id != userId) return;
      await _syncSnapshot(clinicId);
      _snapshotLoaded = true;
      await _flushPending();
    } catch (error) {
      AppLog.error('cloud-connect', error);
      _setStatus(ClinicSyncPhase.error);
    }
  }

  Future<String> _createPersonalClinic(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      await client.from('clinics').insert({'name': 'Personal workspace'});
    } catch (error) {
      final memberships = await client
          .from(_membershipTable)
          .select('clinic_id')
          .eq('user_id', userId)
          .limit(2);
      if (client.auth.currentUser?.id == userId && memberships.isNotEmpty) {
        return _readClinicId(memberships);
      }
      rethrow;
    }

    if (client.auth.currentUser?.id != userId) {
      throw StateError('The signed-in account changed during setup.');
    }
    final memberships = await client
        .from(_membershipTable)
        .select('clinic_id')
        .eq('user_id', userId)
        .limit(2);
    return _readClinicId(memberships);
  }

  String _readClinicId(List<dynamic> memberships) {
    if (memberships.length != 1) {
      throw const FormatException(
        'This account must belong to exactly one workspace.',
      );
    }
    final clinicId = memberships.single['clinic_id'];
    if (clinicId is! String || clinicId.isEmpty) {
      throw const FormatException('Workspace membership is invalid.');
    }
    return clinicId;
  }

  Future<void> _subscribe(String clinicId) async {
    final client = _requireClient();
    final ready = Completer<void>();
    _channel = client
        .channel('clinic-$clinicId-app-records')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'clinic_id',
            value: clinicId,
          ),
          callback: (payload) => unawaited(_applyRealtimeChange(payload)),
        )
        .subscribe((status, error) {
          if (_clinicId != clinicId || _userId == null) return;
          if (status == RealtimeSubscribeStatus.subscribed) {
            _realtimeReady = true;
            if (!ready.isCompleted) ready.complete();
            if (_status.phase == ClinicSyncPhase.error) {
              _setStatus(
                _snapshotLoaded
                    ? ClinicSyncPhase.synced
                    : ClinicSyncPhase.syncing,
              );
            }
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            _realtimeReady = false;
            _snapshotLoaded = false;
            final failure =
                error ?? StateError('Realtime subscription failed.');
            if (!ready.isCompleted) {
              ready.completeError(failure);
            } else {
              AppLog.error('cloud-realtime', failure);
              _setStatus(ClinicSyncPhase.error);
            }
          } else if (status == RealtimeSubscribeStatus.closed) {
            _realtimeReady = false;
            _snapshotLoaded = false;
            _setStatus(ClinicSyncPhase.error);
          }
        });
    await ready.future.timeout(const Duration(seconds: 20));
  }

  Future<void> _syncSnapshot(String clinicId) async {
    final client = _requireClient();
    final outbox = _outbox;
    if (outbox == null) throw StateError('The sync queue is unavailable.');
    final remoteKeys = <String>{};
    var offset = 0;
    const pageSize = 500;

    _setStatus(ClinicSyncPhase.syncing);
    while (true) {
      final page = await client
          .from(_table)
          .select()
          .eq('clinic_id', clinicId)
          .order('collection')
          .order('record_id')
          .range(offset, offset + pageSize - 1);
      for (final row in page) {
        final collection = row['collection'];
        final id = row['record_id'];
        if (collection is! String || id is! String) {
          throw const FormatException('A cloud record has an invalid key.');
        }
        remoteKeys.add(_recordKey(collection, id));
        final store = _stores[collection];
        if (store == null || outbox.read(_outboxKey(collection, id)) != null) {
          continue;
        }
        if (row['is_deleted'] == true) {
          await store.delete(id);
        } else {
          final payload = row['payload'];
          if (payload is! Map) {
            throw const FormatException('A cloud record has invalid data.');
          }
          await store.write(id, jsonEncode(payload));
        }
        _emitChange(collection);
      }
      if (page.length < pageSize) break;
      offset += pageSize;
    }

    for (final entry in _stores.entries) {
      for (final id in entry.value.keys) {
        if (remoteKeys.contains(_recordKey(entry.key, id)) ||
            outbox.read(_outboxKey(entry.key, id)) != null) {
          continue;
        }
        final value = entry.value.read(id);
        if (value != null) {
          await _queueMutation(
            collection: entry.key,
            id: id,
            payload: jsonDecode(value),
            deleted: false,
            flush: false,
          );
        }
      }
    }
  }

  Future<void> _applyRealtimeChange(PostgresChangePayload event) async {
    final record = event.newRecord.isNotEmpty
        ? event.newRecord
        : event.oldRecord;
    final collection = record['collection'];
    final id = record['record_id'];
    if (collection is! String || id is! String) return;
    final store = _stores[collection];
    if (store == null || _outbox?.read(_outboxKey(collection, id)) != null) {
      return;
    }

    try {
      if (event.eventType == PostgresChangeEvent.delete ||
          record['is_deleted'] == true) {
        await store.delete(id);
      } else {
        final payload = record['payload'];
        if (payload is! Map) {
          throw const FormatException('A cloud record has invalid data.');
        }
        await store.write(id, jsonEncode(payload));
      }
      _emitChange(collection);
    } catch (error) {
      AppLog.error('cloud-realtime-apply', error);
      _setStatus(ClinicSyncPhase.error);
    }
  }

  Future<void> _queueMutation({
    required String collection,
    required String id,
    required Object? payload,
    required bool deleted,
    bool flush = true,
  }) async {
    final outbox = _outbox;
    final clinicId = _clinicId ?? outbox?.read(_bindingKey);
    if (outbox == null || clinicId == null) return;
    await outbox.write(
      _outboxKey(collection, id),
      jsonEncode({
        'clinic_id': clinicId,
        'collection': collection,
        'record_id': id,
        'payload': payload,
        'is_deleted': deleted,
      }),
    );
    _refreshPendingStatus();
    _emitChange(collection);
    if (flush && _clinicId == clinicId) unawaited(_flushPending());
  }

  Future<void> _flushPending() async {
    final client = _client;
    final outbox = _outbox;
    final clinicId = _clinicId;
    if (_flushing) {
      _flushRequested = true;
      return;
    }
    if (client == null || outbox == null || clinicId == null) {
      return;
    }
    _flushing = true;
    _flushRequested = false;
    var failed = false;
    try {
      _setStatus(ClinicSyncPhase.syncing);
      for (final key in outbox.keys) {
        if (key == _bindingKey) continue;
        final raw = outbox.read(key);
        if (raw == null) continue;
        final mutation = jsonDecode(raw);
        if (mutation is! Map<String, dynamic>) {
          throw const FormatException('A queued cloud change is invalid.');
        }
        if (mutation['clinic_id'] != clinicId) continue;
        await client.from(_table).upsert({
          'clinic_id': clinicId,
          'collection': mutation['collection'],
          'record_id': mutation['record_id'],
          'payload': mutation['payload'],
          'is_deleted': mutation['is_deleted'],
        }, onConflict: 'clinic_id,collection,record_id');
        if (outbox.read(key) == raw) {
          await outbox.delete(key);
        } else {
          _flushRequested = true;
        }
      }
      _setStatus(ClinicSyncPhase.synced);
    } catch (error) {
      failed = true;
      AppLog.error('cloud-sync', error);
      _setStatus(ClinicSyncPhase.error);
    } finally {
      _flushing = false;
      if (_flushRequested && !failed) {
        _flushRequested = false;
        unawaited(_flushPending());
      }
    }
  }

  Future<void> _disconnect() async {
    _clinicId = null;
    _userId = null;
    _snapshotLoaded = false;
    _realtimeReady = false;
    await _removeChannel();
    if (_client?.auth.currentUser == null) {
      _setStatus(
        _client == null
            ? _configurationError == null
                  ? ClinicSyncPhase.disabled
                  : ClinicSyncPhase.error
            : ClinicSyncPhase.signedOut,
      );
    }
  }

  Future<void> _removeChannel() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) await _client?.removeChannel(channel);
  }

  void _refreshPendingStatus() {
    final pending = _pendingCount;
    if (_client == null) {
      _setStatus(
        _configurationError == null
            ? ClinicSyncPhase.disabled
            : ClinicSyncPhase.error,
      );
    } else if (_clinicId == null && _client.auth.currentUser == null) {
      _setStatus(ClinicSyncPhase.signedOut);
    } else if (_clinicId != null) {
      _setStatus(
        pending == 0 ? ClinicSyncPhase.synced : ClinicSyncPhase.syncing,
      );
    }
  }

  int get _pendingCount {
    final outbox = _outbox;
    if (outbox == null) return 0;
    return outbox.keys.where((key) => key != _bindingKey).length;
  }

  String _outboxKey(String collection, String id) {
    return 'pending:$collection:${base64Url.encode(utf8.encode(id))}';
  }

  String _recordKey(String collection, String id) => '$collection\u0000$id';

  void _emitChange(String collection) {
    if (!_changeController.isClosed) {
      _changeController.add(ClinicDataChange(collection));
    }
  }

  void _setStatus(ClinicSyncPhase phase) {
    _status = ClinicSyncStatus(
      phase: phase,
      pendingChanges: _pendingCount,
      email: currentEmail,
    );
    if (!_statusController.isClosed) _statusController.add(_status);
  }
}
