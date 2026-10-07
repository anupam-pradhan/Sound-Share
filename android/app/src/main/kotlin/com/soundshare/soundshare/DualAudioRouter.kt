package com.soundshare.soundshare

import android.bluetooth.BluetoothDevice
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build

/**
 * Decides how two headphones can really be driven on this phone.
 *
 * Stock Android keeps only ONE classic A2DP headset active at a time; the second
 * connected headset never appears as an [AudioDeviceInfo], so no app can route to it.
 * Dual playback is only possible when the platform exposes two distinct physical
 * outputs (BT + wired/USB, vendor multi-A2DP), or through system features
 * (Samsung Dual Audio, Android 15+/16 LE Audio sharing).
 */
object DualAudioRouter {

    private const val TYPE_BLE_HEADSET = 26
    private const val TYPE_BLE_SPEAKER = 27
    private const val TYPE_BLE_BROADCAST = 30

    const val MODE_APP_MIRRORING = "app_mirroring"
    const val MODE_SAMSUNG_DUAL_AUDIO = "samsung_dual_audio"
    const val MODE_LE_AUDIO_SHARING = "le_audio_sharing"
    const val MODE_SINGLE_ACTIVE_ONLY = "single_active_only"
    const val MODE_NEED_SECOND_DEVICE = "need_second_device"

    fun isBluetoothMediaType(type: Int): Boolean =
        type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
            type == TYPE_BLE_HEADSET ||
            type == TYPE_BLE_SPEAKER ||
            type == TYPE_BLE_BROADCAST

    private fun isLeAudioType(type: Int): Boolean =
        type == TYPE_BLE_HEADSET || type == TYPE_BLE_SPEAKER || type == TYPE_BLE_BROADCAST

    private fun isWiredOrUsbType(type: Int): Boolean =
        type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
            type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
            type == AudioDeviceInfo.TYPE_USB_HEADSET ||
            type == AudioDeviceInfo.TYPE_USB_DEVICE

    fun addressOf(device: AudioDeviceInfo): String =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) device.address.orEmpty() else ""

    private fun normalizedName(name: String): String = name
        .replace(Regex("(?i)\\s*\\((?:left|right|l|r)\\)"), "")
        .replace(Regex("(?i)[_\\-](?:left|right|l|r)$"), "")
        .replace(Regex("(?i)\\s+(?:left|right|l|r)$"), "")
        .trim()
        .lowercase()

    /** True when both entries are the same physical headphone (or the same LE Audio earbud pair). */
    fun isSamePhysicalDevice(a: AudioDeviceInfo, b: AudioDeviceInfo): Boolean {
        if (a.id == b.id) return true
        val addrA = addressOf(a)
        val addrB = addressOf(b)
        if (addrA.isNotEmpty() && addrA.equals(addrB, ignoreCase = true)) return true
        // LE Audio earbuds report left/right as separate devices with different addresses
        val bothLe = isLeAudioType(a.type) && isLeAudioType(b.type)
        return bothLe && normalizedName(a.productName?.toString().orEmpty()) ==
            normalizedName(b.productName?.toString().orEmpty())
    }

    /**
     * Media-capable outputs, one entry per physical device. SCO is excluded because it is
     * the call channel of an A2DP headset that is already listed; routing music to it
     * would steal the link from A2DP.
     */
    fun physicalMediaOutputs(audioManager: AudioManager): List<AudioDeviceInfo> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return emptyList()
        return audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            .filter { isBluetoothMediaType(it.type) || isWiredOrUsbType(it.type) }
            .fold(emptyList()) { acc, dev ->
                if (acc.any { isSamePhysicalDevice(it, dev) }) acc else acc + dev
            }
    }

    /** Picks an output that is a different physical device from [primary], if one exists. */
    fun pickSecondaryOutput(
        outputs: List<AudioDeviceInfo>,
        primary: AudioDeviceInfo?
    ): AudioDeviceInfo? {
        val resolvedPrimary = primary
            ?: outputs.firstOrNull { isBluetoothMediaType(it.type) }
            ?: outputs.firstOrNull()
            ?: return null
        return outputs.firstOrNull { !isSamePhysicalDevice(it, resolvedPrimary) }
    }

    @Suppress("MissingPermission")
    fun evaluate(
        audioManager: AudioManager,
        connectedA2dp: List<BluetoothDevice>
    ): Map<String, Any> {
        val outputs = physicalMediaOutputs(audioManager)
        val playableBt = outputs.filter { isBluetoothMediaType(it.type) }
        val hasWiredOrUsb = outputs.any { isWiredOrUsbType(it.type) }
        val hasLeAudio = outputs.any { isLeAudioType(it.type) }
        val isSamsung = Build.MANUFACTURER.contains("samsung", ignoreCase = true)

        val activeAddresses = playableBt.map { addressOf(it).uppercase() }.toSet()
        val btDevices = connectedA2dp.map { dev ->
            val address = runCatching { dev.address }.getOrNull().orEmpty()
            mapOf(
                "name" to (runCatching { dev.name }.getOrNull() ?: "Bluetooth audio"),
                "address" to address,
                "isActive" to (address.uppercase() in activeAddresses)
            )
        }
        val connectedBtCount = maxOf(btDevices.size, playableBt.size)

        val mode = when {
            outputs.size >= 2 -> MODE_APP_MIRRORING
            isSamsung -> MODE_SAMSUNG_DUAL_AUDIO
            hasLeAudio && Build.VERSION.SDK_INT >= 35 -> MODE_LE_AUDIO_SHARING
            connectedBtCount >= 2 -> MODE_SINGLE_ACTIVE_ONLY
            else -> MODE_NEED_SECOND_DEVICE
        }

        return mapOf(
            "mode" to mode,
            "canAppPlayBoth" to (mode == MODE_APP_MIRRORING),
            "connectedBluetoothCount" to connectedBtCount,
            "playableOutputCount" to outputs.size,
            "hasWiredOrUsb" to hasWiredOrUsb,
            "hasLeAudio" to hasLeAudio,
            "isSamsung" to isSamsung,
            "androidVersion" to Build.VERSION.SDK_INT,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "bluetoothDevices" to btDevices
        )
    }
}
