import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/app_log.dart';
import '../../../data/repository_providers.dart';
import '../models/app_settings.dart';
import '../models/doctor_profile.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).read();

  Future<void> update(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).save(settings);
    state = settings;
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, DoctorProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends Notifier<DoctorProfile> {
  @override
  DoctorProfile build() {
    ref.listen(clinicDataChangesProvider, (_, next) {
      if (next.asData?.value.collection == 'profile') {
        state = ref.read(profileRepositoryProvider).read();
      }
    });
    return ref.read(profileRepositoryProvider).read();
  }

  Future<void> save(DoctorProfile profile) async {
    await ref.read(profileRepositoryProvider).save(profile);
    state = profile;
  }

  Future<void> clear() async {
    await ref.read(profileRepositoryProvider).clear();
    state = DoctorProfile.clinicDefault;
  }
}

Future<void> clearLegacyTrCredentials() async {
  try {
    await const FlutterSecureStorage().delete(key: 'docpad.tr_credentials');
  } catch (error) {
    AppLog.error('legacy-tr-credentials', error);
    rethrow;
  }
}

final stringsProvider = Provider<AppStrings>((ref) {
  final code = ref.watch(
    settingsProvider.select((value) => value.languageCode),
  );
  return AppStrings(code);
});
