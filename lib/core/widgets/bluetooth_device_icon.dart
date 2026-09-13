import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../features/bluetooth/domain/bluetooth_device_model.dart';

/// Reusable widget that displays the correct vector icon for a Bluetooth device type.
class BluetoothDeviceIcon extends StatelessWidget {
  const BluetoothDeviceIcon({
    super.key,
    required this.type,
    this.size = 36,
    this.isConnected = false,
  });

  final BluetoothDeviceType type;
  final double size;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          gradient: isConnected
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEEECFF), Color(0xFFE4F2FF)],
                ),
          color: isConnected ? AppColors.successLight : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: isConnected
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Center(
          child: CustomPaint(
            size: Size(size, size),
            painter: _devicePainter(type, isConnected),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel {
    switch (type) {
      case BluetoothDeviceType.earbuds:
        return 'Earbuds';
      case BluetoothDeviceType.headphones:
        return 'Headphones';
      case BluetoothDeviceType.speaker:
        return 'Speaker';
      case BluetoothDeviceType.carAudio:
        return 'Car audio';
      case BluetoothDeviceType.audioDevice:
        return 'Audio device';
      case BluetoothDeviceType.phone:
        return 'Phone';
      case BluetoothDeviceType.unknown:
        return 'Bluetooth device';
    }
  }

  CustomPainter _devicePainter(BluetoothDeviceType type, bool isConnected) {
    final color = isConnected ? AppColors.success : AppColors.purple;
    switch (type) {
      case BluetoothDeviceType.earbuds:
        return _EarbudsPainter(color: color);
      case BluetoothDeviceType.headphones:
        return _HeadphonesPainter(color: color);
      case BluetoothDeviceType.speaker:
        return _SpeakerPainter(color: color);
      case BluetoothDeviceType.carAudio:
        return _CarAudioPainter(color: color);
      case BluetoothDeviceType.phone:
        return _PhonePainter(color: color);
      case BluetoothDeviceType.audioDevice:
      case BluetoothDeviceType.unknown:
        return _BluetoothAudioPainter(color: color);
    }
  }
}

// ──────────────────────────────────────────────
// Earbuds Painter
// ──────────────────────────────────────────────

class _EarbudsPainter extends CustomPainter {
  _EarbudsPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Left earbud
    final leftBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.2, w * 0.3, h * 0.45),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(leftBody, fill);
    canvas.drawRRect(leftBody, paint);

    // Left tip
    canvas.drawCircle(Offset(w * 0.23, h * 0.72), w * 0.07, paint);

    // Right earbud
    final rightBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.62, h * 0.2, w * 0.3, h * 0.45),
      Radius.circular(w * 0.1),
    );
    canvas.drawRRect(rightBody, fill);
    canvas.drawRRect(rightBody, paint);

    // Right tip
    canvas.drawCircle(Offset(w * 0.77, h * 0.72), w * 0.07, paint);
  }

  @override
  bool shouldRepaint(_EarbudsPainter old) => old.color != color;
}

// ──────────────────────────────────────────────
// Headphones Painter
// ──────────────────────────────────────────────

class _HeadphonesPainter extends CustomPainter {
  _HeadphonesPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Headband arc
    final arcRect = Rect.fromLTWH(w * 0.1, h * 0.05, w * 0.8, h * 0.65);
    canvas.drawArc(arcRect, 3.14, 3.14, false, paint);

    // Left ear cup
    final leftCup = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.5, w * 0.22, h * 0.38),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(leftCup, paint);

    // Right ear cup
    final rightCup = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.73, h * 0.5, w * 0.22, h * 0.38),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(rightCup, paint);
  }

  @override
  bool shouldRepaint(_HeadphonesPainter old) => old.color != color;
}

// ──────────────────────────────────────────────
// Speaker Painter
// ──────────────────────────────────────────────

class _SpeakerPainter extends CustomPainter {
  _SpeakerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Speaker body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.1, w * 0.7, h * 0.8),
      Radius.circular(w * 0.15),
    );
    canvas.drawRRect(body, paint);

    // Woofer circle
    canvas.drawCircle(Offset(w * 0.5, h * 0.55), w * 0.2, paint);
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.55), w * 0.08, paint..style = PaintingStyle.fill);

    paint
      ..style = PaintingStyle.stroke
      ..color = color;
    // Tweeter dot
    canvas.drawCircle(Offset(w * 0.5, h * 0.22), w * 0.07, paint);
  }

  @override
  bool shouldRepaint(_SpeakerPainter old) => old.color != color;
}

// ──────────────────────────────────────────────
// Car Audio Painter
// ──────────────────────────────────────────────

class _CarAudioPainter extends CustomPainter {
  _CarAudioPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Car body
    final path = Path()
      ..moveTo(w * 0.05, h * 0.65)
      ..lineTo(w * 0.15, h * 0.65)
      ..lineTo(w * 0.25, h * 0.38)
      ..lineTo(w * 0.75, h * 0.38)
      ..lineTo(w * 0.85, h * 0.65)
      ..lineTo(w * 0.95, h * 0.65)
      ..lineTo(w * 0.95, h * 0.72)
      ..lineTo(w * 0.05, h * 0.72)
      ..close();
    canvas.drawPath(path, paint);

    // Windshield
    final glass = Path()
      ..moveTo(w * 0.28, h * 0.38)
      ..lineTo(w * 0.35, h * 0.22)
      ..lineTo(w * 0.65, h * 0.22)
      ..lineTo(w * 0.72, h * 0.38);
    canvas.drawPath(glass, paint);

    // Wheels
    canvas.drawCircle(Offset(w * 0.25, h * 0.75), w * 0.1, paint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.75), w * 0.1, paint);
  }

  @override
  bool shouldRepaint(_CarAudioPainter old) => old.color != color;
}

// ──────────────────────────────────────────────
// Generic Bluetooth/Audio Painter
// ──────────────────────────────────────────────

class _BluetoothAudioPainter extends CustomPainter {
  _BluetoothAudioPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Bluetooth "B" lightning bolt shape
    final path = Path()
      ..moveTo(w * 0.35, h * 0.22)
      ..lineTo(w * 0.65, h * 0.5)
      ..lineTo(w * 0.35, h * 0.78)
      ..lineTo(w * 0.35, h * 0.12)
      ..lineTo(w * 0.65, h * 0.5)
      ..lineTo(w * 0.35, h * 0.88);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BluetoothAudioPainter old) => old.color != color;
}

// ──────────────────────────────────────────────
// Phone Painter
// ──────────────────────────────────────────────

class _PhonePainter extends CustomPainter {
  _PhonePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Phone body (rounded rect)
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.1, w * 0.56, h * 0.8),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(phoneRect, fill);
    canvas.drawRRect(phoneRect, paint);

    // Speaker / Notch line at top
    final notchPaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.42, h * 0.2),
      Offset(w * 0.58, h * 0.2),
      notchPaint,
    );

    // Home indicator dot at bottom
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.78),
      w * 0.045,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PhonePainter old) => old.color != color;
}
