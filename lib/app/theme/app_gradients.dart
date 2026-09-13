import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Gradient definitions for SoundShare.
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.purple, AppColors.blue],
    stops: [0.0, 1.0],
  );

  static const LinearGradient primaryVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.purple, AppColors.blue],
  );

  static const LinearGradient primaryDisabled = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD0CFE8), Color(0xFFD0CFE8)],
  );

  static const LinearGradient splashBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8F7FF), Color(0xFFEFEDFF)],
  );

  static const LinearGradient splashBackgroundDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F0E17), Color(0xFF1B1A28)],
  );

  static const LinearGradient cardHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0EEFF), Color(0xFFE8F4FF)],
  );

  static const LinearGradient successGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
  );

  static const LinearGradient iconBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEEECFF), Color(0xFFE4F2FF)],
  );

  static BoxDecoration primaryButton({double radius = 16}) => BoxDecoration(
        gradient: primary,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration disabledButton({double radius = 16}) => BoxDecoration(
        color: AppColors.disabled,
        borderRadius: BorderRadius.circular(radius),
      );

  static BoxDecoration disabledButtonOf(BuildContext context, {double radius = 16}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF26243A) : AppColors.disabled,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}
