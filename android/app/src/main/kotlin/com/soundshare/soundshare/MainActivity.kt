package com.soundshare.soundshare

import android.bluetooth.BluetoothManager
import android.content.Context
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val audioChannel = "com.soundshare/audio"
    private val btChannel = "com.soundshare/bluetooth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Audio method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canShareAudio" -> {
                        result.success(checkAudioSharingCapability())
                    }
                    "getAudioOutputDevices" -> {
                        result.success(getAudioOutputDevices())
                    }
                    "getActiveOutputDevice" -> {
                        result.success(getActiveOutputDevice())
                    }
                    "startForegroundService" -> {
                        AudioShareForegroundService.startService(this)
                        result.success(true)
                    }
                    "stopForegroundService" -> {
                        AudioShareForegroundService.stopService(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Bluetooth info channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, btChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBluetoothEnabled" -> {
                        val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                        result.success(btManager?.adapter?.isEnabled ?: false)
                    }
                    "getConnectedDevices" -> {
                        result.success(getBluetoothConnectedDevices())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun checkAudioSharingCapability(): Map<String, Any> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val canShare: Boolean
        val reason: String

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ can theoretically share to multiple A2DP via AudioManager routing
            canShare = true
            reason = "android_audio_routing"
        } else {
            // Older Android: audio routing to two simultaneous BT outputs is not supported
            canShare = false
            reason = "android_version_unsupported"
        }

        return mapOf(
            "canShare" to canShare,
            "reason" to reason,
            "androidVersion" to Build.VERSION.SDK_INT
        )
    }

    private fun getAudioOutputDevices(): List<Map<String, Any>> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val devices = mutableListOf<Map<String, Any>>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).forEach { device ->
                devices.add(
                    mapOf(
                        "id" to device.id,
                        "type" to device.type,
                        "productName" to device.productName.toString(),
                        "address" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) device.address else "")
                    )
                )
            }
        }

        return devices
    }

    private fun getActiveOutputDevice(): Map<String, Any> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return mapOf(
            "isBluetoothA2dpOn" to audioManager.isBluetoothA2dpOn,
            "isHeadsetOn" to audioManager.isWiredHeadsetOn,
            "isSpeakerphoneOn" to audioManager.isSpeakerphoneOn
        )
    }

    @Suppress("MissingPermission")
    private fun getBluetoothConnectedDevices(): List<Map<String, Any>> {
        val devices = mutableListOf<Map<String, Any>>()
        try {
            val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = btManager?.adapter ?: return devices

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Handled via flutter_blue_plus in Dart
                return devices
            }

            // Legacy approach for pre-S
            val connectedDevices = adapter.bondedDevices ?: return devices
            connectedDevices.forEach { device ->
                devices.add(
                    mapOf(
                        "address" to device.address,
                        "name" to (device.name ?: "Unknown"),
                        "type" to device.type,
                        "bondState" to device.bondState
                    )
                )
            }
        } catch (e: Exception) {
            // Return empty list on any error
        }
        return devices
    }
}
