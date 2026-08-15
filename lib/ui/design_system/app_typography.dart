import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Exact typography scale from Stitch Vitality Glass specification.
/// Displays/Headlines: Manrope
/// Body/Labels: Inter
class AppTypography {
  static TextStyle headlineLg(bool isDark) => GoogleFonts.manrope(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 41 / 34,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle headlineMd(bool isDark) => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 30 / 24,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle headlineMobile(bool isDark) => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 28 / 22,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle displayRing(bool isDark) => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 34 / 28,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle monoSm(bool isDark) => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      );

  static TextStyle mono(bool isDark) => GoogleFonts.jetBrainsMono(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle bodyLg(bool isDark) => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 24 / 17,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle bodyMd(bool isDark) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 20 / 15,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle labelSm(bool isDark) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.1,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      );

  static TextStyle headline(bool isDark) => headlineMobile(isDark);
  static TextStyle title1(bool isDark) => headlineLg(isDark);
  static TextStyle title2(bool isDark) => headlineMd(isDark);
  static TextStyle body(bool isDark) => bodyMd(isDark);
  static TextStyle subhead(bool isDark) => bodyMd(isDark);
  static TextStyle footnote(bool isDark) => labelSm(isDark);
  static TextStyle caption(bool isDark) => labelSm(isDark);

  static TextStyle buttonLabel(bool isDark) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );
}
