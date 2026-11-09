import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.darkPrimary : AppColors.primary,
      onPrimary: isDark ? AppColors.darkBackground : Colors.white,
      secondary: isDark ? AppColors.darkPrimary : AppColors.primary,
      onSecondary: isDark ? AppColors.darkBackground : Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? AppColors.darkText : AppColors.textPrimary,
    );
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.background,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['NotoSansBengali', 'NotoSans'],
      dividerColor: border,
      splashFactory: InkRipple.splashFactory,
    );

    final text = base.textTheme
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
          fontFamily: 'Inter',
        )
        .copyWith(
          headlineMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.2,
            color: scheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: scheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            height: 1.45,
            color: scheme.onSurface,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.45,
            color: scheme.onSurface,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            height: 1.4,
            color: secondaryText,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        );

    final radius = BorderRadius.circular(12);
    final outline = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: border),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: text.bodyMedium?.copyWith(color: secondaryText),
        hintStyle: text.bodyMedium?.copyWith(color: secondaryText),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
          foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: isDark
            ? const Color(0xFF24332F)
            : AppColors.primaryLight,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: secondaryText),
        selectedLabelTextStyle: text.bodySmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: text.bodySmall,
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkText : AppColors.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isDark ? AppColors.darkBackground : Colors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
