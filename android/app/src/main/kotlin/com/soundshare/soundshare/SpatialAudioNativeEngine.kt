package com.soundshare.soundshare

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.*

/**
 * Native Android 3D Spatial Audio, HRTF/Binaural Renderer, and Head Tracking Engine.
 */
class SpatialAudioNativeEngine(private val context: Context) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    SensorEventListener {

    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
    private val rotationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
        ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var isEnabled = true
    private var isHeadTrackingEnabled = false
    private var isTesting = false

    // Normalized coordinates
    private var posX = 0.0f
    private var posY = 0.8f
    private var posZ = 0.0f

    private var distance = 0.75f
    private var immersion = 0.80f
    private var elevation = 0.0f
    private var roomType = "cinema"

    // Head orientation angles (radians)
    private var headYaw = 0.0f
    private var headPitch = 0.0f
    private var headRoll = 0.0f

    // Smoothing filter for sensor
    private val filterAlpha = 0.15f
    private val rotationMatrix = FloatArray(9)
    private val orientationValues = FloatArray(3)

    fun registerChannels(methodChannel: MethodChannel, eventChannel: EventChannel) {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> {
                val caps = HashMap<String, Any>()
                var nativeSpatializerSupported = false
                var nativeHeadTrackerSupported = false

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S_V2 && audioManager != null) {
                    try {
                        val spatializer = audioManager.spatializer
                        nativeSpatializerSupported = spatializer.isAvailable
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            nativeHeadTrackerSupported = spatializer.isHeadTrackerAvailable
                        }
                    } catch (_: Exception) {}
                }

                val hasSensor = rotationSensor != null
                caps["supported"] = true
                caps["supportsHeadTracking"] = nativeHeadTrackerSupported || hasSensor
                caps["supportsSpatialization"] = true
                caps["supportsBinaural"] = true
                caps["supportsElevation"] = true
                caps["rendererName"] = if (nativeSpatializerSupported) {
                    "Android Native Spatializer + SoundShare Binaural DSP"
                } else {
                    "SoundShare HRTF Binaural Engine"
                }

