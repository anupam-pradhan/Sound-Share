import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';

/// Bottom navigation shell wrapping Share and Settings tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _SoundShareBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                label: 'Share',
                iconBuilder: (color) => _ShareNavIcon(color: color),
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                label: 'Settings',
                iconBuilder: (color) => _SettingsNavIcon(color: color),
                onTap: onTap,
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
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.iconBuilder,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String label;
  final CustomPainter Function(Color) iconBuilder;
  final ValueChanged<int> onTap;

  bool get _selected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    final color = _selected ? AppColors.navActive : AppColors.navInactive;

    return Expanded(
      child: Semantics(
        label: label,
        selected: _selected,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 28,
                child: CustomPaint(
                  painter: iconBuilder(color),
                  size: const Size(24, 24),
                ),
              ),
              Text(
                label,
                style: AppTextStyles.navLabel.copyWith(color: color),
              ),
              if (_selected)
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.navActive,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Nav icon painters using dart:math
// ──────────────────────────────────────────────

class _ShareNavIcon extends CustomPainter {
  _ShareNavIcon({this.color = AppColors.navInactive});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
        Offset(w * 0.5, h * 0.5), w * 0.07, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    // Inner arcs
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5),
          width: w * 0.45,
          height: h * 0.45),
      2.4,
      -1.7,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5),
          width: w * 0.45,
          height: h * 0.45),
      0.74,
      -1.7,
      false,
      paint,
    );

    // Outer arcs
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5),
          width: w * 0.8,
          height: h * 0.8),
      2.7,
      -2.0,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5),
          width: w * 0.8,
          height: h * 0.8),
      0.44,
      -2.0,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShareNavIcon old) => old.color != color;
}

class _SettingsNavIcon extends CustomPainter {
  _SettingsNavIcon({this.color = AppColors.navInactive});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    // Gear shape via path
    final outer = w * 0.42;
    final inner = w * 0.3;
    final path = Path();
    const teeth = 8;
    const toothAngle = 22.5 * math.pi / 180;

    for (int i = 0; i < teeth; i++) {
      final baseAngle = i * (2 * math.pi / teeth);
      final a1 = baseAngle - toothAngle;
      final a2 = baseAngle + toothAngle;
      final aMid = baseAngle + math.pi / teeth;

      if (i == 0) {
        path.moveTo(cx + inner * math.cos(a1), cy + inner * math.sin(a1));
      } else {
        path.lineTo(cx + inner * math.cos(a1), cy + inner * math.sin(a1));
      }
      path.lineTo(cx + outer * math.cos(a1), cy + outer * math.sin(a1));
      path.lineTo(cx + outer * math.cos(a2), cy + outer * math.sin(a2));
      path.lineTo(cx + inner * math.cos(a2), cy + inner * math.sin(a2));
      path.lineTo(cx + inner * math.cos(aMid), cy + inner * math.sin(aMid));
    }
    path.close();
    canvas.drawPath(path, paint);

    // Center circle
    canvas.drawCircle(Offset(cx, cy), w * 0.16, paint);
  }

  @override
  bool shouldRepaint(_SettingsNavIcon old) => old.color != color;
}
