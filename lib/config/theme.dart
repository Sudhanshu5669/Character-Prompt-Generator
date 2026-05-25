import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Colors.white;
  static const Color secondary = Color(0xFFE0E0E0);
  static const Color tertiary = Color(0xFF8E8E93);
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF121212);
  static const Color cardColor = Color(0xFF161616);
  static const Color error = Color(0xFFCF6679);
  static const Color onPrimary = Colors.black;
  static const Color onBackground = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textDisabled = Colors.white38;
  static const Color borderSubtle = Color(0xFF2C2C2C);
}

class AppDecorations {
  AppDecorations._();

  static BoxDecoration get glassmorphicCard => BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      );

  static BoxDecoration get gradientCard => BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      );

  static BoxDecoration get accentGradient => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      );
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Inter',
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.tertiary,
    surface: AppColors.surface,
    error: AppColors.error,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.white,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: AppColors.background,
  canvasColor: AppColors.background,
  cardColor: AppColors.cardColor,
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFamily: 'Inter',
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFamily: 'Inter',
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.white70,
      fontFamily: 'Inter',
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.white70,
      fontFamily: 'Inter',
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.borderSubtle, width: 1),
    ),
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 2,
    shape: CircleBorder(),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderSubtle),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    hintStyle: const TextStyle(
      color: Colors.white38,
      fontFamily: 'Inter',
    ),
    labelStyle: const TextStyle(
      color: Colors.white70,
      fontFamily: 'Inter',
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.background,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white38,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: 'Inter',
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surface,
    selectedColor: Colors.white24,
    disabledColor: AppColors.surface,
    labelStyle: const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontFamily: 'Inter',
    ),
    secondaryLabelStyle: const TextStyle(
      color: Colors.white70,
      fontSize: 13,
      fontFamily: 'Inter',
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    side: const BorderSide(color: AppColors.borderSubtle),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.surface,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontFamily: 'Inter',
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.borderSubtle),
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 2,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.borderSubtle),
    ),
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
    ),
    contentTextStyle: const TextStyle(
      fontSize: 14,
      color: Colors.white70,
      fontFamily: 'Inter',
    ),
    elevation: 4,
  ),
);
