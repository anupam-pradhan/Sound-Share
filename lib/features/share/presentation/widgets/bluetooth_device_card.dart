import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/widgets/bluetooth_device_icon.dart';
import 'package:soundshare/core/widgets/animated_widgets.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';

/// Card for a single discovered Bluetooth device with connect/disconnect.
class BluetoothDeviceCard extends ConsumerStatefulWidget {
  const BluetoothDeviceCard({
    super.key,
    required this.device,
    required this.animationDelay,
  });

  final BluetoothDeviceModel device;
  final Duration animationDelay;

  @override
  ConsumerState<BluetoothDeviceCard> createState() =>
      _BluetoothDeviceCardState();
}

class _BluetoothDeviceCardState extends ConsumerState<BluetoothDeviceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _appearController;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOut,
    ));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _appearController.forward();
    });
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  bool get _isConnecting =>
      widget.device.connectionState == DeviceConnectionState.connecting;

  bool get _isConnected =>
      widget.device.connectionState == DeviceConnectionState.connected;

  bool get _isAvailable =>
      widget.device.connectionState == DeviceConnectionState.available;

  bool get _isDiscovering =>
      widget.device.connectionState == DeviceConnectionState.discovering;

  Future<void> _connect() async {
    HapticFeedback.lightImpact();

    final discoveredNotifier = ref.read(discoveredDevicesProvider.notifier);
    final connectedNotifier = ref.read(connectedDevicesProvider.notifier);

    discoveredNotifier.updateDeviceState(
        widget.device.id, DeviceConnectionState.connecting);

    try {
      // 1. Native A2DP audio connect (connects headphones/earbuds at the Android audio level)
      await discoveredNotifier.connectAudioDevice(widget.device.id);

      // 2. Also attempt BLE GATT connect if supported
      try {
        final btDevice = BluetoothDevice.fromId(widget.device.id);
        await btDevice.connect(timeout: const Duration(seconds: 3));
      } catch (_) {}

      if (!mounted) return;

      // 3. Refresh live connected devices from Android AudioManager
      await connectedNotifier.refreshConnectedDevices();

      discoveredNotifier.updateDeviceState(
          widget.device.id, DeviceConnectionState.connected);
      connectedNotifier.addDevice(widget.device);

      setState(() => _showSuccess = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _showSuccess = false);
    } catch (_) {
      if (!mounted) return;
      discoveredNotifier.updateDeviceState(
          widget.device.id, DeviceConnectionState.available);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pair "${widget.device.name}" in Bluetooth Settings?',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          action: SnackBarAction(
            label: 'Open Settings',
            textColor: AppColors.purpleLight,
            onPressed: () {
              ref.read(audioSharingServiceProvider).openBluetoothSettings();
            },
          ),
          backgroundColor: AppColors.textPrimary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    HapticFeedback.lightImpact();

    // Stop sharing first if active
    final sharingState = ref.read(audioSharingStateProvider);
    if (sharingState == AudioSharingState.sharing) {
      await ref.read(audioSharingStateProvider.notifier).stopSharing();
    }

    final discoveredNotifier = ref.read(discoveredDevicesProvider.notifier);
    final connectedNotifier = ref.read(connectedDevicesProvider.notifier);

    discoveredNotifier.updateDeviceState(
        widget.device.id, DeviceConnectionState.disconnecting);

    // 1. Native A2DP disconnect
    try {
      await discoveredNotifier.disconnectAudioDevice(widget.device.id);
    } catch (_) {}

    // 2. BLE disconnect
    try {
      final btDevice = BluetoothDevice.fromId(widget.device.id);
      await btDevice.disconnect();
    } catch (_) {}

    connectedNotifier.removeDevice(widget.device.id);
    discoveredNotifier.updateDeviceState(
        widget.device.id, DeviceConnectionState.available);

    await connectedNotifier.refreshConnectedDevices();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: _cardContent(),
      ),
    );
  }

  Widget _cardContent() {
    final isMuted = widget.device.isMuted;
    final volume = isMuted ? 0.0 : widget.device.volumeLevel;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final connectedBg = isDark
        ? const Color(0xFF132B25)
        : AppColors.successLight.withValues(alpha: 0.7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isConnected ? connectedBg : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isConnected
              ? AppColors.success.withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF2B293E) : AppColors.cardBorder),
          width: _isConnected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isConnected
                ? AppColors.success.withValues(alpha: 0.08)
                : (isDark ? Colors.black.withValues(alpha: 0.2) : AppColors.cardShadow),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Device icon with optional success pulse
              if (_showSuccess)
                PulseIndicator(
                  size: 52,
                  color: AppColors.success,
                  child: BluetoothDeviceIcon(
                    type: widget.device.type,
                    size: 26,
                    isConnected: true,
                  ),
                )
              else
                BluetoothDeviceIcon(
                  type: widget.device.type,
                  size: 26,
                  isConnected: _isConnected,
                ),

              const SizedBox(width: 12),

              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.device.name,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    _statusText(),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action button
              _actionWidget(),
            ],
          ),

          // Individual Sound & Volume Control when connected
          if (_isConnected) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1A28) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  // Mute / Unmute Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(connectedDevicesProvider.notifier)
                          .toggleMute(widget.device.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isMuted
                            ? AppColors.error.withValues(alpha: 0.12)
                            : AppColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isMuted
                            ? Icons.volume_off_rounded
                            : (volume > 0.5
                                ? Icons.volume_up_rounded
                                : Icons.volume_down_rounded),
                        size: 18,
                        color: isMuted ? AppColors.error : AppColors.purple,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Individual Volume Slider
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                          pressedElevation: 2,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: isMuted
                            ? AppColors.disabled
                            : AppColors.purple,
                        inactiveTrackColor: AppColors.cardBorder,
                        thumbColor: isMuted
                            ? AppColors.disabled
                            : AppColors.purple,
                        overlayColor: AppColors.purple.withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: volume,
                        onChanged: isMuted
                            ? null
                            : (val) {
                                ref
                                    .read(connectedDevicesProvider.notifier)
                                    .updateVolume(widget.device.id, val);
                              },
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Volume Percentage Label
                  SizedBox(
                    width: 38,
                    child: Text(
                      isMuted ? 'Mute' : '${(volume * 100).toInt()}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isMuted
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusText() {
    if (_isConnecting) {
      return Text('Connecting...', style: AppTextStyles.statusMuted);
    }
    if (_isConnected) {
      return Text(
        'Connected',
        style: AppTextStyles.statusSuccess,
      );
    }
    if (_isDiscovering) {
      return Text('Discovering...', style: AppTextStyles.statusMuted);
    }
    if (widget.device.connectionState == DeviceConnectionState.failed) {
      return Text(
        'Failed to connect',
        style: AppTextStyles.statusMuted.copyWith(color: AppColors.error),
      );
    }
    return Text('Available', style: AppTextStyles.statusMuted);
  }

  Widget _actionWidget() {
    if (_isConnecting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.purple,
        ),
      );
    }

    if (_isConnected) {
      return _OutlinedActionButton(
        label: 'Disconnect',
        color: AppColors.error,
        onTap: _disconnect,
      );
    }

    if (_isAvailable || _isDiscovering) {
      return _OutlinedActionButton(
        label: 'Connect',
        color: AppColors.purple,
        onTap: _isAvailable ? _connect : null,
      );
    }

    return const SizedBox.shrink();
  }
}

class _OutlinedActionButton extends StatefulWidget {
  const _OutlinedActionButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_OutlinedActionButton> createState() => _OutlinedActionButtonState();
}

class _OutlinedActionButtonState extends State<_OutlinedActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.onTap != null
                ? widget.color.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.onTap != null
                  ? widget.color.withValues(alpha: 0.4)
                  : AppColors.disabled,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.onTap != null ? widget.color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
