import 'dart:convert';

import 'package:docpad/data/cloud/clinic_sync_service.dart';
import 'package:docpad/data/cloud/cloud_synced_key_value_store.dart';
import 'package:docpad/data/local/key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local changes are queued for the device clinic while offline', () async {
    final local = MemoryStore();
    final outbox = MemoryStore();
    await outbox.write('__clinic_binding__', 'clinic-1');
    final sync = ClinicSyncService(
      client: null,
      stores: {'patients': local},
      outbox: outbox,
    );
    final store = CloudSyncedKeyValueStore(
      local: local,
      syncService: sync,
      collection: 'patients',
    );

    await store.write('patient-1', '{"id":"patient-1","name":"Example"}');

    expect(store.read('patient-1'), '{"id":"patient-1","name":"Example"}');
    final pendingKeys = outbox.keys
        .where((key) => key.startsWith('pending:'))
        .toList();
    expect(pendingKeys, hasLength(1));
    final write = jsonDecode(outbox.read(pendingKeys.single)!) as Map;
    expect(write['clinic_id'], 'clinic-1');
    expect(write['is_deleted'], isFalse);
    expect(write['payload']['id'], 'patient-1');

    await store.delete('patient-1');

    expect(store.read('patient-1'), isNull);
    final deletion = jsonDecode(outbox.read(pendingKeys.single)!) as Map;
    expect(deletion['is_deleted'], isTrue);
    expect(deletion['payload'], isNull);
    await sync.dispose();
  });

  test('clearing a collection queues its records before removing local data', () async {
    final local = MemoryStore();
    final outbox = MemoryStore();
    await outbox.write('__clinic_binding__', 'clinic-1');
    await local.write('patient-1', '{"id":"patient-1"}');
    await local.write('patient-2', '{"id":"patient-2"}');
    final sync = ClinicSyncService(
      client: null,
      stores: {'patients': local},
      outbox: outbox,
    );
    final store = CloudSyncedKeyValueStore(
      local: local,
      syncService: sync,
      collection: 'patients',
    );

    await store.clear();

    expect(store.keys, isEmpty);
    final queued = [
      for (final key in outbox.keys)
        if (key != '__clinic_binding__') jsonDecode(outbox.read(key)!) as Map,
    ];
    expect(queued, hasLength(2));
    expect(queued.every((change) => change['is_deleted'] == true), isTrue);
    await sync.dispose();
  });
}
