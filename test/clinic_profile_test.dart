import 'package:docpad/data/local/key_value_store.dart';
import 'package:docpad/features/settings/models/doctor_profile.dart';
import 'package:docpad/features/settings/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'new profiles use the supplied clinic defaults without replacing edits',
    () async {
      final repository = ProfileRepository(MemoryStore());

      final profile = repository.read();
      expect(profile.clinicName, 'Raifa Medicine & SS Health Care');
      expect(profile.name, 'Dr. Morsalin Bin Sakhawat');
      expect(profile.contact, '01682897670');

      await repository.save(DoctorProfile.empty);
      expect(repository.read().clinicName, 'Raifa Medicine & SS Health Care');

      await repository.save(
        profile.copyWith(clinicName: 'Custom Clinic', contact: '12345678'),
      );
      expect(repository.read().clinicName, 'Custom Clinic');
      expect(repository.read().contact, '12345678');
    },
  );
}
