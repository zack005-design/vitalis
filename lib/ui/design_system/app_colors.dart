import 'package:flutter/material.dart';

/// Refined color tokens for the Stitch "Vitality Glass" design specification.
class AppColors {
  // Base Backgrounds
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color darkBackground = Color(0xFF0B0E14); // Deep Midnight Obsidian

  // Surface Colors
  static const Color lightSurface = Color(0xFFF9F9FF);
  static const Color darkSurface = Color(0xFF141923);   // Midnight Glass Surface

  // Glass Overlays & Containers
  static const Color lightGlassSurface = Color(0xB3FFFFFF); // rgba(255, 255, 255, 0.70)
  static const Color darkGlassSurface = Color(0x29FFFFFF);  // Translucent Frosted Glass Overlay

  static const Color lightCardBorder = Color(0x99FFFFFF);   // rgba(255, 255, 255, 0.6)
  static const Color darkCardBorder = Color(0x2EFFFFFF);    // Crisp Subtle Glass Border

  // Typography & Content
  static const Color lightTextPrimary = Color(0xFF181C23);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  static const Color lightTextSecondary = Color(0xFF414755);
  static const Color darkTextSecondary = Color(0xFFD1D6E5);

  static const Color lightTextMuted = Color(0xFF717786);
  static const Color darkTextMuted = Color(0xFF9EA3B0);

  // Vitality Glass Health Semantic Accents
  static const Color calorieAccent = Color(0xFFFF8C69); // Coral Calories
  static const Color waterAccent = Color(0xFF4CC2C2);   // Teal Water
  static const Color sleepAccent = Color(0xFF6B66FF);   // Vibrant Indigo Sleep
  static const Color primaryBlue = Color(0xFF0070EB);   // Primary Blue
  static const Color scoreAccent = Color(0xFF0070EB);   // Balance Score Blue

  static const Color destructive = Color(0xFFFF453A);   // iOS Destructive Red
  static const Color warning = Color(0xFFFF9F0A);       // iOS Warning Gold

  // Ambient Glows
  static const Color primaryGlow = Color(0x260070EB);
  static const Color waterGlow = Color(0x264CC2C2);
}
