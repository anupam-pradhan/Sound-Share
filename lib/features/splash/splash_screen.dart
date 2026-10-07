import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soundshare/core/constants/app_assets.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _waveController;
  late final AnimationController _ringController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _waveOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _waveOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeOut),
    );

    if (!(WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations)) {
      _ringController.repeat();
    }
    _startSequence();
  }

  Future<void> _startSequence() async {
    // Step 1: Animate logo in
    await _logoController.forward();
    if (!mounted) return;

    // Step 2: Fade in waveform
    await _waveController.forward();
    if (!mounted) return;

    // Step 3: Check if permissions are already granted
    final btScanStatus = await Permission.bluetoothScan.status;
    final btConnectStatus = await Permission.bluetoothConnect.status;
    final btLegacyStatus = await Permission.bluetooth.status;

    if (!mounted) return;

    if ((btScanStatus.isGranted && btConnectStatus.isGranted) ||
        btLegacyStatus.isGranted) {
      context.go('/share');
    } else {
      context.go('/permissions');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _waveController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purple,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B4BDB), AppColors.purple, AppColors.blue],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(top: -120, right: -80, child: _Glow(size: 320)),
            const Positioned(bottom: -140, left: -100, child: _Glow(size: 360)),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  AnimatedBuilder(
                    animation:
                        Listenable.merge([_logoController, _ringController]),
                    builder: (context, _) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: SizedBox(
                            width: 220,
                            height: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                for (final offset in [0.0, 0.5])
                                  _Ring(
                                      progress:
                                          (_ringController.value + offset) % 1),
                                Container(
                                  width: 112,
                                  height: 112,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.18),
                                        blurRadius: 30,
                                        offset: const Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(AppAssets.logo,
                                      fit: BoxFit.contain),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, _) => Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - _textOpacity.value)),
                        child: Column(
                          children: [
                            Text(
                              'SoundShare',
                              style: AppTextStyles.displayLarge.copyWith(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Listen together, out loud or in private',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) => Opacity(
                      opacity: _waveOpacity.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          'by Quick Media Solution',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expanding, fading ring that radiates from the logo like sound.
class _Ring extends StatelessWidget {
  const _Ring({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = 112 + 108 * progress;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35 * (1 - progress)),
          width: 2,
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
