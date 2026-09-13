import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/theme_provider.dart';
import 'package:soundshare/core/utils/app_haptics.dart';

/// Animated toggle button for smoothly switching between Light and Dark mode.
class ThemeToggleIconButton extends ConsumerStatefulWidget {
  const ThemeToggleIconButton({super.key});

  @override
  ConsumerState<ThemeToggleIconButton> createState() =>
      _ThemeToggleIconButtonState();
}

class _ThemeToggleIconButtonState extends ConsumerState<ThemeToggleIconButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Semantics(
      label: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          AppHaptics.light();
          ref.read(themeModeProvider.notifier).toggleTheme();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF26243A)
                  : AppColors.purpleLight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3F3C58)
                    : AppColors.purple.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : AppColors.purple.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: AnimatedRotation(
                turns: isDark ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    size: 20,
                    color: isDark ? const Color(0xFFFFD166) : AppColors.purple,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
