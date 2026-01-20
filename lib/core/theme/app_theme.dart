
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axevora11/core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      primaryColor: AppColors.primaryBackground,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGreen,
        secondary: AppColors.accentRed,
        surface: AppColors.cardColor,
        onSurface: Colors.black, // Ensure text on white cards is black
        background: AppColors.primaryBackground,
        onBackground: AppColors.textWhite,
        error: AppColors.accentRed,
      ),

      // SnackBar Theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colors.white,
        contentTextStyle: TextStyle(color: Colors.black),
        actionTextColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.oswald(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textWhite,
        ),
        displayMedium: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textWhite,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          color: AppColors.textWhite,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          color: AppColors.textGrey,
        ),
        labelLarge: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        surfaceTintColor: Colors.white, // Remove tint
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textWhite,
        ),
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.black, // Dark text on Neon Green
          textStyle: GoogleFonts.oswald(
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        )
      ),
    );
  }
}
