import 'dart:convert';

import 'package:docpad/data/local/encrypted_backup_service.dart';
import 'package:docpad/data/local/key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const password = 'correct horse battery staple';

  test('encrypted backup replaces local records when restored', () async {
    final stores = _createStores();
    await stores['profile']!.write(
      'doctor',
      jsonEncode({'name': 'Clinic doctor'}),
    );
    await stores['patients']!.write(
      'patient-1',
      jsonEncode({'name': 'Sensitive patient name'}),
    );
    await stores['prescriptions']!.write(
      'prescription-1',
      jsonEncode({'id': 'prescription-1'}),
    );

    final service = EncryptedBackupService(stores: stores);
    final backup = await service.createBackup(password);

    expect(utf8.decode(backup), isNot(contains('Sensitive patient name')));

    await stores['patients']!.clear();
    await stores['patients']!.write(
      'local-only',
      jsonEncode({'name': 'Local record'}),
    );

    final contents = await service.decryptBackup(backup, password);
    expect(contents.recordCount, 2);
    await service.restoreLocalData(contents);

    expect(
      stores['profile']!.read('doctor'),
      jsonEncode({'name': 'Clinic doctor'}),
    );
    expect(stores['patients']!.keys, ['patient-1']);
    expect(
      stores['patients']!.read('patient-1'),
      jsonEncode({'name': 'Sensitive patient name'}),
    );
    expect(stores['prescriptions']!.keys, ['prescription-1']);
  });

  test('rejects short passwords and incorrect restore passwords', () async {
    final service = EncryptedBackupService(stores: _createStores());

    await expectLater(
      service.createBackup('short'),
      throwsA(isA<EncryptedBackupException>()),
    );

    final backup = await service.createBackup(password);
    await expectLater(
      service.decryptBackup(backup, 'another incorrect password'),
      throwsA(isA<EncryptedBackupException>()),
    );
  });
}

Map<String, MemoryStore> _createStores() => {
  'profile': MemoryStore(),
  'prescriptions': MemoryStore(),
  'patients': MemoryStore(),
  'advice': MemoryStore(),
  'medicines': MemoryStore(),
};
