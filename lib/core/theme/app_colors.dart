import 'package:flutter/material.dart';

/// J.A's Food Trading Brand Colors
/// Consistent with the web app color scheme
class AppColors {
  // Brand Primary Colors
  static const Color primaryRed = Color(0xFFC21722);
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color goldAccent = Color(0xFFD4AF37);

  // Primary Red Variations
  static const Color primaryRed50 = Color(0xFFFEF2F2);
  static const Color primaryRed100 = Color(0xFFFEE2E2);
  static const Color primaryRed200 = Color(0xFFFECACA);
  static const Color primaryRed500 = primaryRed;
  static const Color primaryRed600 = Color(0xFFA21419);
  static const Color primaryRed700 = Color(0xFF821116);
  static const Color primaryRed800 = Color(0xFF620D10);
  static const Color primaryRed900 = Color(0xFF420A0B);

  // Primary Blue Variations
  static const Color primaryBlue50 = Color(0xFFEFF6FF);
  static const Color primaryBlue100 = Color(0xFFDBEAFE);
  static const Color primaryBlue200 = Color(0xFFBFDBFE);
  static const Color primaryBlue500 = primaryBlue;
  static const Color primaryBlue600 = Color(0xFF1150A3);
  static const Color primaryBlue700 = Color(0xFF0E3A86);
  static const Color primaryBlue800 = Color(0xFF0A2969);
  static const Color primaryBlue900 = Color(0xFF07184C);

  // Gold Accent Variations
  static const Color goldAccent50 = Color(0xFFFFFBEB);
  static const Color goldAccent100 = Color(0xFFFEF3C7);
  static const Color goldAccent200 = Color(0xFFFDE68A);
  static const Color goldAccent500 = goldAccent;
  static const Color goldAccent600 = Color(0xFFB8942E);
  static const Color goldAccent700 = Color(0xFF9C7925);
  static const Color goldAccent800 = Color(0xFF805E1C);
  static const Color goldAccent900 = Color(0xFF644313);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Surface Colors
  static const Color surfacePrimary = white;
  static const Color surfaceSecondary = gray50;
  static const Color surfaceTertiary = gray100;
  static const Color surfaceAccent = primaryRed50;

  // Semantic Colors
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = primaryBlue;
  static const Color infoLight = primaryBlue100;

  // Text Colors
  static const Color textPrimary = gray900;
  static const Color textSecondary = gray600;
  static const Color textTertiary = gray400;
  static const Color textOnPrimary = white;
  static const Color textOnSecondary = white;

  // Border Colors
  static const Color borderLight = gray200;
  static const Color borderMedium = gray300;
  static const Color borderDark = gray400;
}