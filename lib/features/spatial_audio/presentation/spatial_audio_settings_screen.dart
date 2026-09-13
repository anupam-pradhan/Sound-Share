import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import '../domain/spatial_audio_models.dart';
import '../domain/spatial_audio_providers.dart';
import 'widgets/spatial_sound_visualizer.dart';

/// Pixel-perfect 3D Spatial Audio Screen matching the reference design.
class SpatialAudioSettingsScreen extends ConsumerStatefulWidget {
  const SpatialAudioSettingsScreen({super.key});

  @override
  ConsumerState<SpatialAudioSettingsScreen> createState() =>
      _SpatialAudioSettingsScreenState();
}

class _SpatialAudioSettingsScreenState
    extends ConsumerState<SpatialAudioSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _centerAnimController;
  late AnimationController _autoPlayController;
  Animation<SpatialAudioPosition>? _centerAnimation;

  bool _isAutoPlaying = false;
  bool _testingAudio = false;

  static const Color _accentPurple = Color(0xFF7A5AF8);
  static const Color _accentBlue = Color(0xFF53B1FD);
  static const Color _statusGreen = Color(0xFF12B76A);

  @override
  void initState() {
    super.initState();
    _centerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _autoPlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..addListener(_onAutoPlayTick);
  }

  @override
  void dispose() {
    _autoPlayController.removeListener(_onAutoPlayTick);
    _autoPlayController.dispose();
    _centerAnimController.dispose();
    super.dispose();
  }

  void _onAutoPlayTick() {
    if (!_isAutoPlaying) return;
    final progress = _autoPlayController.value * 2.0 * math.pi;
    final x = (0.85 * math.sin(progress)).clamp(-1.0, 1.0);
    final y = (0.45 + 0.35 * math.cos(progress)).clamp(-1.0, 1.0);

    ref
        .read(spatialAudioSettingsProvider.notifier)
        .setPosition(SpatialAudioPosition(x: x, y: y, z: 0.0));
  }

  void _toggleAutoPlay() {
    AppHaptics.medium();
    setState(() {
      _isAutoPlaying = !_isAutoPlaying;
      if (_isAutoPlaying) {
        _autoPlayController.repeat();
      } else {
        _autoPlayController.stop();
      }
    });
  }

  void _animateToCenter(SpatialAudioPosition current) {
    if (_isAutoPlaying) {
      _toggleAutoPlay();
    }

    AppHaptics.light();
    const target = SpatialAudioPosition(x: 0.0, y: 0.8, z: 0.0);

    _centerAnimation = SpatialAudioPositionTween(
      begin: current,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _centerAnimController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        if (_centerAnimation != null) {
          ref
              .read(spatialAudioSettingsProvider.notifier)
              .setPosition(_centerAnimation!.value);
        }
      });

    _centerAnimController.forward(from: 0.0);
  }

  Future<void> _startTest() async {
    if (_isAutoPlaying) {
      _toggleAutoPlay();
    }

    AppHaptics.medium();
    setState(() => _testingAudio = true);

    await ref.read(spatialAudioSettingsProvider.notifier).startTestAudio();

    await Future.delayed(const Duration(milliseconds: 3200));
    if (mounted) {
      setState(() => _testingAudio = false);
      AppHaptics.selection();
    }
  }

  void _showInfoSheet(BuildContext context, bool isDark) {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF13121D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222033) : const Color(0xFFE4E0F4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.spatial_audio_rounded, color: _accentPurple, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      '3D Spatial Audio Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'SoundShare utilizes real-time HRTF binaural synthesis to position sound in 360° virtual acoustic space. Head tracking accurately keeps your virtual audio stage anchored in world space as you move.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: isDark ? const Color(0xFF8C8A9E) : const Color(0xFF6E6B87),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: _accentPurple.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: _accentPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatPositionName(SpatialAudioPosition pos) {
    final dist = pos.distance;
    final y = pos.y;
    final x = pos.x;

    if (dist < 0.18) return 'Center';
    if (y > 0.35 && x.abs() < 0.35) return 'Front';
    if (y > 0.35 && x > 0.35) return 'Front Right';
    if (y > 0.35 && x < -0.35) return 'Front Left';
    if (y < -0.35 && x.abs() < 0.35) return 'Back';
    if (y < -0.35 && x > 0.35) return 'Rear Right';
    if (y < -0.35 && x < -0.35) return 'Rear Left';
    if (x > 0.35) return 'Right';
    if (x < -0.35) return 'Left';
    return 'Front Right';
  }

  int _getPositionDotIndex(SpatialAudioPosition pos) {
    final name = _formatPositionName(pos);
    switch (name) {
      case 'Front':
        return 0;
      case 'Front Right':
        return 1;
      case 'Right':
        return 2;
      case 'Rear Right':
        return 3;
      case 'Back':
        return 4;
      case 'Rear Left':
        return 5;
      case 'Left':
        return 6;
      case 'Front Left':
        return 7;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settings = ref.watch(spatialAudioSettingsProvider);
    final stateAsync = ref.watch(spatialAudioStateProvider);
    final capsAsync = ref.watch(spatialAudioCapabilitiesProvider);

    final isEnabled = settings.enabled;
    final liveState = stateAsync.valueOrNull ?? SpatialAudioState.initial();
    final headYaw = liveState.headYaw;
    final isTesting = _testingAudio || liveState.isTesting;

    final positionName = _formatPositionName(settings.position);
    final dotIndex = _getPositionDotIndex(settings.position);

    // Color tokens
    final bg = isDark ? const Color(0xFF07060D) : const Color(0xFFFAFAFE);
    final cardBg = isDark ? const Color(0xFF0F0E18) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E1C2B) : const Color(0xFFF0EDFA);
    final textPrimary = isDark ? Colors.white : const Color(0xFF161528);
    final textSecondary = isDark ? const Color(0xFF8B889E) : const Color(0xFF7E7A94);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header with circular action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    isDark: isDark,
                    onPressed: () {
                      AppHaptics.light();
                      context.pop();
                    },
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3D Spatial Audio',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Immersive sound around you',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _CircleButton(
                    icon: Icons.settings_outlined,
                    isDark: isDark,
                    onPressed: () => _showInfoSheet(context, isDark),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  children: [
                    // 2. Main 3D Spatial Visualizer
                    SpatialSoundVisualizer(
                      position: settings.position,
                      isEnabled: isEnabled,
                      isDark: isDark,
                      headYaw: headYaw,
                      isTesting: isTesting,
                      height: 290,
                      onPositionChanged: (newPos) {
                        if (_isAutoPlaying) {
                          _toggleAutoPlay();
                        }
                        ref
                            .read(spatialAudioSettingsProvider.notifier)
                            .setPosition(newPos);
                      },
                    ),

                    const SizedBox(height: 6),

                    // 3. Position Capsule Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141320) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E2B45) : const Color(0xFFE4E0F4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? const Color(0xFF7A5AF8).withValues(alpha: 0.12)
                                : const Color(0xFF7A5AF8).withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.graphic_eq_rounded,
                            size: 16,
                            color: _accentPurple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            positionName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFB4A1FF) : const Color(0xFF282538),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 4. Dot Pagination under position pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(8, (i) {
                        final isActive = i == dotIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: isActive ? 6 : 4,
                          height: isActive ? 6 : 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? _accentPurple
                                : (isDark ? const Color(0xFF2E2B40) : const Color(0xFFD6D3E8)),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 14),

                    // 5. Status & Quick Actions Row (Status on left, Center & Auto on right)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          // Status
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isEnabled ? _statusGreen : textSecondary,
                                    boxShadow: isEnabled
                                        ? [
                                            BoxShadow(
                                              color: _statusGreen.withValues(alpha: 0.5),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '3D Spatial Audio',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(
                                    '|',
                                    style: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                                  ),
                                ),
                                Text(
                                  isEnabled ? 'Active' : 'Off',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isEnabled ? _statusGreen : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Quick Auto L↔R Action
                          GestureDetector(
                            onTap: isEnabled ? _toggleAutoPlay : null,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                              decoration: BoxDecoration(
                                color: _isAutoPlaying
                                    ? _accentPurple.withValues(alpha: 0.18)
                                    : cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _isAutoPlaying ? _accentPurple : cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isAutoPlaying
                                        ? Icons.pause_rounded
                                        : Icons.swap_horiz_rounded,
                                    size: 15,
                                    color: _isAutoPlaying ? _accentPurple : textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isAutoPlaying ? 'Auto' : 'Auto L↔R',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _isAutoPlaying ? _accentPurple : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Quick Center Sound Button
                          GestureDetector(
                            onTap: isEnabled ? () => _animateToCenter(settings.position) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.center_focus_strong_rounded,
                                    size: 14,
                                    color: isEnabled ? _accentPurple : textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Center Sound',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isEnabled ? textPrimary : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 6. Head Tracking Card
                    _SectionCard(
                      isDark: isDark,
                      child: capsAsync.when(
                        data: (caps) {
                          final canTrack = caps.supportsHeadTracking;
                          final isTrackingOn = canTrack && settings.headTracking;

                          return Row(
                            children: [
                              _IconSquare(
                                icon: Icons.blur_circular_rounded,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Head Tracking',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Keep sound positioned as you move',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Switch(
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: _accentPurple,
                                    inactiveTrackColor: isDark
                                        ? const Color(0xFF262436)
                                        : const Color(0xFFE2DFEC),
                                    value: isTrackingOn,
                                    onChanged: (isEnabled && canTrack)
                                        ? (val) {
                                            AppHaptics.selection();
                                            ref
                                                .read(spatialAudioSettingsProvider.notifier)
                                                .setHeadTracking(val);
                                          }
                                        : null,
                                  ),
                                  Text(
                                    isTrackingOn ? 'On' : 'Off',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isTrackingOn ? _statusGreen : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 7. Immersion & Distance Dual Slider Card
                    _SectionCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          // Immersion Row
                          _SliderRow(
                            icon: Icons.graphic_eq_rounded,
                            title: 'Immersion',
                            subtitle: 'Affects the width and depth of sound',
                            minLabel: 'Low',
                            maxLabel: 'High',
                            value: settings.immersion,
                            enabled: isEnabled,
                            isDark: isDark,
                            onChanged: (val) {
                              ref
                                  .read(spatialAudioSettingsProvider.notifier)
                                  .setImmersion(val);
                            },
                          ),

                          const SizedBox(height: 16),

                          // Distance Row
                          _SliderRow(
                            icon: Icons.adjust_rounded,
                            title: 'Distance',
                            subtitle: 'Controls how far the sound feels',
                            minLabel: 'Near',
                            maxLabel: 'Far',
                            value: settings.distance,
                            enabled: isEnabled,
                            isDark: isDark,
                            onChanged: (val) {
                              ref
                                  .read(spatialAudioSettingsProvider.notifier)
                                  .setDistance(val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 8. Spatial Presets Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Spatial Presets',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 5 Preset Cards
                    SizedBox(
                      height: 94,
                      child: Row(
                        children: [
                          _PresetCard(
                            label: 'Balanced',
                            icon: Icons.graphic_eq_rounded,
                            iconColor: const Color(0xFF9E77ED),
                            isSelected: settings.preset == SpatialPreset.balanced,
                            isDark: isDark,
                            onTap: isEnabled
                                ? () {
                                    if (_isAutoPlaying) _toggleAutoPlay();
                                    AppHaptics.selection();
                                    ref
                                        .read(spatialAudioSettingsProvider.notifier)
                                        .applyPreset(SpatialPreset.balanced);
                                  }
                                : null,
                          ),
                          const SizedBox(width: 8),
                          _PresetCard(
                            label: 'Wide',
                            icon: Icons.cell_tower_rounded,
                            iconColor: const Color(0xFF53B1FD),
                            isSelected: settings.preset == SpatialPreset.wide,
                            isDark: isDark,
                            onTap: isEnabled
                                ? () {
                                    if (_isAutoPlaying) _toggleAutoPlay();
                                    AppHaptics.selection();
                                    ref
                                        .read(spatialAudioSettingsProvider.notifier)
                                        .applyPreset(SpatialPreset.wide);
                                  }
                                : null,
                          ),
                          const SizedBox(width: 8),
                          _PresetCard(
                            label: 'Cinema',
                            icon: Icons.movie_outlined,
                            iconColor: isDark ? const Color(0xFF9E9AB5) : const Color(0xFF55536D),
                            isSelected: settings.preset == SpatialPreset.cinema,
                            isDark: isDark,
                            onTap: isEnabled
                                ? () {
                                    if (_isAutoPlaying) _toggleAutoPlay();
                                    AppHaptics.selection();
                                    ref
                                        .read(spatialAudioSettingsProvider.notifier)
                                        .applyPreset(SpatialPreset.cinema);
                                  }
                                : null,
                          ),
                          const SizedBox(width: 8),
                          _PresetCard(
                            label: 'Gaming',
                            icon: Icons.sports_esports_outlined,
                            iconColor: const Color(0xFF12B76A),
                            isSelected: settings.preset == SpatialPreset.gaming,
                            isDark: isDark,
                            onTap: isEnabled
                                ? () {
                                    if (_isAutoPlaying) _toggleAutoPlay();
                                    AppHaptics.selection();
                                    ref
                                        .read(spatialAudioSettingsProvider.notifier)
                                        .applyPreset(SpatialPreset.gaming);
                                  }
                                : null,
                          ),
                          const SizedBox(width: 8),
                          _PresetCard(
                            label: 'Immersive',
                            icon: Icons.person_outline_rounded,
                            iconColor: const Color(0xFFF79009),
                            isSelected: settings.preset == SpatialPreset.immersive,
                            isDark: isDark,
                            onTap: isEnabled
                                ? () {
                                    if (_isAutoPlaying) _toggleAutoPlay();
                                    AppHaptics.selection();
                                    ref
                                        .read(spatialAudioSettingsProvider.notifier)
                                        .applyPreset(SpatialPreset.immersive);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Preset pagination dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accentPurple,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF323045) : const Color(0xFFD4D0E6),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 9. Bottom Dual Action Cards (Test 3D Audio & Center Sound)
                    Row(
                      children: [
                        // Left: Test 3D Audio Card
                        Expanded(
                          child: GestureDetector(
                            onTap: isEnabled && !isTesting ? _startTest : null,
                            child: _BottomActionCard(
                              icon: isTesting ? Icons.spatial_tracking_rounded : Icons.play_arrow_rounded,
                              title: isTesting ? 'Testing Audio...' : 'Test 3D Audio',
                              subtitle: 'Play demo to feel the difference',
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Right: Center Sound Card
                        Expanded(
                          child: GestureDetector(
                            onTap: isEnabled ? () => _animateToCenter(settings.position) : null,
                            child: _BottomActionCard(
                              icon: Icons.center_focus_strong_rounded,
                              title: 'Center Sound',
                              subtitle: 'Bring sound to your center',
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 10. Master Bottom Action Bar (3D Audio On / Enable 3D Audio)
                    GestureDetector(
                      onTap: () {
                        AppHaptics.medium();
                        if (isEnabled && _isAutoPlaying) {
                          _toggleAutoPlay();
                        }
                        ref
                            .read(spatialAudioSettingsProvider.notifier)
                            .setEnabled(!isEnabled);
                      },
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: isEnabled
                              ? const LinearGradient(
                                  colors: [_accentPurple, _accentBlue],
                                )
                              : LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF262438), const Color(0xFF1B1A28)]
                                      : [const Color(0xFFDCDAEB), const Color(0xFFCBC8DD)],
                                ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isEnabled
                              ? [
                                  BoxShadow(
                                    color: _accentPurple.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.graphic_eq_rounded,
                                size: 24,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEnabled ? '3D Audio On' : 'Enable 3D Audio',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  Text(
                                    isEnabled ? 'Tap to disable' : 'Tap to activate',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Reusable UI Components
// ──────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.isDark,
    required this.onPressed,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF13121E) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF222032) : const Color(0xFFECE9F8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.isDark});
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0E18) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E1C2B) : const Color(0xFFF0EDFA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconSquare extends StatelessWidget {
  const _IconSquare({required this.icon, required this.isDark});
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1A2E) : const Color(0xFFF4F2FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 22,
        color: const Color(0xFF9E77ED),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.minLabel,
    required this.maxLabel,
    required this.value,
    required this.enabled,
    required this.isDark,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String minLabel;
  final String maxLabel;
  final double value;
  final bool enabled;
  final bool isDark;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF161528);
    final textSecondary = isDark ? const Color(0xFF8B889E) : const Color(0xFF7E7A94);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconSquare(icon: icon, isDark: isDark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: const Color(0xFF7A5AF8),
                        inactiveTrackColor: isDark
                            ? const Color(0xFF222032)
                            : const Color(0xFFEAE7F6),
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                          elevation: 3,
                        ),
                        overlayColor: const Color(0xFF7A5AF8).withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: value.clamp(0.0, 1.0),
                        onChanged: enabled
                            ? (v) {
                                AppHaptics.selection();
                                onChanged(v);
                              }
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(value * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9E77ED),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      minLabel,
                      style: TextStyle(fontSize: 10, color: textSecondary),
                    ),
                    Text(
                      maxLabel,
                      style: TextStyle(fontSize: 10, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF19172B) : const Color(0xFFF7F5FE))
                : (isDark ? const Color(0xFF0F0E18) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7A5AF8)
                  : (isDark ? const Color(0xFF1E1C2B) : const Color(0xFFF0EDFA)),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7A5AF8).withValues(alpha: isDark ? 0.25 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF7A5AF8)
                          : (isDark ? const Color(0xFF8B889E) : const Color(0xFF7E7A94)),
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionCard extends StatelessWidget {
  const _BottomActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF161528);
    final textSecondary = isDark ? const Color(0xFF8B889E) : const Color(0xFF7E7A94);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0E18) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E1C2B) : const Color(0xFFF0EDFA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1A2E) : const Color(0xFFF4F2FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF9E77ED),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: textSecondary,
          ),
        ],
      ),
    );
  }
}
