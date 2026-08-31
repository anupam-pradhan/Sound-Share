import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soundshare/core/constants/app_assets.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/widgets/audio_waveform.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _waveController;
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

    if (!mounted) return;

    if (btScanStatus.isGranted && btConnectStatus.isGranted) {
      context.go('/share');
    } else {
      context.go('/permissions');
    }
  }

  Future<void> _requestPermissions() async {
    // Request Bluetooth and notification permissions
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.notification,
    ].request();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.splashBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo + branding
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Column(
                        children: [
                          // App logo
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                AppAssets.logo,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // App name
                          Opacity(
                            opacity: _textOpacity.value,
                            child: Column(
                              children: [
                                Text(
                                  'SoundShare',
                                  style: AppTextStyles.displayLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Connect multiple devices',
                                  style: AppTextStyles.tagline,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 36),

              // Animated Sound Wave
              AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) {
                  return Opacity(
                    opacity: _waveOpacity.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: AudioWaveform(
                        isActive: true,
                        isSharing: true,
                        height: 56,
                        barCount: 36,
                        color: AppColors.purple.withValues(alpha: 0.75),
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
