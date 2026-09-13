import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system for SoundShare.
class AppTextStyles {
  AppTextStyles._();

  // App name / large display
  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  // Section headings
  static TextStyle get headingLarge => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get headingMedium => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get headingSmall => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  // Body text
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // Labels / captions
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.3,
      );

  // Button
  static TextStyle get buttonLarge => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonMedium => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.purple,
      );

  // Status / badge
  static TextStyle get statusSuccess => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.success,
      );

  static TextStyle get statusMuted => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  // Nav label
  static TextStyle get navLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );

  // App branding tagline
  static TextStyle get tagline => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );
}
