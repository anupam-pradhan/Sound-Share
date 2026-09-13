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

class _SoundShareBottomNav extends StatelessWidget {
  const _SoundShareBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : AppColors.purple.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                label: 'Share',
                activeIcon: Icons.sensors_rounded,
                inactiveIcon: Icons.sensors_outlined,
                onTap: onTap,
              ),
              const SizedBox(width: 16),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                label: 'Settings',
                activeIcon: Icons.settings_rounded,
                inactiveIcon: Icons.settings_outlined,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final ValueChanged<int> onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  bool get _selected => widget.index == widget.currentIndex;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.purple;
    const inactiveColor = AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        label: widget.label,
        selected: _selected,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap(widget.index);
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _selected
                    ? AppColors.purple.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _selected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      _selected ? widget.activeIcon : widget.inactiveIcon,
                      size: 24,
                      color: _selected ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: AppTextStyles.navLabel.copyWith(
                      color: _selected ? activeColor : inactiveColor,
                      fontWeight: _selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(widget.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
