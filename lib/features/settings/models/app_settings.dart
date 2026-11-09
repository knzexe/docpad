import 'package:flutter/material.dart';

import '../../../core/constants/app_config.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.languageCode,
    required this.medexBaseUrl,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      themeMode: ThemeMode.system,
      languageCode: 'en',
      medexBaseUrl: AppConfig.normalizeBaseUrl(AppConfig.defaultMedexBaseUrl),
    );
  }

  final ThemeMode themeMode;
  final String languageCode;
  final String medexBaseUrl;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    String? medexBaseUrl,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      medexBaseUrl: medexBaseUrl ?? this.medexBaseUrl,
    );
  }
}
