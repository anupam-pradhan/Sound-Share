import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/navigation/app_back_handler.dart';
import 'package:soundshare/core/utils/app_haptics.dart';

/// Bottom navigation shell wrapping Share and Settings tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _onNavTap(int index) {
    AppHaptics.selection();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackHandler(
      navigationShell: navigationShell,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: _SoundShareBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

/// Floating pill navigation with a sliding selection highlight.
class _SoundShareBottomNav extends StatelessWidget {
  const _SoundShareBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (
      label: 'Share',
      active: Icons.graphic_eq_rounded,
      inactive: Icons.graphic_eq_rounded
    ),
    (
      label: 'Settings',
      active: Icons.settings_rounded,
      inactive: Icons.settings_outlined
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark ? const Color(0xFF2E2B45) : AppColors.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : AppColors.purple.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedAlign(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 320),
                  curve: const Cubic(0.2, 0.0, 0, 1.0),
                  alignment: Alignment(
                    _items.length == 1
                        ? 0
                        : -1 + 2 * currentIndex / (_items.length - 1),
                    0,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 1 / _items.length,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.purple, AppColors.blue],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    for (int i = 0; i < _items.length; i++)
                      Expanded(
                        child: _NavItem(
                          label: _items[i].label,
                          icon: i == currentIndex
                              ? _items[i].active
                              : _items[i].inactive,
                          selected: i == currentIndex,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.textSecondary;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.navLabel.copyWith(
                color: color,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
