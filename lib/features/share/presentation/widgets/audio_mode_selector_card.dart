import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';

class AudioModeSelectorCard extends ConsumerWidget {
  const AudioModeSelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilityAsync = ref.watch(audioSharingCapabilityProvider);
    final activeMode = ref.watch(activeSharingModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final capability = capabilityAsync.valueOrNull;
    final recommendedMode = capability?.recommendedMode ?? AudioSharingMode.universalPeerShare;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181628) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2B45) : AppColors.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : AppColors.purple.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header & Device Badge ──────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.purpleLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Sharing Mode',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      capability != null
                          ? '${capability.deviceManufacturer} • Android ${capability.androidVersion}'
                          : 'Auto-adapts to your device',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Mode Option Tabs ───────────────────────────
          Row(
            children: [
              _buildModeTab(
                context: context,
                ref: ref,
                mode: AudioSharingMode.universalPeerShare,
                activeMode: activeMode,
                recommendedMode: recommendedMode,
                icon: Icons.wifi_tethering_rounded,
                label: 'Universal',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildModeTab(
                context: context,
                ref: ref,
                mode: AudioSharingMode.samsungDualAudio,
                activeMode: activeMode,
                recommendedMode: recommendedMode,
                icon: Icons.phone_android_rounded,
                label: 'Samsung',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildModeTab(
                context: context,
                ref: ref,
                mode: AudioSharingMode.auracastBroadcast,
                activeMode: activeMode,
                recommendedMode: recommendedMode,
                icon: Icons.podcasts_rounded,
                label: 'Auracast',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Selected Mode Description & Quick Action ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF100E1C) : const Color(0xFFF6F5FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF26223B) : const Color(0xFFE8E5FA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getModeIcon(activeMode),
                      size: 16,
                      color: AppColors.purpleLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activeMode.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: activeMode == recommendedMode
                            ? const Color(0xFF12B76A).withOpacity(0.15)
                            : AppColors.purple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activeMode == recommendedMode
                            ? 'AUTO-ADOPTED'
                            : activeMode.badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: activeMode == recommendedMode
                              ? const Color(0xFF32D583)
                              : AppColors.purpleLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _getModeDescription(activeMode),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? const Color(0xFFA09EAE) : AppColors.textSecondary,
                  ),
                ),

                if (activeMode == AudioSharingMode.samsungDualAudio) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AppHaptics.light();
                        ref.read(audioSharingServiceProvider).openMediaOutputSelector();
                      },
                      icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                      label: const Text(
                        'Open Samsung Media Output / Dual Audio Panel',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.purpleLight,
                        side: BorderSide(color: AppColors.purpleLight.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required BuildContext context,
    required WidgetRef ref,
    required AudioSharingMode mode,
    required AudioSharingMode activeMode,
    required AudioSharingMode recommendedMode,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = mode == activeMode;
    final isRecommended = mode == recommendedMode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppHaptics.selection();
          ref.read(activeSharingModeProvider.notifier).setMode(mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF6C5CE7) : AppColors.purple)
                : (isDark ? const Color(0xFF100E1C) : const Color(0xFFF1F0FA)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isRecommended
                      ? const Color(0xFF12B76A).withOpacity(0.5)
                      : Colors.transparent),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFD1D5DB) : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon(AudioSharingMode mode) {
    return switch (mode) {
      AudioSharingMode.samsungDualAudio => Icons.phone_android_rounded,
      AudioSharingMode.auracastBroadcast => Icons.podcasts_rounded,
      AudioSharingMode.universalPeerShare => Icons.wifi_tethering_rounded,
    };
  }

  String _getModeDescription(AudioSharingMode mode) {
    return switch (mode) {
      AudioSharingMode.samsungDualAudio =>
        'Plays audio directly from your Samsung phone to 2 connected Bluetooth headphones simultaneously using Samsung One UI Dual Audio.',
      AudioSharingMode.auracastBroadcast =>
        'Directly broadcasts high-efficiency LC3 audio to any nearby Auracast or Bluetooth LE Audio earbuds without requiring a second phone.',
      AudioSharingMode.universalPeerShare =>
        'Works on 100% of smartphones (Pixel, Motorola, Xiaomi, OnePlus, etc.). Streams in real time over local Wi-Fi / Hotspot with zero mobile data.',
    };
  }
}
