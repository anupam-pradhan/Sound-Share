import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/bluetooth_device_icon.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../features/bluetooth/domain/bluetooth_device_model.dart';
import '../../../features/bluetooth/domain/bluetooth_providers.dart';
import '../../../features/audio_sharing/domain/audio_sharing_providers.dart';

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

    final discoveredNotifier =
        ref.read(discoveredDevicesProvider.notifier);
    final connectedNotifier = ref.read(connectedDevicesProvider.notifier);

    discoveredNotifier.updateDeviceState(
        widget.device.id, DeviceConnectionState.connecting);

    try {
      final btDevice = BluetoothDevice.fromId(widget.device.id);
      await btDevice.connect(timeout: const Duration(seconds: 12));

      if (!mounted) return;

      // Listen for disconnection
      btDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && mounted) {
          connectedNotifier.removeDevice(widget.device.id);
          discoveredNotifier.updateDeviceState(
              widget.device.id, DeviceConnectionState.available);
        }
      });

      discoveredNotifier.updateDeviceState(
          widget.device.id, DeviceConnectionState.connected);
      connectedNotifier.addDevice(widget.device);

      setState(() => _showSuccess = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _showSuccess = false);
    } on Exception catch (e) {
      if (!mounted) return;
      discoveredNotifier.updateDeviceState(
          widget.device.id, DeviceConnectionState.failed);
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        discoveredNotifier.updateDeviceState(
            widget.device.id, DeviceConnectionState.available);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Couldn't connect",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Make sure the device is nearby and try again.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: AppColors.textPrimary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
        widget.device.id, DeviceConnectionState.connecting);

    try {
      final btDevice = BluetoothDevice.fromId(widget.device.id);
      await btDevice.disconnect();
    } catch (_) {}

    connectedNotifier.removeDevice(widget.device.id);
    discoveredNotifier.updateDeviceState(
        widget.device.id, DeviceConnectionState.available);
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isConnected
            ? AppColors.successLight
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isConnected
              ? AppColors.success.withOpacity(0.35)
              : AppColors.cardBorder,
          width: _isConnected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isConnected
                ? AppColors.success.withOpacity(0.08)
                : AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
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
                ? widget.color.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.onTap != null
                  ? widget.color.withOpacity(0.4)
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