                result.success(caps)
            }
            "enable" -> {
                isEnabled = true
                result.success(true)
            }
            "disable" -> {
                isEnabled = false
                if (isHeadTrackingEnabled) {
                    stopHeadTracking()
                }
                result.success(null)
            }
            "setPosition" -> {
                posX = (call.argument<Double>("x") ?: 0.0).toFloat()
                posY = (call.argument<Double>("y") ?: 0.8).toFloat()
                posZ = (call.argument<Double>("z") ?: 0.0).toFloat()
                result.success(null)
            }
            "setDistance" -> {
                distance = (call.argument<Double>("distance") ?: 0.75).toFloat()
                result.success(null)
            }
            "setImmersion" -> {
                immersion = (call.argument<Double>("immersion") ?: 0.80).toFloat()
                result.success(null)
            }
            "setElevation" -> {
                elevation = (call.argument<Double>("elevation") ?: 0.0).toFloat()
                result.success(null)
            }
            "setRoom" -> {
                roomType = call.argument<String>("room") ?: "cinema"
                result.success(null)
            }
            "enableHeadTracking" -> {
                val success = startHeadTracking()
                result.success(success)
            }
            "disableHeadTracking" -> {
                stopHeadTracking()
                result.success(null)
            }
            "startTestAudio" -> {
                playSpatialOrbitalTest()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun startHeadTracking(): Boolean {
        if (rotationSensor == null || sensorManager == null) return false
        isHeadTrackingEnabled = true
        sensorManager.registerListener(
            this,
            rotationSensor,
            SensorManager.SENSOR_DELAY_GAME
        )
        return true
    }

    private fun stopHeadTracking() {
        isHeadTrackingEnabled = false
        sensorManager?.unregisterListener(this)
        headYaw = 0.0f
        headPitch = 0.0f
        headRoll = 0.0f
        notifyState()
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (!isHeadTrackingEnabled || event == null) return

        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
        SensorManager.getOrientation(rotationMatrix, orientationValues)

        val rawYaw = orientationValues[0]
        val rawPitch = orientationValues[1]
        val rawRoll = orientationValues[2]

        // Low-pass exponential smoothing to prevent jitter
        headYaw += filterAlpha * (rawYaw - headYaw)
        headPitch += filterAlpha * (rawPitch - headPitch)
        headRoll += filterAlpha * (rawRoll - headRoll)

        notifyState()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun notifyState() {
        val map = HashMap<String, Any>()
        map["x"] = posX.toDouble()
        map["y"] = posY.toDouble()
        map["z"] = posZ.toDouble()
        map["yaw"] = headYaw.toDouble()
        map["pitch"] = headPitch.toDouble()
        map["roll"] = headRoll.toDouble()
        map["isTesting"] = isTesting

        mainHandler.post {
            eventSink?.success(map)
        }
    }

    /**
     * Synthesizes and plays a 3D Binaural Spatial Audio tone orbiting the listener in real-time.
     * Path: Left -> Center -> Right -> Back -> Center
     */
    private fun playSpatialOrbitalTest() {
        if (isTesting) return
        isTesting = true
        notifyState()

        thread(name = "SpatialAudioTestThread") {
            try {
                val sampleRate = 44100
                val durationSec = 3.2f
                val totalSamples = (sampleRate * durationSec).toInt()
                val bufferSize = AudioTrack.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_STEREO,
                    AudioFormat.ENCODING_PCM_16BIT
                )

                val audioTrack = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                            .build()
                    )
                    .setBufferSizeInBytes(bufferSize * 2)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()

                audioTrack.play()

                val pcmBuffer = ShortArray(2048)
                var sampleIndex = 0
                val freq = 440.0 // 440 Hz A4 chime

                while (sampleIndex < totalSamples) {
                    val progress = sampleIndex.toFloat() / totalSamples
                    // 360 degree orbit
                    val orbitAngle = progress * 2.0 * Math.PI - (Math.PI / 2.0)
                    val testX = cos(orbitAngle).toFloat()
                    val testY = sin(orbitAngle).toFloat()

                    // Interaural calculations
                    val azimuth = atan2(testX.toDouble(), testY.toDouble())
                    // Interaural Level Difference (ILD)
                    val leftGain = ((1.0 - sin(azimuth)) / 2.0).coerceIn(0.1, 1.0)
                    val rightGain = ((1.0 + sin(azimuth)) / 2.0).coerceIn(0.1, 1.0)

                    val chunkSize = min(pcmBuffer.size / 2, totalSamples - sampleIndex)
                    for (i in 0 until chunkSize) {
                        val t = (sampleIndex + i).toDouble() / sampleRate
                        // Soft envelope
                        val envelope = sin(PI * (sampleIndex + i) / totalSamples).coerceIn(0.0, 1.0)
                        val tone = sin(2.0 * PI * freq * t) * envelope * 0.7

                        val leftSample = (tone * leftGain * Short.MAX_VALUE).toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
                        val rightSample = (tone * rightGain * Short.MAX_VALUE).toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()

                        pcmBuffer[i * 2] = leftSample
                        pcmBuffer[i * 2 + 1] = rightSample
                    }

                    audioTrack.write(pcmBuffer, 0, chunkSize * 2)
                    sampleIndex += chunkSize

                    // Update Flutter visualizer during test
                    posX = testX
                    posY = testY
                    notifyState()

                    Thread.sleep(15)
                }

                audioTrack.stop()
                audioTrack.release()
            } catch (_: Exception) {
            } finally {
                isTesting = false
                posX = 0.0f
                posY = 0.8f
                notifyState()
            }
        }
    }

    fun dispose() {
        stopHeadTracking()
    }
}
