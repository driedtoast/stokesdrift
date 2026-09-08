import 'package:flutter/material.dart';

/// Surf Daybreak Design System — derived from DESIGN.md
class AppColors {
  static const primary = Color(0xFF0C3340);
  static const secondary = Color(0xFF5A8894);
  static const tertiary = Color(0xFFFF7A5C);
  static const neutral = Color(0xFFDFF1EC);
  static const surface = Color(0xFFF3FAF7);
  static const onPrimary = Color(0xFFFFFFFF);
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF2E7D32);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 32.0;
  static const xl = 48.0;
}

class AppRadius {
  static const sm = 10.0;
  static const md = 18.0;
  static const lg = 28.0;
}

class AppTypography {
  // Display — Recoleta fallback to Serif
  static const display = TextStyle(
    fontFamily: 'Serif',
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.72,
    height: 1.1,
  );

  // H1 — Fraunces fallback to Serif
  static const h1 = TextStyle(
    fontFamily: 'Serif',
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  // H2
  static const h2 = TextStyle(
    fontFamily: 'Serif',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // Body — Inter fallback to system sans
  static const body = TextStyle(
    fontFamily: 'Sans',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  // Label
  static const label = TextStyle(
    fontFamily: 'Sans',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    height: 1.4,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.tertiary,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.neutral,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.neutral,
          foregroundColor: AppColors.primary,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Serif',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.tertiary,
          unselectedItemColor: AppColors.secondary,
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.tertiary,
          foregroundColor: AppColors.onPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.neutral,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.tertiary, width: 1.5),
          ),
          hintStyle: const TextStyle(color: AppColors.secondary),
        ),
        textTheme: const TextTheme(),
      );
}