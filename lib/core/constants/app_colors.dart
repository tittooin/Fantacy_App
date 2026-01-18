
import 'package:flutter/material.dart';

class AppColors {
  // Primary Backgrounds
  static const Color primaryBackground = Color(0xFF0F172A); // Deep Navy
  static const Color secondaryBackground = Color(0xFF1E293B); // Lighter Navy
  static const Color cardColor = Color(0xFF334155); // Slate
  static const Color cardSurface = Color(0xFF1E293B); // Darker Slate
  static const Color cardBorder = Color(0xFF475569); // Border Grey
  
  // Accents
  static const Color accentGreen = Color(0xFF00E5FF); // Neon Cyan/Green
  static const Color accentRed = Color(0xFFFF2E63); // Crimson
  static const Color accentGold = Color(0xFFFFD700); // Gold for Winners
  
  // Text
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textGrey = Color(0xFF94A3B8);
  
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
