import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

export 'app_colors.dart';
export 'app_text_styles.dart';

/// CulturaX ThemeData — apply this in MaterialApp.
class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.terra,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: AppColors.bg,
          onSecondary: AppColors.cream,
          onSurface: AppColors.cream,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
            .copyWith(
          displayLarge: AppTextStyles.display,
          headlineLarge: AppTextStyles.h1,
          headlineMedium: AppTextStyles.h2,
          titleLarge: AppTextStyles.h3,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.button,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.gold,
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gold),
          iconTheme: const IconThemeData(color: AppColors.gold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.bg,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: AppTextStyles.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: const BorderSide(color: AppColors.gold, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: AppTextStyles.buttonOutline,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          labelStyle: AppTextStyles.body.copyWith(color: AppColors.muted),
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.hint),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
        iconTheme: const IconThemeData(color: AppColors.gold),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.gold,
        ),
      );
}
