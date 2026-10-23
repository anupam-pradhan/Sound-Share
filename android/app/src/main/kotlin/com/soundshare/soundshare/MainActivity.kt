package com.soundshare.soundshare

import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.projection.MediaProjectionConfig
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

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

    // Playback capture for Wi-Fi sharing: PCM goes to Dart over this channel
    private val pcmChannel = "com.soundshare/pcm"
    private var pcmSink: EventChannel.EventSink? = null
    private var pendingCaptureResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private companion object {
        const val TAG = "SoundShare"
        const val REQUEST_CAPTURE_CONSENT = 4101
        const val REQUEST_RECORD_AUDIO = 4102
    }

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

        // Captured audio (raw 16-bit stereo PCM chunks)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, pcmChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    pcmSink = events
                }

                override fun onCancel(arguments: Any?) {
                    pcmSink = null
                }
            })
        AudioShareForegroundService.callbacks = captureCallbacks

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
                    "startCapture" -> {
                        startCapture(result)
                    }
                    "stopCapture" -> {
                        AudioShareForegroundService.stopService(this)
                        result.success(true)
                    }
                    "setDeviceVolume" -> {
                        val volume = call.argument<Double>("volume") ?: 1.0
                        setMediaVolume(volume.toFloat())
                        result.success(true)
                    }
                    "isAudioPlaying" -> {
                        result.success(
                            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                                PlaybackCaptureEngine.isRunning
                        )
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

    // ──────────────────────────────────────────────
    // Playback capture (Wi-Fi sharing)
    // ──────────────────────────────────────────────

    private val captureCallbacks = object : AudioShareForegroundService.CaptureCallbacks {
        override fun onCaptureStarted(sampleRate: Int) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                PlaybackCaptureEngine.listener = PlaybackCaptureEngine.Listener { chunk, _ ->
                    // EventSink must be used on the main thread
                    mainHandler.post { pcmSink?.success(chunk) }
                }
            }
            completeCapture(mapOf("ok" to true, "sampleRate" to sampleRate))
        }

        // The PCM stream itself reports the end, so Dart needs only one subscription
        override fun onCaptureStopped() {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) PlaybackCaptureEngine.listener = null
            pcmSink?.endOfStream()
        }

        override fun onCaptureFailed(reason: String) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) PlaybackCaptureEngine.listener = null
            if (!completeCapture(mapOf("ok" to false, "reason" to reason))) {
                pcmSink?.error("capture_failed", reason, null)
            }
        }
    }

    /** Replies to a pending startCapture call; false when none was waiting. */
    private fun completeCapture(reply: Map<String, Any>): Boolean {
        val pending = pendingCaptureResult ?: return false
        pendingCaptureResult = null
        pending.success(reply)
        return true
    }

    /** Asks for microphone-class permission, then Android's screen-audio consent. */
    private fun startCapture(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(mapOf("ok" to false, "reason" to "Wi-Fi sharing needs Android 10 or newer."))
            return
        }
        if (pendingCaptureResult != null) {
            result.success(mapOf("ok" to false, "reason" to "Already starting."))
            return
        }
        pendingCaptureResult = result
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_RECORD_AUDIO)
            return
        }
        requestCaptureConsent()
    }

    private fun requestCaptureConsent() {
        val mpm = getSystemService(MediaProjectionManager::class.java)
        if (mpm == null) {
            completeCapture(mapOf("ok" to false, "reason" to "Audio capture is not available on this phone."))
            return
        }
        // Android 14+: offer only "entire screen"; the single-app mode cannot capture audio
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            mpm.createScreenCaptureIntent(MediaProjectionConfig.createConfigForDefaultDisplay())
        } else {
            mpm.createScreenCaptureIntent()
        }
        try {
            startActivityForResult(intent, REQUEST_CAPTURE_CONSENT)
        } catch (e: Exception) {
            Log.e(TAG, "Capture consent dialog failed", e)
            completeCapture(mapOf("ok" to false, "reason" to "Could not open Android's sharing dialog."))
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_RECORD_AUDIO) return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            requestCaptureConsent()
        } else {
            completeCapture(
                mapOf("ok" to false, "reason" to "Allow audio access so SoundShare can share what's playing.")
            )
        }
    }

    @Deprecated("Activity result API is not used by FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_CAPTURE_CONSENT) return
        if (resultCode != Activity.RESULT_OK || data == null) {
            completeCapture(mapOf("ok" to false, "reason" to "Sharing was cancelled."))
            return
        }
        // The service replies through captureCallbacks
        AudioShareForegroundService.startCapture(this, resultCode, data)
    }

    private fun setMediaVolume(volume: Float) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        try {
            audioManager.setStreamVolume(
                AudioManager.STREAM_MUSIC,
                (volume.coerceIn(0f, 1f) * max).toInt(),
                0
            )
        } catch (e: SecurityException) {
            Log.w(TAG, "Volume change blocked (Do Not Disturb): ${e.message}")
        }
    }

    override fun onDestroy() {
        // The Wi-Fi server lives in this Flutter engine, so capture ends with it
        if (AudioShareForegroundService.callbacks === captureCallbacks) {
            AudioShareForegroundService.callbacks = null
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) PlaybackCaptureEngine.listener = null
        AudioShareForegroundService.stopService(this)
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
