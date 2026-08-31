import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/core/utils/app_haptics.dart';

/// Reusable wrapper that manages back button behavior across the app shell:
/// 1. If on secondary tab (Settings), back press returns to Home (Share tab).
/// 2. If on primary tab (Share), first back press prompts double-back toast.
/// 3. Second back press within 2s exits the app.
class AppBackHandler extends StatefulWidget {
  const AppBackHandler({
    super.key,
    required this.navigationShell,
    required this.child,
  });

  final StatefulNavigationShell navigationShell;
  final Widget child;

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBackPressTime;

  void _handleBackPress() {
    // If not on Home tab (Share), go back to Home tab
    if (widget.navigationShell.currentIndex != 0) {
      AppHaptics.light();
      widget.navigationShell.goBranch(0);
      return;
    }

    // On Home tab, prompt double-tap to exit
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      AppHaptics.medium();

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Press back again to exit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.textPrimary.withValues(alpha: 0.92),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        ),
      );
      return;
    }

    // Second press within 2 seconds exits cleanly
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: widget.child,
    );
  }
}
