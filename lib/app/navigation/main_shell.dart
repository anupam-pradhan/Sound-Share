import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

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
            color: Colors.black.withOpacity(0.04),
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
                painter: _ShareNavIcon(),
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                label: 'Settings',
                painter: _SettingsNavIcon(),
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
    required this.painter,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String label;
  final CustomPainter painter;
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 28,
                child: CustomPaint(
                  painter: _coloredPainter(painter, color),
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

  CustomPainter _coloredPainter(CustomPainter base, Color color) {
    if (base is _ShareNavIcon) return _ShareNavIcon(color: color);
    if (base is _SettingsNavIcon) return _SettingsNavIcon(color: color);
    return base;
  }
}

// ──────────────────────────────────────────────
// Nav icon painters
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

    // Wireless/share arc icon
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.5), w * 0.07, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5), width: w * 0.45, height: h * 0.45),
      2.4,
      -1.7,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5), width: w * 0.45, height: h * 0.45),
      0.74,
      -1.7,
      false,
      paint,
    );

    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5), width: w * 0.8, height: h * 0.8),
      2.7,
      -2.0,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5), width: w * 0.8, height: h * 0.8),
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
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.18, paint);

    // Gear teeth (6 teeth via path)
    final teethPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.butt;

    final outer = w * 0.42;
    final inner = w * 0.3;
    final cx = w * 0.5;
    final cy = h * 0.5;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle1 = (i * 45 - 10) * 3.14159 / 180;
      final angle2 = (i * 45 + 10) * 3.14159 / 180;
      final angle3 = (i * 45 + 22.5) * 3.14159 / 180;

      final x1 = cx + inner * _cos(angle1);
      final y1 = cy + inner * _sin(angle1);
      final x2 = cx + outer * _cos(angle1);
      final y2 = cy + outer * _sin(angle1);
      final x3 = cx + outer * _cos(angle2);
      final y3 = cy + outer * _sin(angle2);
      final x4 = cx + inner * _cos(angle2);
      final y4 = cy + inner * _sin(angle2);

      if (i == 0) path.moveTo(x1, y1);
      path.lineTo(x2, y2);
      path.lineTo(x3, y3);
      path.lineTo(x4, y4);

      final xArc = cx + inner * _cos(angle3);
      final yArc = cy + inner * _sin(angle3);
      path.lineTo(xArc, yArc);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double a) => (a * 1.0).clamp(-3.14, 3.14) < 1e9
      ? _approxCos(a)
      : 0;
  double _sin(double a) => _approxSin(a);

  double _approxCos(double a) {
    // Use dart:math via import
    return _mathCos(a);
  }

  double _approxSin(double a) {
    return _mathSin(a);
  }

  @override
  bool shouldRepaint(_SettingsNavIcon old) => old.color != color;
}

double _mathCos(double a) {
  // dart:math
  return _dartMathCos(a);
}

double _mathSin(double a) {
  return _dartMathSin(a);
}

double _dartMathCos(double a) {
  const pi = 3.14159265358979;
  // Taylor approximation good enough for icon rendering
  a = a % (2 * pi);
  double result = 1;
  double term = 1;
  for (int i = 1; i <= 6; i++) {
    term *= -a * a / ((2 * i - 1) * (2 * i));
    result += term;
  }
  return result;
}

double _dartMathSin(double a) {
  const pi = 3.14159265358979;
  a = a % (2 * pi);
  double result = a;
  double term = a;
  for (int i = 1; i <= 6; i++) {
    term *= -a * a / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}
