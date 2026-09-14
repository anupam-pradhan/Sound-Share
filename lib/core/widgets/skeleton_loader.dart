import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soundshare/app/theme/app_colors.dart';

/// Shimmer skeleton loader for loading states.
/// Uses the `shimmer` package for smooth, performant shimmer effects.
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1F1D2F) : AppColors.cardBorder.withValues(alpha: 0.3),
      highlightColor: isDark ? const Color(0xFF2E2B42) : Colors.white.withValues(alpha: 0.8),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer card placeholder for Bluetooth devices while scanning.
class BluetoothDeviceSkeletonCard extends StatelessWidget {
  const BluetoothDeviceSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        children: [
          // Icon skeleton
          SkeletonLoader(width: 48, height: 48, borderRadius: 14),
          SizedBox(width: 12),
          // Texts skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonLoader(width: 80, height: 10, borderRadius: 4),
              ],
            ),
          ),
          SizedBox(width: 8),
          // Button skeleton
          SkeletonLoader(width: 68, height: 32, borderRadius: 10),
        ],
      ),
    );
  }
}
