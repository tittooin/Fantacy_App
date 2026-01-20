
import 'package:flutter/material.dart';

class AppColors {
  // Primary Backgrounds
  static const Color primaryBackground = Color(0xFF2EA7FF); // Bright Sky Blue
  static const Color secondaryBackground = Color(0xFF0E1B3D); // Deep Blue for contrast
  static const Color skyBlue = Color(0xFF3BB3FF);
  
  // Cards & Surface
  static const Color cardColor = Color(0xFFFFFFFF); // Solid White for Flat UI
  static const Color cardSurface = Color(0xFFF1F5F9); // Light Slate
  static const Color cardBorder = Color(0xFFE2E8F0);
  
  // Accents
  static const Color accentBlue = Color(0xFF4FC3F7); // Cyan Accent
  static const Color ctaColor = Color(0xFF26A69A); // Solid Blue-Green for CTA
  static const Color accentGold = Color(0xFFFFD700); // Winner Gold
  
  // Backward Compatibility (Aliases for Blue/Red theme)
  static const Color accentGreen = Color(0xFF4FC3F7); // Mapped to Cyan for sports look
  static const Color accentRed = Color(0xFFEF4444); // Standard Soft Red for errors
  
  // Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textBlack = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x26FFFFFF), Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
