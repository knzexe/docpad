import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/app_log.dart';
import '../../../data/repository_providers.dart';
import '../models/app_settings.dart';
import '../models/doctor_profile.dart';
import '../models/tr_credentials.dart';

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
  DoctorProfile build() => ref.read(profileRepositoryProvider).read();

  Future<void> save(DoctorProfile profile) async {
    await ref.read(profileRepositoryProvider).save(profile);
    state = profile;
  }

  Future<void> clear() async {
    await ref.read(profileRepositoryProvider).clear();
    state = DoctorProfile.empty;
  }
}

final trCredentialsProvider =
    AsyncNotifierProvider<TrCredentialsNotifier, TrCredentials>(
      TrCredentialsNotifier.new,
    );

class TrCredentialsNotifier extends AsyncNotifier<TrCredentials> {
  static const _key = 'docpad.tr_credentials';

  @override
  Future<TrCredentials> build() => _read();

  Future<void> save(TrCredentials value) async {
    const storage = FlutterSecureStorage();
    final username = value.username.trim();
    final next = TrCredentials(username: username, password: value.password);
    try {
      if (username.isEmpty && value.password.isEmpty) {
        await storage.delete(key: _key);
      } else {
        await storage.write(
          key: _key,
          value: jsonEncode({
            'username': username,
            'password': value.password,
          }),
        );
      }
    } on PlatformException catch (error) {
      AppLog.error('tr-credentials', error);
      throw const AppException(
        'The secure store could not save the terminology login.',
        code: 'secure_store',
      );
    } catch (error) {
      AppLog.error('tr-credentials', error);
      throw const AppException(
        'The secure store could not save the terminology login.',
        code: 'secure_store',
      );
    }
    state = AsyncData(next);
  }

  Future<TrCredentials> _read() async {
    try {
      final raw = await const FlutterSecureStorage().read(key: _key);
      if (raw == null || raw.isEmpty) return const TrCredentials();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const TrCredentials();
      return TrCredentials(
        username: decoded['username'] is String
            ? decoded['username'] as String
            : '',
        password: decoded['password'] is String
            ? decoded['password'] as String
            : '',
      );
    } catch (error) {
      AppLog.error('tr-credentials', error);
      return const TrCredentials();
    }
  }
}

final stringsProvider = Provider<AppStrings>((ref) {
  final code = ref.watch(
    settingsProvider.select((value) => value.languageCode),
  );
  return AppStrings(code);
});
