import 'package:flutter/material.dart';

// First, let's define our custom colors as constants for easy reference.
class AppColors {
  static const Color etherealBlue = Color(0xFFA0D2EB);
  static const Color gentlePink = Color(0xFFFFB6C1);
  static const Color wispLavender = Color(0xFFE6E6FA);
  static const Color darkSlate = Color(0xFF2F4F4F);
  static const Color coolGray = Color(0xFF90A4AE);
  static const Color snow = Color(0xFFFAFAFA);
}

// Now, let's create our ThemeData
final ThemeData tenorWispTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // 1. Color Scheme
  // We use ColorScheme.fromSeed and then override the specific colors
  // that you have defined. This gives us a full, harmonious color palette.
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.etherealBlue, // The primary color is used to generate other shades
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.etherealBlue,
    secondary: AppColors.gentlePink,
    tertiary: AppColors.wispLavender,
    background: AppColors.snow,
    surface: AppColors.snow, // Used for the surface of cards, dialogs, etc.
    onPrimary: Colors.white, // Text/icon color on top of the primary color
    onSecondary: AppColors.darkSlate, // Text/icon color on top of the secondary color
    onTertiary: AppColors.darkSlate, // Text/icon color on top of the tertiary color
    onBackground: AppColors.darkSlate, // Primary text color
    onSurface: AppColors.darkSlate, // Primary text color
    onSurfaceVariant: AppColors.coolGray, // For subtitles, hints, etc.
    error: Colors.redAccent, // A standard error color
    onError: Colors.white, // Text on top of error color
  ),

  // 2. Text Theme
  // This defines the default text styles for headlines, titles, body text, etc.
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.darkSlate),
    displayMedium: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.darkSlate),
    displaySmall: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.darkSlate),
    headlineLarge: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.darkSlate),
    headlineMedium: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.darkSlate),
    headlineSmall: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.darkSlate),
    titleLarge: TextStyle(fontFamily: 'YourCustomFont', fontWeight: FontWeight.bold, color: AppColors.darkSlate),
    titleMedium: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.darkSlate),
    titleSmall: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.darkSlate),
    bodyLarge: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.darkSlate),
    bodyMedium: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.darkSlate),
    bodySmall: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.coolGray),
    labelLarge: TextStyle(fontFamily: 'YourCustomFont', fontWeight: FontWeight.bold, color: Colors.white),
    labelMedium: TextStyle(fontFamily: 'YourCustomFont', color: AppColors.coolGray),
    labelSmall: TextStyle(fontFamily: 'YourCustom-Font', color: AppColors.coolGray),
  ).apply(
    bodyColor: AppColors.darkSlate,
    displayColor: AppColors.darkSlate,
  ),

  // 3. Component Themes
  // Here we can style specific widgets globally.
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.etherealBlue,
    foregroundColor: Colors.white, // Title and icon color
    elevation: 2,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.etherealBlue, // Main button background
      foregroundColor: Colors.white, // Main button text/icon color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: AppColors.coolGray), // For placeholder text
    labelStyle: const TextStyle(color: AppColors.coolGray),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.coolGray, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.etherealBlue, width: 2.0),
    ),
  ),
);
