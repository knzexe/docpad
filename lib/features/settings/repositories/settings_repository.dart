import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final language = _prefs.getString('language_code') ?? 'en';
    return AppSettings(
      themeMode: ThemeMode.light,
      languageCode: language == 'bn' ? 'bn' : 'en',
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString('theme_mode', 'light');
    await _prefs.setString(
      'language_code',
      settings.languageCode == 'bn' ? 'bn' : 'en',
    );
  }
}
