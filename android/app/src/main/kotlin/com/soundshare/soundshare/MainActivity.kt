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
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.AudioTrack
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.app.Activity
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.Collections
import android.os.Process
import kotlin.concurrent.thread
import kotlin.math.exp
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
    private var audioFocusRequest: Any? = null

    // Universal Android 10+ internal audio playback capture & dual-device mirroring
    private val REQUEST_CODE_MEDIA_PROJECTION = 2001
    private var mediaProjection: MediaProjection? = null
    private var audioRecord: AudioRecord? = null
    private var captureThread: Thread? = null
    private var isCapturingAudio = false

    // Real-time HTTP PCM/WAV audio stream server for universal peer devices
    private var liveStreamServer: ServerSocket? = null
    private val liveStreamClients = Collections.synchronizedList(mutableListOf<Socket>())
    private var isStreamingServerRunning = false

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
                    "playTestChime" -> {
                        playDualAudioChime()
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
                    "openDeveloperSettings" -> {
                        result.success(openDeveloperSettings())
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
            // 1. Samsung One UI specific media output intents
            if (Build.MANUFACTURER.contains("samsung", ignoreCase = true)) {
                val samsungIntents = listOf(
                    Intent("com.samsung.android.setting.MEDIA_OUTPUT"),
                    Intent("com.samsung.android.app.soundalive.ACTION_DUAL_AUDIO"),
                    Intent().setClassName("com.samsung.android.setting", "com.samsung.android.setting.mediaoutput.MediaOutputActivity"),
                    Intent().setClassName("com.android.settings", "com.samsung.android.settings.bluetooth.CheckableMediaDeviceActivity")
                )
                for (sIntent in samsungIntents) {
                    try {
                        sIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(sIntent)
                        return true
                    } catch (_: Exception) {}
                }
            }

            // 2. Android 10+ (API 29+) Media Output Panel
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    val intent = Intent("android.settings.panel.action.MEDIA_OUTPUT").apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        putExtra("com.android.settings.panel.extra.PACKAGE_NAME", packageName)
                        putExtra("android.provider.extra.PACKAGE_NAME", packageName)
                    }
                    startActivity(intent)
                    return true
                } catch (_: Exception) {}
            }

            // 3. Fallback: Bluetooth settings
            openBluetoothSettings()
        } catch (_: Exception) {
            openBluetoothSettings()
        }
    }

    private fun openDeveloperSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                val intent = Intent(Settings.ACTION_DEVICE_INFO_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                true
            } catch (_: Exception) {
                openBluetoothSettings()
            }
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
            else -> "universal_peer_share" // Guaranteed zero-config sharing on all non-Samsung phones without Developer Mode
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

    /**
     * Normalizes device names by removing channel suffixes (e.g. "(L)", "(R)", " Left", " Right")
     * so that TWS earbuds are not displayed or counted twice.
     */
    private fun normalizeAudioDeviceName(name: String): String {
        return name
            .replace(Regex("(?i)\\s*\\((?:left|right|l|r)\\)"), "")
            .replace(Regex("(?i)[_\\-](?:left|right|l|r)$"), "")
            .replace(Regex("(?i)\\s+(?:left|right|l|r)$"), "")
            .trim()
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
                val devAddr = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) device.address ?: "" else ""

                // Only include named audio devices or bluetooth
                if (pName.trim().isNotEmpty() &&
                    !pName.equals("Unknown Device", ignoreCase = true) &&
                    !pName.startsWith("Unknown", ignoreCase = true)) {

                    // Deduplicate so Left & Right earbuds of the same pair don't show twice
                    val isDuplicate = isBt && devices.any { existing ->
                        val exAddr = existing["address"] as? String ?: ""
                        val exName = existing["productName"] as? String ?: ""
                        (devAddr.isNotEmpty() && exAddr.isNotEmpty() && exAddr.equals(devAddr, ignoreCase = true)) ||
                                normalizeAudioDeviceName(exName).equals(normalizeAudioDeviceName(pName), ignoreCase = true)
                    }

                    if (!isDuplicate) {
                        devices.add(
                            mapOf(
                                "id" to device.id.toString(),
                                "type" to typeName,
                                "typeCode" to device.type,
                                "productName" to pName,
                                "address" to devAddr,
                                "isBluetooth" to isBt,
                                "isConnected" to true
                            )
                        )
                    }
                }
            }
        }

        // Cross-reference with A2DP profile proxy to detect second connected Bluetooth headphone
        try {
            a2dpProfile?.connectedDevices?.forEach { btDev ->
                val name = btDev.name ?: ""
                val addr = btDev.address ?: ""
                if (name.trim().isNotEmpty() &&
                    !name.equals("Unknown Device", ignoreCase = true) &&
                    !name.startsWith("Unknown", ignoreCase = true)) {

                    val alreadyAdded = devices.any {
                        val dAddr = it["address"] as? String ?: ""
                        val dName = it["productName"] as? String ?: ""
                        (addr.isNotEmpty() && dAddr.equals(addr, ignoreCase = true)) ||
                                normalizeAudioDeviceName(dName).equals(normalizeAudioDeviceName(name), ignoreCase = true)
                    }
                    if (!alreadyAdded) {
                        devices.add(
                            mapOf(
                                "id" to if (addr.isNotEmpty()) addr else name,
                                "type" to "bluetooth_a2dp",
                                "typeCode" to AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                                "productName" to name,
                                "address" to addr,
                                "isBluetooth" to true,
                                "isConnected" to true
                            )
                        )
                    }
                }
            }
        } catch (_: Exception) {}

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
     * Plays a pleasant, gentle 0.35-second dual confirmation chime through all connected
     * Bluetooth audio outputs so the user can verify both headphones are connected and responsive.
     * Crucially, this does NOT run an infinite loop and does NOT lock audio focus, ensuring
     * external music apps (Spotify, YouTube, media players) can stream cleanly to both outputs.
     */
    private fun playDualAudioChime() {
        thread(start = true, isDaemon = true, name = "SoundShareChime") {
            val sampleRate = 44100
            val channelConfig = AudioFormat.CHANNEL_OUT_STEREO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val durationSec = 0.35
            val totalFrames = (sampleRate * durationSec).toInt()
            val totalShorts = totalFrames * 2
            val chimeBuffer = ShortArray(totalShorts)

            // Two-tone ascending chime: Note 1 (C5 = 523.25 Hz, 0-140ms), Note 2 (E5 = 659.25 Hz, 140-350ms)
            val splitFrame = (sampleRate * 0.14).toInt()
            var phase1 = 0.0
            var phase2 = 0.0

            for (frame in 0 until totalFrames) {
                val freq = if (frame < splitFrame) 523.25 else 659.25
                val currentPhase = if (frame < splitFrame) {
                    phase1 += 2.0 * Math.PI * freq / sampleRate
                    if (phase1 > 2.0 * Math.PI) phase1 -= 2.0 * Math.PI
                    phase1
                } else {
                    phase2 += 2.0 * Math.PI * freq / sampleRate
                    if (phase2 > 2.0 * Math.PI) phase2 -= 2.0 * Math.PI
                    phase2
                }

                // Envelope: Smooth gentle attack, exponential decay to zero
                val env = if (frame < splitFrame) {
                    val note1Rel = frame.toDouble() / splitFrame
                    val attack = (frame.toDouble() / (sampleRate * 0.01)).coerceIn(0.0, 1.0)
                    attack * (1.0 - note1Rel * 0.35)
                } else {
                    val note2Frame = frame - splitFrame
                    val note2Len = totalFrames - splitFrame
                    val attack = (note2Frame.toDouble() / (sampleRate * 0.008)).coerceIn(0.0, 1.0)
                    val decay = exp(-4.5 * (note2Frame.toDouble() / note2Len))
                    attack * decay
                }

                val sampleVal = (sin(currentPhase) * env * 0.65 * Short.MAX_VALUE).toInt().toShort()
                val idx = frame * 2
                chimeBuffer[idx] = sampleVal     // Left
                chimeBuffer[idx + 1] = sampleVal // Right
            }

            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val minBufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat)
            val bufferSize = (minBufferSize * 2).coerceAtLeast(totalShorts * 2)

            // Find distinct connected Bluetooth outputs (deduplicating Left/Right earbuds)
            val allOutputs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).filter {
                    it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                    it.type == 26 || it.type == 27 || it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
                }
            } else emptyList()

            val distinctOutputs = mutableListOf<AudioDeviceInfo>()
            allOutputs.forEach { dev ->
                val pName = dev.productName?.toString() ?: ""
                val isDup = distinctOutputs.any {
                    val exName = it.productName?.toString() ?: ""
                    normalizeAudioDeviceName(exName).equals(normalizeAudioDeviceName(pName), ignoreCase = true)
                }
                if (!isDup) {
                    distinctOutputs.add(dev)
                }
            }

            val tempTracks = mutableListOf<AudioTrack>()
            try {
                // Request transient ducking focus for the brief chime only
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val afr = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                        .setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_MEDIA)
                                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                .build()
                        )
                        .build()
                    audioManager.requestAudioFocus(afr)
                }

                // Track 1 (Primary route)
                val primaryTrack = AudioTrack.Builder()
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

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && distinctOutputs.isNotEmpty()) {
                    try {
                        primaryTrack.preferredDevice = distinctOutputs[0]
                    } catch (_: Exception) {}
                }
                try {
                    primaryTrack.play()
                    tempTracks.add(primaryTrack)
                } catch (_: Exception) {}

                // Track 2 (Second distinct device if available)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && distinctOutputs.size >= 2) {
                    try {
                        val secondaryTrack = AudioTrack.Builder()
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

                        secondaryTrack.preferredDevice = distinctOutputs[1]
                        secondaryTrack.play()
                        tempTracks.add(secondaryTrack)
                    } catch (_: Exception) {}
                }

                // Write chime once to all active tracks
                for (track in tempTracks) {
                    try {
                        track.write(chimeBuffer, 0, chimeBuffer.size)
                    } catch (_: Exception) {}
                }

                // Allow 380ms for hardware buffer to complete audio emission
                Thread.sleep(380)

            } catch (_: Exception) {
            } finally {
                // Immediately release tracks and abandon audio focus so Spotify, YouTube, and music players stream freely
                for (track in tempTracks) {
                    try {
                        track.stop()
                        track.release()
                    } catch (_: Exception) {}
                }
                tempTracks.clear()

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val afr = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK).build()
                        audioManager.abandonAudioFocusRequest(afr)
                    } else {
                        @Suppress("DEPRECATION")
                        audioManager.abandonAudioFocus(null)
                    }
                } catch (_: Exception) {}
            }
        }
    }

    /**
     * Starts native audio sharing mode.
     * 1. Plays a brief dual startup confirmation chime (0.35s) on both connected devices.
     * 2. On Android 10+ (API 29+), launches AudioPlaybackCapture so that music played from
     *    ANY app (Spotify, YouTube, media players) is captured and mirrored to both headphones
     *    synchronously across ALL phone brands (Samsung, Xiaomi, Oppo, Vivo, OnePlus, Pixel, Moto).
     */
    private fun startNativeAudioPlayback() {
        if (isPlayingAudio) return
        isPlayingAudio = true

        // Play brief dual confirmation chime so user gets immediate acoustic confirmation
        playDualAudioChime()

        // Universal real-time audio capture for Android 10+ across all phone brands
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val mpManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
                if (mpManager != null) {
                    startActivityForResult(mpManager.createScreenCaptureIntent(), REQUEST_CODE_MEDIA_PROJECTION)
                }
            } catch (_: Exception) {}
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_MEDIA_PROJECTION) {
            if (resultCode == Activity.RESULT_OK && data != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    val mpManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
                    val mp = mpManager?.getMediaProjection(resultCode, data)
                    if (mp != null) {
                        mediaProjection = mp
                        startRealtimeAudioCapture(mp)
                    }
                } catch (_: Exception) {}
            }
        }
    }

    private fun startRealtimeAudioCapture(mp: MediaProjection) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        stopAudioCapture()
        isCapturingAudio = true

        // Start local HTTP audio streaming server so any connected peer phone/browser receives the live audio stream
        startLiveAudioStreamServer(8889)

        captureThread = thread(start = true, isDaemon = true, name = "SoundShareCapture") {
            // Wait 400ms for startup chime to finish emitting
            try { Thread.sleep(400) } catch (_: Exception) {}

            val sampleRate = 44100
            val channelConfig = AudioFormat.CHANNEL_IN_STEREO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val minRecordBuf = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
            val recordBufSize = (minRecordBuf * 2).coerceAtLeast(4096)

            val minTrackBuf = AudioTrack.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_OUT_STEREO, audioFormat)
            val trackBufSize = (minTrackBuf * 2).coerceAtLeast(4096)

            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

            // Find distinct outputs across Bluetooth, Wired, USB-C, and BLE
            val allOutputs = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).filter {
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                it.type == 26 || it.type == 27 || it.type == 30 ||
                it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                it.type == AudioDeviceInfo.TYPE_USB_HEADSET ||
                it.type == AudioDeviceInfo.TYPE_USB_DEVICE ||
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
            }
            val distinctOutputs = mutableListOf<AudioDeviceInfo>()
            allOutputs.forEach { dev ->
                val pName = dev.productName?.toString() ?: ""
                val isDup = distinctOutputs.any {
                    val exName = it.productName?.toString() ?: ""
                    normalizeAudioDeviceName(exName).equals(normalizeAudioDeviceName(pName), ignoreCase = true)
                }
                if (!isDup) distinctOutputs.add(dev)
            }

            try {
                // EXCLUDE own app UID to avoid infinite audio capture feedback/looping
                val config = AudioPlaybackCaptureConfiguration.Builder(mp)
                    .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                    .addMatchingUsage(AudioAttributes.USAGE_GAME)
                    .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
                    .excludeUid(Process.myUid())
                    .build()

                val record = AudioRecord.Builder()
                    .setAudioPlaybackCaptureConfig(config)
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(audioFormat)
                            .setSampleRate(sampleRate)
                            .setChannelMask(channelConfig)
                            .build()
                    )
                    .setBufferSizeInBytes(recordBufSize)
                    .build()

                audioRecord = record

                // Create secondary track specifically routed to Device 2 if 2 distinct hardware outputs exist
                val secTrack = AudioTrack.Builder()
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
                            .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                            .build()
                    )
                    .setBufferSizeInBytes(trackBufSize)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()

                if (distinctOutputs.size >= 2) {
                    try {
                        secTrack.preferredDevice = distinctOutputs[1]
                    } catch (_: Exception) {}
                    try {
                        secTrack.play()
                        synchronized(audioTracks) {
                            audioTracks.clear()
                            audioTracks.add(secTrack)
                        }
                    } catch (_: Exception) {}
                }

                record.startRecording()

                val pcmBuffer = ShortArray(recordBufSize / 2)

                while (isPlayingAudio && isCapturingAudio) {
                    val readCount = record.read(pcmBuffer, 0, pcmBuffer.size)
                    if (readCount > 0) {
                        // 1. Write to local secondary output if available (e.g. wired/USB or multi-sink BT)
                        if (distinctOutputs.size >= 2) {
                            try {
                                secTrack.write(pcmBuffer, 0, readCount)
                            } catch (_: Exception) {}
                        }
                        // 2. Broadcast PCM live to all connected peer listeners over Wi-Fi / Hotspot
                        broadcastPcmToLiveClients(pcmBuffer, readCount)
                    }
                }

                try {
                    secTrack.stop()
                    secTrack.release()
                } catch (_: Exception) {}
                try {
                    record.stop()
                    record.release()
                } catch (_: Exception) {}

            } catch (_: Exception) {
            } finally {
                synchronized(audioTracks) {
                    audioTracks.clear()
                }
            }
        }
    }

    private fun startLiveAudioStreamServer(port: Int = 8889) {
        stopLiveAudioStreamServer()
        thread(start = true, isDaemon = true, name = "SoundShareStreamServer") {
            try {
                val server = ServerSocket()
                server.reuseAddress = true
                server.bind(InetSocketAddress("0.0.0.0", port))
                liveStreamServer = server
                isStreamingServerRunning = true

                while (isStreamingServerRunning && !server.isClosed) {
                    try {
                        val client = server.accept()
                        thread(start = true, isDaemon = true, name = "SoundShareStreamClient") {
                            handleLiveStreamClient(client)
                        }
                    } catch (_: Exception) {}
                }
            } catch (_: Exception) {}
        }
    }

    private fun handleLiveStreamClient(client: Socket) {
        try {
            client.soTimeout = 0
            client.tcpNoDelay = true
            val reader = BufferedReader(InputStreamReader(client.getInputStream()))
            // Consume request headers
            var line: String? = reader.readLine()
            while (!line.isNullOrEmpty()) {
                line = reader.readLine()
            }

            val out = client.getOutputStream()
            val header = "HTTP/1.1 200 OK\r\n" +
                    "Content-Type: audio/wav\r\n" +
                    "Access-Control-Allow-Origin: *\r\n" +
                    "Cache-Control: no-cache, no-store\r\n" +
                    "Connection: close\r\n\r\n"
            out.write(header.toByteArray(Charsets.US_ASCII))

            // Standard 44-byte WAV header for indefinite streaming (44.1kHz, 16-bit, Stereo)
            val wavHeader = createWavHeader(sampleRate = 44100, channels = 2, bitsPerSample = 16)
            out.write(wavHeader)
            out.flush()

            liveStreamClients.add(client)
        } catch (_: Exception) {
            try { client.close() } catch (_: Exception) {}
        }
    }

    private fun createWavHeader(sampleRate: Int, channels: Int, bitsPerSample: Int): ByteArray {
        val byteRate = sampleRate * channels * bitsPerSample / 8
        val blockAlign = channels * bitsPerSample / 8
        val totalDataLen = 0x7FFFFFF0
        val totalAudioLen = totalDataLen + 36

        val header = ByteArray(44)
        header[0] = 'R'.code.toByte(); header[1] = 'I'.code.toByte(); header[2] = 'F'.code.toByte(); header[3] = 'F'.code.toByte()
        header[4] = (totalAudioLen and 0xff).toByte()
        header[5] = ((totalAudioLen shr 8) and 0xff).toByte()
        header[6] = ((totalAudioLen shr 16) and 0xff).toByte()
        header[7] = ((totalAudioLen shr 24) and 0xff).toByte()
        header[8] = 'W'.code.toByte(); header[9] = 'A'.code.toByte(); header[10] = 'V'.code.toByte(); header[11] = 'E'.code.toByte()
        header[12] = 'f'.code.toByte(); header[13] = 'm'.code.toByte(); header[14] = 't'.code.toByte(); header[15] = ' '.code.toByte()
        header[16] = 16; header[17] = 0; header[18] = 0; header[19] = 0 // 16 for PCM
        header[20] = 1; header[21] = 0 // format = 1 (PCM)
        header[22] = channels.toByte(); header[23] = 0
        header[24] = (sampleRate and 0xff).toByte()
        header[25] = ((sampleRate shr 8) and 0xff).toByte()
        header[26] = ((sampleRate shr 16) and 0xff).toByte()
        header[27] = ((sampleRate shr 24) and 0xff).toByte()
        header[28] = (byteRate and 0xff).toByte()
        header[29] = ((byteRate shr 8) and 0xff).toByte()
        header[30] = ((byteRate shr 16) and 0xff).toByte()
        header[31] = ((byteRate shr 24) and 0xff).toByte()
        header[32] = blockAlign.toByte(); header[33] = 0
        header[34] = bitsPerSample.toByte(); header[35] = 0
        header[36] = 'd'.code.toByte(); header[37] = 'a'.code.toByte(); header[38] = 't'.code.toByte(); header[39] = 'a'.code.toByte()
        header[40] = (totalDataLen and 0xff).toByte()
        header[41] = ((totalDataLen shr 8) and 0xff).toByte()
        header[42] = ((totalDataLen shr 16) and 0xff).toByte()
        header[43] = ((totalDataLen shr 24) and 0xff).toByte()
        return header
    }

    private fun broadcastPcmToLiveClients(pcmBuffer: ShortArray, readCount: Int) {
        if (liveStreamClients.isEmpty() || readCount <= 0) return
        val byteBuf = ByteArray(readCount * 2)
        for (i in 0 until readCount) {
            val s = pcmBuffer[i].toInt()
            byteBuf[i * 2] = (s and 0xFF).toByte()
            byteBuf[i * 2 + 1] = ((s shr 8) and 0xFF).toByte()
        }

        val deadClients = mutableListOf<Socket>()
        synchronized(liveStreamClients) {
            for (client in liveStreamClients) {
                try {
                    client.getOutputStream().write(byteBuf)
                } catch (_: Exception) {
                    deadClients.add(client)
                }
            }
            if (deadClients.isNotEmpty()) {
                liveStreamClients.removeAll(deadClients)
                deadClients.forEach { try { it.close() } catch (_: Exception) {} }
            }
        }
    }

    private fun stopLiveAudioStreamServer() {
        isStreamingServerRunning = false
        try {
            liveStreamServer?.close()
        } catch (_: Exception) {}
        liveStreamServer = null
        synchronized(liveStreamClients) {
            for (client in liveStreamClients) {
                try { client.close() } catch (_: Exception) {}
            }
            liveStreamClients.clear()
        }
    }

    private fun stopAudioCapture() {
        isCapturingAudio = false
        stopLiveAudioStreamServer()
        captureThread?.interrupt()
        captureThread = null
        try {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
        } catch (_: Exception) {}
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                mediaProjection?.stop()
            }
            mediaProjection = null
        } catch (_: Exception) {}
    }

    private fun stopNativeAudioPlayback() {
        isPlayingAudio = false
        stopAudioCapture()
        playbackThread?.interrupt()
        playbackThread = null
        synchronized(audioTracks) {
            for (t in audioTracks) {
                try {
                    t.stop()
                    t.release()
                } catch (_: Exception) {}
            }
            audioTracks.clear()
        }
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && audioFocusRequest is AudioFocusRequest) {
                audioManager.abandonAudioFocusRequest(audioFocusRequest as AudioFocusRequest)
                audioFocusRequest = null
            } else {
                @Suppress("DEPRECATION")
                audioManager.abandonAudioFocus(null)
            }
        } catch (_: Exception) {}
    }

    private fun setDeviceVolume(address: String, volume: Float) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val targetVol = (volume.coerceIn(0f, 1f) * maxVol).toInt()
        try {
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVol, 0)
        } catch (_: Exception) {}

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
            if (!matched) {
                audioTracks.forEach { track ->
                    try {
                        track.setVolume(volume.coerceIn(0f, 1f))
                    } catch (_: Exception) {}
                }
            }
        }
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
