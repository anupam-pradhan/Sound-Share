package com.soundshare.soundshare

import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.sin

class MainActivity : FlutterActivity() {

    private val audioChannel = "com.soundshare/audio"
    private val btChannel = "com.soundshare/bluetooth"
    private val audioEventsChannel = "com.soundshare/audio_events"

    // [COMMENTED OUT - BeatSync & Spatial Audio disabled per SoundShare-only configuration]
    // private val beatSyncChannel = "com.soundshare/beatsync"
    // private val beatSyncEventsChannel = "com.soundshare/beatsync_events"
    // private val spatialAudioChannel = "com.soundshare/spatial_audio"
    // private val spatialAudioEventsChannel = "com.soundshare/spatial_audio_events"
    // private var beatSyncEngine: BeatSyncNativeEngine? = null
    // private var spatialAudioEngine: SpatialAudioNativeEngine? = null

    private var audioEventSink: EventChannel.EventSink? = null
    private var audioDeviceCallback: AudioDeviceCallback? = null
    private var a2dpProfile: BluetoothA2dp? = null

    // Native audio playback engine for real multi-headphone audio streaming
    private val audioTracks = mutableListOf<AudioTrack>()
    private var isPlayingAudio = false
    private var playbackThread: Thread? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        // Register A2DP Profile proxy to connect Bluetooth audio devices directly
        try {
            val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            btManager?.adapter?.getProfileProxy(applicationContext, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    if (profile == BluetoothProfile.A2DP) {
                        a2dpProfile = proxy as BluetoothA2dp
                    }
                }

                override fun onServiceDisconnected(profile: Int) {
                    if (profile == BluetoothProfile.A2DP) {
                        a2dpProfile = null
                    }
                }
            }, BluetoothProfile.A2DP)
        } catch (_: Exception) {}

        // Register Audio Device change listener
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioDeviceCallback = object : AudioDeviceCallback() {
                override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) {
                    super.onAudioDevicesAdded(addedDevices)
                    notifyAudioDevicesChanged()
                }

                override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>?) {
                    super.onAudioDevicesRemoved(removedDevices)
                    notifyAudioDevicesChanged()
                }
            }
            audioManager.registerAudioDeviceCallback(audioDeviceCallback, null)
        }

        // Audio Events Stream Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, audioEventsChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    audioEventSink = events
                    notifyAudioDevicesChanged()
                }

                override fun onCancel(arguments: Any?) {
                    audioEventSink = null
                }
            })

        // Core Audio Method Channel
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
                    "startAudioPlayback" -> {
                        startNativeAudioPlayback()
                        result.success(true)
                    }
                    "stopAudioPlayback" -> {
                        stopNativeAudioPlayback()
                        result.success(true)
                    }
                    "setDeviceVolume" -> {
                        val address = call.argument<String>("address") ?: ""
                        val volume = call.argument<Double>("volume") ?: 1.0
                        setDeviceVolume(address, volume.toFloat())
                        result.success(true)
                    }
                    "isAudioPlaying" -> {
                        result.success(isPlayingAudio)
                    }
                    "openBluetoothSettings" -> {
                        result.success(openBluetoothSettings())
                    }
                    "openMediaOutputSelector" -> {
                        result.success(openMediaOutputSelector())
                    }
                    "openPlayStore" -> {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName")).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$packageName")).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(webIntent)
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Bluetooth method channel
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
                    "getBondedAudioDevices" -> {
                        result.success(getBondedAudioDevices())
                    }
                    "connectAudioDevice" -> {
                        val address = call.argument<String>("address") ?: ""
                        result.success(connectA2dpDevice(address))
                    }
                    "disconnectAudioDevice" -> {
                        val address = call.argument<String>("address") ?: ""
                        result.success(disconnectA2dpDevice(address))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openBluetoothSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openMediaOutputSelector(): Boolean {
        return try {
            // If Samsung, attempt to open Samsung Media Output panel directly
            if (Build.MANUFACTURER.contains("samsung", ignoreCase = true)) {
                try {
                    val samsungIntent = Intent("com.samsung.android.setting.MEDIA_OUTPUT").apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(samsungIntent)
                    return true
                } catch (_: Exception) {}
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val intent = Intent("android.settings.panel.action.MEDIA_OUTPUT").apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    putExtra("android.provider.extra.PACKAGE_NAME", packageName)
                }
                startActivity(intent)
                true
            } else {
                openBluetoothSettings()
            }
        } catch (_: Exception) {
            openBluetoothSettings()
        }
    }

    @Suppress("MissingPermission")
    private fun connectA2dpDevice(address: String): Boolean {
        try {
            val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = btManager?.adapter ?: return false
            if (!BluetoothAdapter.checkBluetoothAddress(address)) {
                openBluetoothSettings()
                return true
            }
            val device = adapter.getRemoteDevice(address) ?: return false

            // 1. If device is not bonded, initiate pairing
            if (device.bondState != BluetoothDevice.BOND_BONDED) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                    device.createBond()
                }
            }

            // 2. If A2DP profile proxy is available, invoke connect(BluetoothDevice) via reflection
            if (a2dpProfile != null) {
                try {
                    val method = a2dpProfile!!.javaClass.getMethod("connect", BluetoothDevice::class.java)
                    method.isAccessible = true
                    val success = method.invoke(a2dpProfile, device) as? Boolean ?: false
                    if (success) {
                        notifyAudioDevicesChanged()
                        return true
                    }
                } catch (_: Exception) {}
            }

            // 3. Fallback: launch Bluetooth settings
            openBluetoothSettings()
            return true
        } catch (_: Exception) {
            openBluetoothSettings()
            return false
        }
    }

    @Suppress("MissingPermission")
    private fun disconnectA2dpDevice(address: String): Boolean {
        try {
            val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = btManager?.adapter ?: return false
            if (!BluetoothAdapter.checkBluetoothAddress(address)) return false
            val device = adapter.getRemoteDevice(address) ?: return false

            if (a2dpProfile != null) {
                try {
                    val method = a2dpProfile!!.javaClass.getMethod("disconnect", BluetoothDevice::class.java)
                    method.isAccessible = true
                    val success = method.invoke(a2dpProfile, device) as? Boolean ?: false
                    if (success) {
                        notifyAudioDevicesChanged()
                        return true
                    }
                } catch (_: Exception) {}
            }
            return false
        } catch (_: Exception) {
            return false
        }
    }

    private fun notifyAudioDevicesChanged() {
        runOnUiThread {
            try {
                val devices = getAudioOutputDevices()
                audioEventSink?.success(mapOf("event" to "devices_changed", "devices" to devices))
            } catch (_: Exception) {}
        }
    }

    private fun checkAudioSharingCapability(): Map<String, Any> {
        val isSamsung = Build.MANUFACTURER.contains("samsung", ignoreCase = true)
        var isLeAudioSupported = false

        // Check for LE Audio Broadcast capability on Android 13+ (API 33+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                val adapter = btManager?.adapter
                if (adapter != null) {
                    val method = adapter.javaClass.getMethod("isLeAudioBroadcastSourceSupported")
                    val result = method.invoke(adapter) as? Int
                    // BluetoothStatusCodes.FEATURE_SUPPORTED == 10
                    isLeAudioSupported = (result == 10)
                }
            } catch (_: Exception) {}
        }

        // Also check if any connected output is a BLE headset/speaker/broadcast
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val outputs = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                if (outputs.any { it.type == 26 || it.type == 27 || it.type == 30 }) {
                    isLeAudioSupported = true
                }
            } catch (_: Exception) {}
        }

        val recommendedMode = when {
            isSamsung -> "samsung_dual_audio"
            isLeAudioSupported -> "auracast_broadcast"
            else -> "universal_peer_share"
        }

        return mapOf(
            "canShare" to true,
            "reason" to "multi_mode_ready",
            "androidVersion" to Build.VERSION.SDK_INT,
            "deviceManufacturer" to Build.MANUFACTURER,
            "deviceModel" to Build.MODEL,
            "hasSamsungDualAudio" to isSamsung,
            "hasLeAudioBroadcast" to isLeAudioSupported,
            "recommendedMode" to recommendedMode
        )
    }

    private fun getAudioOutputDevices(): List<Map<String, Any>> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val devices = mutableListOf<Map<String, Any>>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).forEach { device ->
                val typeName = when (device.type) {
                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "bluetooth_a2dp"
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "bluetooth_sco"
                    26 -> "ble_headset" // TYPE_BLE_HEADSET
                    27 -> "ble_speaker" // TYPE_BLE_SPEAKER
                    30 -> "ble_broadcast" // TYPE_BLE_BROADCAST
                    AudioDeviceInfo.TYPE_WIRED_HEADSET, AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "wired_headphones"
                    AudioDeviceInfo.TYPE_USB_HEADSET, AudioDeviceInfo.TYPE_USB_DEVICE -> "usb_audio"
                    AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "builtin_speaker"
                    else -> "audio_device"
                }

                val isBt = device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                        device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                        device.type == 26 || device.type == 27 || device.type == 30

                val pName = device.productName?.toString() ?: ""
                // Only include named audio devices or bluetooth
                if (pName.trim().isNotEmpty() && !pName.equals("Unknown Device", ignoreCase = true)) {
                    devices.add(
                        mapOf(
                            "id" to device.id.toString(),
                            "type" to typeName,
                            "typeCode" to device.type,
                            "productName" to pName,
                            "address" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) device.address ?: "" else ""),
                            "isBluetooth" to isBt,
                            "isConnected" to true
                        )
                    )
                }
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

            val bondedDevices = adapter.bondedDevices ?: return devices
            val audioOutputs = getAudioOutputDevices()

            bondedDevices.forEach { device ->
                val name = device.name ?: ""
                // Filter out unnamed or "Unknown Device" entries
                if (name.trim().isNotEmpty() &&
                    !name.equals("Unknown Device", ignoreCase = true) &&
                    !name.startsWith("Unknown", ignoreCase = true)) {

                    val isConnected = audioOutputs.any { output ->
                        val addr = output["address"] as? String ?: ""
                        val pName = output["productName"] as? String ?: ""
                        (addr.isNotEmpty() && addr.equals(device.address, ignoreCase = true)) ||
                                (pName.isNotEmpty() && pName.equals(device.name, ignoreCase = true))
                    }

                    devices.add(
                        mapOf(
                            "address" to device.address,
                            "name" to name,
                            "type" to device.type,
                            "bondState" to device.bondState,
                            "isConnected" to isConnected
                        )
                    )
                }
            }
        } catch (_: Exception) {}
        return devices
    }

    @Suppress("MissingPermission")
    private fun getBondedAudioDevices(): List<Map<String, Any>> {
        val devices = mutableListOf<Map<String, Any>>()
        try {
            val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = btManager?.adapter ?: return devices
            val audioOutputs = getAudioOutputDevices()

            adapter.bondedDevices?.forEach { device ->
                val name = device.name ?: ""
                // Filter out unnamed or "Unknown Device" entries
                if (name.trim().isNotEmpty() &&
                    !name.equals("Unknown Device", ignoreCase = true) &&
                    !name.startsWith("Unknown", ignoreCase = true)) {

                    val isConnected = audioOutputs.any { output ->
                        val addr = output["address"] as? String ?: ""
                        val pName = output["productName"] as? String ?: ""
                        (addr.isNotEmpty() && addr.equals(device.address, ignoreCase = true)) ||
                                (pName.isNotEmpty() && pName.equals(device.name, ignoreCase = true))
                    }

                    devices.add(
                        mapOf(
                            "address" to device.address,
                            "name" to name,
                            "type" to device.type,
                            "isConnected" to isConnected
                        )
                    )
                }
            }
        } catch (_: Exception) {}
        return devices
    }

    /**
     * Real native audio playback engine using AudioTrack.
     * Generates a stereo harmonic soundscape so when "Share Audio" is active,
     * actual audio streams continuously through connected Bluetooth outputs.
     */
    private fun startNativeAudioPlayback() {
        if (isPlayingAudio) return
        isPlayingAudio = true

        playbackThread = thread(start = true, isDaemon = true, name = "SoundShareAudioPlayback") {
            val sampleRate = 44100
            val channelConfig = AudioFormat.CHANNEL_OUT_STEREO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val minBufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat)
            val bufferSize = (minBufferSize * 2).coerceAtLeast(4096)

            try {
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val currentVol = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                if (currentVol == 0 && maxVol > 0) {
                    audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, (maxVol * 0.6).toInt(), 0)
                }

                val btOutputs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).filter {
                        it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                        it.type == 26 || it.type == 27 || it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
                    }
                } else emptyList()

                // Multi-headphone routing: Create dedicated AudioTrack per Bluetooth device
                if (btOutputs.isNotEmpty()) {
                    for (dev in btOutputs) {
                        try {
                            val track = AudioTrack.Builder()
                                .setAudioAttributes(
                                    AudioAttributes.Builder()
                                        .setUsage(AudioAttributes.USAGE_MEDIA)
                                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                        .build()
                                )
                                .setAudioFormat(
                                    AudioFormat.Builder()
                                        .setEncoding(audioFormat)
                                        .setSampleRate(sampleRate)
                                        .setChannelMask(channelConfig)
                                        .build()
                                )
                                .setBufferSizeInBytes(bufferSize)
                                .setTransferMode(AudioTrack.MODE_STREAM)
                                .build()
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                track.preferredDevice = dev
                            }
                            track.play()
                            audioTracks.add(track)
                        } catch (_: Exception) {}
                    }
                }

                // Fallback default track if no specific BT tracks were created
                if (audioTracks.isEmpty()) {
                    try {
                        val defaultTrack = AudioTrack.Builder()
                            .setAudioAttributes(
                                AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_MEDIA)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                    .build()
                            )
                            .setAudioFormat(
                                AudioFormat.Builder()
                                    .setEncoding(audioFormat)
                                    .setSampleRate(sampleRate)
                                    .setChannelMask(channelConfig)
                                    .build()
                            )
                            .setBufferSizeInBytes(bufferSize)
                            .setTransferMode(AudioTrack.MODE_STREAM)
                            .build()
                        defaultTrack.play()
                        audioTracks.add(defaultTrack)
                    } catch (_: Exception) {}
                }

                val buffer = ShortArray(bufferSize / 2)
                var phaseL = 0.0
                var phaseR = 0.0
                var sampleIndex = 0L

                while (isPlayingAudio) {
                    val timeSec = sampleIndex.toDouble() / sampleRate
                    // Harmonic pulsing chord: Root (220Hz / A3), Fifth (330Hz / E4), Octave (440Hz / A4)
                    val beatPulse = (sin(2.0 * Math.PI * 1.5 * timeSec) * 0.5 + 0.5) // 1.5 Hz pulse
                    val freqL = 220.0
                    val freqR = 330.0

                    for (i in 0 until buffer.size step 2) {
                        phaseL += 2.0 * Math.PI * freqL / sampleRate
                        phaseR += 2.0 * Math.PI * freqR / sampleRate
                        if (phaseL > 2.0 * Math.PI) phaseL -= 2.0 * Math.PI
                        if (phaseR > 2.0 * Math.PI) phaseR -= 2.0 * Math.PI

                        val amp = 0.45 * (0.6 + 0.4 * beatPulse)
                        val sampleL = (sin(phaseL) * amp * Short.MAX_VALUE).toInt().toShort()
                        val sampleR = (sin(phaseR) * amp * Short.MAX_VALUE).toInt().toShort()

                        buffer[i] = sampleL
                        buffer[i + 1] = sampleR
                    }
                    sampleIndex += buffer.size / 2

                    // Stream to all connected headphone tracks synchronously
                    for (t in audioTracks) {
                        try {
                            t.write(buffer, 0, buffer.size)
                        } catch (_: Exception) {}
                    }
                }

                for (t in audioTracks) {
                    try {
                        t.stop()
                        t.release()
                    } catch (_: Exception) {}
                }
                audioTracks.clear()
            } catch (_: Exception) {
            } finally {
                audioTracks.clear()
                isPlayingAudio = false
            }
        }
    }

    private fun setDeviceVolume(address: String, volume: Float) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            var matched = false
            audioTracks.forEach { track ->
                val trackAddr = track.preferredDevice?.address ?: ""
                val trackName = track.preferredDevice?.productName?.toString() ?: ""
                if ((trackAddr.isNotEmpty() && trackAddr.equals(address, ignoreCase = true)) ||
                    (trackName.isNotEmpty() && trackName.equals(address, ignoreCase = true))) {
                    try {
                        track.setVolume(volume.coerceIn(0f, 1f))
                        matched = true
                    } catch (_: Exception) {}
                }
            }
            // If no specific track matched or single device fallback, apply to all active tracks
            if (!matched) {
                audioTracks.forEach { track ->
                    try {
                        track.setVolume(volume.coerceIn(0f, 1f))
                    } catch (_: Exception) {}
                }
            }
        }
    }

    private fun stopNativeAudioPlayback() {
        isPlayingAudio = false
        playbackThread?.interrupt()
        playbackThread = null
        for (t in audioTracks) {
            try {
                t.stop()
                t.release()
            } catch (_: Exception) {}
        }
        audioTracks.clear()
    }

    override fun onDestroy() {
        stopNativeAudioPlayback()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && audioDeviceCallback != null) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            audioManager?.unregisterAudioDeviceCallback(audioDeviceCallback)
        }
        if (a2dpProfile != null) {
            try {
                val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                btManager?.adapter?.closeProfileProxy(BluetoothProfile.A2DP, a2dpProfile)
            } catch (_: Exception) {}
            a2dpProfile = null
        }
        super.onDestroy()
    }
}
