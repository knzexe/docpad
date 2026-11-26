import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.languageCode,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      themeMode: ThemeMode.light,
      languageCode: 'en',
    );
  }

  final ThemeMode themeMode;
  final String languageCode;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
