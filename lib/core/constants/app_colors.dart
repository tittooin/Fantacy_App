
import 'package:flutter/material.dart';

class AppColors {
  // AxevoraLabs Social Brand Colors
  static const Color skyBlue = Color(0xFF0EB0E2);     // Primary Social Blue
  static const Color accentRed = Color(0xFFEA2027);   // Action & Highlights
  static const Color darkNavy = Color(0xFF1E293B);    // Primary Text (Charcoal vibe)
  
  // Surface Colors
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color lightBlueBackground = Color(0xFFF0F9FF);
  static const Color glassWhite = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFF64748B);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status Colors
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Aliases for compatibility (Pivoted to Social)
  static const Color vibrantBlue = skyBlue;
  static const Color deepNavy = darkNavy;
  static const Color stadiumRed = accentRed;
  static const Color glossyRed = accentRed;
  static const Color primaryBackground = pureWhite;
  static const Color secondaryBackground = offWhite;
  static const Color cardColor = pureWhite;
  static const Color accentGreen = successGreen;

  // Social Gradients
  static const LinearGradient socialGradient = LinearGradient(
    colors: [skyBlue, Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
