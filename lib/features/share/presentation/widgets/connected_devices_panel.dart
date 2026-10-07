import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/core/widgets/motion/motion.dart';
import 'package:soundshare/core/widgets/surface.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_providers.dart';

import 'dual_headphone_setup_sheet.dart';

/// "Your headphones" section: what is connected, what is actually playing, and how to add more.
class ConnectedDevicesPanel extends ConsumerWidget {
  const ConnectedDevicesPanel({
    super.key,
    required this.connectedDevices,
    required this.sharingState,
  });

  final List<BluetoothDeviceModel> connectedDevices;
  final AudioSharingState sharingState;

  bool get _isSharing => sharingState == AudioSharingState.sharing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(audioSharingServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          'Your headphones',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (connectedDevices.isNotEmpty)
                SectionAction(
                  label: 'Test',
                  icon: Icons.music_note_rounded,
                  onTap: () async {
                    AppHaptics.light();
                    await service.playTestChime();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playing a short test sound…'),
                          duration: Duration(milliseconds: 1400),
                        ),
                      );
                    }
                  },
                ),
              SectionAction(
                label: 'Output',
                icon: Icons.speaker_group_rounded,
                onTap: () {
                  AppHaptics.light();
                  service.openMediaOutputSelector();
                },
              ),
            ],
          ),
        ),
        Surface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < connectedDevices.length; i++) ...[
                if (i > 0) const _RowDivider(),
                Entrance(
                  key: ValueKey('headphone-${connectedDevices[i].id}'),
                  index: i,
                  child: _HeadphoneRow(
                    device: connectedDevices[i],
                    showVolume: _isSharing && connectedDevices[i].isAudioActive,
                  ),
                ),
              ],
              if (connectedDevices.isNotEmpty) const _RowDivider(),
              _AddHeadphoneRow(isFirst: connectedDevices.isEmpty),
            ],
          ),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 74,
      color: Surface.borderColor(context),
    );
  }
}

class _HeadphoneRow extends ConsumerWidget {
  const _HeadphoneRow({required this.device, required this.showVolume});

  final BluetoothDeviceModel device;
  final bool showVolume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playing = device.isAudioActive;
    final notifier = ref.read(connectedDevicesProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              _DeviceAvatar(type: device.type, active: playing),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (playing)
                      _StatusLine(
                        color: AppColors.success,
                        text: device.batteryLevel != null
                            ? 'Playing • ${device.batteryLevel}%'
                            : 'Playing',
                      )
                    else
                      GestureDetector(
                        onTap: () => DualHeadphoneSetupSheet.show(context),
                        child: const _StatusLine(
                          color: Color(0xFFD69E2E),
                          text: 'Standby • Tap for options',
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Disconnect ${device.name}',
                onPressed: () {
                  AppHaptics.light();
                  notifier.disconnectDevice(device.id);
                },
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF8F8BA3) : AppColors.textMuted,
                ),
              ),
            ],
          ),
          Reveal(
            visible: showVolume,
            child: Padding(
              padding: const EdgeInsets.only(left: 58, right: 8, top: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => notifier.toggleMute(device.id),
                    child: Icon(
                      device.isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      size: 18,
                      color: AppColors.purple,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: device.isMuted ? 0 : device.volumeLevel,
                        onChanged: (v) => notifier.updateVolume(device.id, v),
                        activeColor: AppColors.purple,
                        inactiveColor: AppColors.purple.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceAvatar extends StatelessWidget {
  const _DeviceAvatar({required this.type, required this.active});
  final BluetoothDeviceType type;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      BluetoothDeviceType.speaker => Icons.speaker_rounded,
      BluetoothDeviceType.carAudio => Icons.directions_car_rounded,
      _ => Icons.headphones_rounded,
    };
    return AnimatedContainer(
      duration: Motion.medium,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.purple, AppColors.blue],
              )
            : null,
        color: active ? null : AppColors.purple.withValues(alpha: 0.10),
      ),
      child: Icon(
        icon,
        size: 22,
        color: active ? Colors.white : AppColors.purple,
      ),
    );
  }
}

class _AddHeadphoneRow extends StatelessWidget {
  const _AddHeadphoneRow({required this.isFirst});
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        DualHeadphoneSetupSheet.show(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 22, color: AppColors.purple),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFirst ? 'Connect headphones' : 'Add another headphone',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Bluetooth, wired or USB-C',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
