import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.offWhite,
      primaryColor: AppColors.skyBlue,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.skyBlue,
        secondary: AppColors.accentRed,
        surface: AppColors.pureWhite,
        onSurface: AppColors.textDark,
        error: AppColors.errorRed,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.oswald(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        displayMedium: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        titleLarge: GoogleFonts.oswald(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textLight,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 1, // Subtle social elevation
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.skyBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textWhite,
        ),
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.skyBlue, // Primary buttons are blue
          foregroundColor: AppColors.textWhite,
          textStyle: GoogleFonts.inter( // Inter for better readability in social apps
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        )
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme; 
}
