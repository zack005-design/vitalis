import 'package:flutter/material.dart';

/// Refined color tokens for the Stitch "Vitality Glass" design specification.
class AppColors {
  // Base Backgrounds (Deep Midnight Obsidian)
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color darkBackground = Color(0xFF0B1326); // Midnight Navy Obsidian

  // Surface Colors
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF131B2E);   // Midnight Container Low
  static const Color darkSurfaceHigh = Color(0xFF222A3E); // Container High
  static const Color darkSurfaceHighest = Color(0xFF2D3449); // Container Highest

  // Glass Overlays & Containers
  static const Color lightGlassSurface = Color(0xB3FFFFFF);
  static const Color darkGlassSurface = Color(0x66171F33);  // Frosted Dark Glass

  static const Color lightCardBorder = Color(0x33000000);
  static const Color darkCardBorder = Color(0x1FFFFFFF);    // 12% White Subtle Glass Border

  // Typography & Content
  static const Color lightTextPrimary = Color(0xFF181C23);
  static const Color darkTextPrimary = Color(0xFFDBE2FD);   // Primary On-Surface
  static const Color darkTextHeading = Color(0xFFFFFFFF);

  static const Color lightTextSecondary = Color(0xFF414755);
  static const Color darkTextSecondary = Color(0xFFADC6FF); // Secondary Blue/Slate

  static const Color lightTextMuted = Color(0xFF525866); // WCAG AA compliant (6.3:1 on lightBackground, 7.1:1 on lightSurface)
  static const Color darkTextMuted = Color(0xFFA0A7B8);  // WCAG AA compliant (7.6:1 on darkBackground, 5.2:1 on darkSurfaceHighest)

  // Semantic Accents
  static const Color calorieAccent = Color(0xFFFFB95F);     // Nutrition Amber / Warm Flame
  static const Color waterAccent = Color(0xFF3B82F6);       // Electric Health Blue
  static const Color sleepAccent = Color(0xFF6366F1);       // Sleep Indigo
  static const Color primaryBlue = Color(0xFF3B82F6);       // Health Blue
  static const Color scoreAccent = Color(0xFFADC6FF);       // Balance Glow

  // Macro Accents
  static const Color proteinAccent = Color(0xFF3B82F6);     // Blue
  static const Color carbsAccent = Color(0xFFFFB95F);       // Amber
  static const Color fatAccent = Color(0xFFFF8C69);         // Coral

  static const Color destructive = Color(0xFFFFB4AB);       // Error Red
  static const Color warning = Color(0xFFFFB95F);           // Amber Warning
  static const Color success = Color(0xFF00E676);           // Success Mint

  // Ambient Glows
  static const Color primaryGlow = Color(0x333B82F6);
  static const Color calorieGlow = Color(0x33FFB95F);
  static const Color waterGlow = Color(0x333B82F6);
  static const Color sleepGlow = Color(0x336366F1);
}
