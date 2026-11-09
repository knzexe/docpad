import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_config.dart';
import '../models/app_settings.dart';

abstract class SettingsRepository {
  AppSettings read();
  Future<void> save(AppSettings settings);
}

class MemorySettingsRepository implements SettingsRepository {
  MemorySettingsRepository([AppSettings? initial])
    : _settings = initial ?? AppSettings.defaults();

  AppSettings _settings;

  @override
  AppSettings read() => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}

class PreferencesSettingsRepository implements SettingsRepository {
  PreferencesSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  AppSettings read() {
    final theme = _prefs.getString('theme_mode') ?? 'system';
    final language = _prefs.getString('language_code') ?? 'en';
    final stored = _prefs.getString('medex_base_url');
    final url = stored == null ||
            AppConfig.normalizeBaseUrl(stored) == AppConfig.previousLocalCatalog
        ? AppConfig.defaultMedexBaseUrl
        : stored;
    return AppSettings(
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      languageCode: language == 'bn' ? 'bn' : 'en',
      medexBaseUrl: AppConfig.normalizeBaseUrl(url),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final theme = switch (settings.themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString('theme_mode', theme);
    await _prefs.setString(
      'language_code',
      settings.languageCode == 'bn' ? 'bn' : 'en',
    );
    await _prefs.setString('medex_base_url', settings.medexBaseUrl);
  }
}
