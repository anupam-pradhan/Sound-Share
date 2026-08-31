import 'package:flutter/material.dart';
import 'package:soundshare/app/theme/app_colors.dart';

/// Shimmer skeleton loader for loading states.
class SkeletonLoader extends StatefulWidget {
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
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                AppColors.cardBorder.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.8),
                AppColors.cardBorder.withValues(alpha: 0.3),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer card placeholder for Bluetooth devices while scanning.
class BluetoothDeviceSkeletonCard extends StatelessWidget {
  const BluetoothDeviceSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon skeleton
          const SkeletonLoader(width: 48, height: 48, borderRadius: 14),
          const SizedBox(width: 12),
          // Texts skeleton
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonLoader(width: 80, height: 10, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Button skeleton
          const SkeletonLoader(width: 68, height: 32, borderRadius: 10),
        ],
      ),
    );
  }
}
