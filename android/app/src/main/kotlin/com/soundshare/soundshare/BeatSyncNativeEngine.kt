package com.soundshare.soundshare

import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.Visualizer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * BeatSyncNativeEngine handles real-time audio analysis (via Visualizer / AudioRecord),
 * dynamic spectral/transient beat detection, drop detection, safety rate limiting,
 * and haptic vibration feedback.
 */
class BeatSyncNativeEngine(private val context: Context) {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    // Haptic engine
    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    // Settings
    private var isEnabled = false
    private var intensityMultiplier: Double = 1.0 // 0.5 (low), 1.0 (med), 1.5 (high)
    private var sensitivityThreshold: Double = 1.0 // 1.4 (low sens), 1.0 (med), 0.7 (high sens)
    private var bassBoost: Double = 1.0 // 1.0 (off), 1.3 (normal), 1.6 (strong)

    // Analysis state
    private var visualizer: Visualizer? = null
    private var audioRecord: AudioRecord? = null
    private var recordThread: Thread? = null
    private val isRecording = AtomicBoolean(false)

    // Beat Detection state
    private var energyHistory = DoubleArray(32) { 0.0 }
    private var historyIndex = 0
    private var lastBeatTimestamp = 0L
    private var lastDropTimestamp = 0L
    private var quietDurationMs = 0L
    private var lastAnalysisTimestamp = System.currentTimeMillis()

    // Safety Rate Limiting
    private val minBeatIntervalMs = 95L // Minimum interval between haptic beats
    private val maxBeatsPerSecond = 8
    private var beatCountWindow = 0
    private var windowStartMs = System.currentTimeMillis()
    private val silenceThreshold = 0.015

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun getCapabilities(): Map<String, Any> {
        val hasVib = vibrator?.hasVibrator() ?: false
        val hasAmp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.hasAmplitudeControl() ?: false
        } else {
            false
        }
        val hasAdvanced = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

        return mapOf(
            "available" to hasVib,
            "supportsAmplitude" to hasAmp,
            "supportsAdvancedEffects" to hasAdvanced,
            "androidVersion" to Build.VERSION.SDK_INT
        )
    }

    fun updateSettings(intensity: Double, sensitivity: Double, bass: Double) {
        this.intensityMultiplier = intensity.coerceIn(0.2, 2.0)
        this.sensitivityThreshold = sensitivity.coerceIn(0.5, 2.0)
        this.bassBoost = bass.coerceIn(1.0, 2.0)
    }

    fun startAnalysis(): Boolean {
        if (isEnabled) return true
        isEnabled = true

        // Try Visualizer on audio session 0 (output mix)
        var visualizerSuccess = false
        try {
            visualizer = Visualizer(0).apply {
                captureSize = Visualizer.getCaptureSizeRange()[1]
                setDataCaptureListener(object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(v: Visualizer?, waveform: ByteArray?, samplingRate: Int) {
                        if (waveform != null && isEnabled) {
                            processWaveform(waveform)
                        }
                    }

                    override fun onFftDataCapture(v: Visualizer?, fft: ByteArray?, samplingRate: Int) {
                        if (fft != null && isEnabled) {
                            processFft(fft)
                        }
                    }
                }, Visualizer.getMaxCaptureRate() / 2, true, true)
                enabled = true
            }
            visualizerSuccess = true
        } catch (e: Exception) {
            visualizer?.release()
            visualizer = null
        }

        if (!visualizerSuccess) {
            // Fallback to background AudioRecord for real PCM analysis
            startAudioRecordAnalysis()
        }

        return true
    }

    fun stopAnalysis() {
        isEnabled = false
        try {
            visualizer?.apply {
                enabled = false
                release()
            }
            visualizer = null
        } catch (_: Exception) {}

        isRecording.set(false)
        try {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
        } catch (_: Exception) {}
        recordThread = null
    }

    private fun startAudioRecordAnalysis() {
        if (isRecording.get()) return
        val sampleRate = 44100
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val bufferSize = max(
            AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat),
            2048
        )

        try {
            @Suppress("MissingPermission")
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                channelConfig,
                audioFormat,
                bufferSize
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                audioRecord?.release()
                audioRecord = null
                return
            }

            audioRecord?.startRecording()
            isRecording.set(true)

            recordThread = Thread {
                val pcmBuffer = ShortArray(1024)
                while (isRecording.get() && isEnabled) {
                    val read = audioRecord?.read(pcmBuffer, 0, pcmBuffer.size) ?: -1
                    if (read > 0) {
                        processPcm(pcmBuffer, read)
                    }
                    try {
                        Thread.sleep(25) // ~40 fps analysis rate
                    } catch (_: InterruptedException) {
                        break
                    }
                }
            }.apply {
                priority = Thread.NORM_PRIORITY
                isDaemon = true
                start()
            }
        } catch (_: Exception) {
            isRecording.set(false)
        }
    }

    private fun processWaveform(waveform: ByteArray) {
        var sumSquares = 0.0
        for (b in waveform) {
            val normalized = (b.toInt() - 128) / 128.0
            sumSquares += normalized * normalized
        }
        val rms = sqrt(sumSquares / waveform.size)
        analyzeEnergy(rms, bassEnergyRatio = 1.0)
    }

    private fun processFft(fft: ByteArray) {
        // FFT format: n bytes (real, imag pairs)
        var bassSum = 0.0
        var totalSum = 0.0
        val n = fft.size / 2

        for (i in 1 until n) {
            val real = fft[2 * i].toDouble()
            val imag = fft[2 * i + 1].toDouble()
            val magnitude = sqrt(real * real + imag * imag)

            totalSum += magnitude
            if (i in 1..4) { // Sub-bass bins (~30 - 200 Hz)
                bassSum += magnitude
            }
        }

        val bassRatio = if (totalSum > 0.001) (bassSum / totalSum) * bassBoost else 1.0
        val normalizedEnergy = (totalSum / (n * 128.0)).coerceIn(0.0, 1.0)
        analyzeEnergy(normalizedEnergy, bassRatio)
    }

    private fun processPcm(pcm: ShortArray, length: Int) {
        var sumSquares = 0.0
        var lowPass = 0.0
        var alpha = 0.15 // Simple 1-pole low-pass filter for sub-bass

        for (i in 0 until length) {
            val sample = pcm[i] / 32768.0
            sumSquares += sample * sample

            // Low pass estimate
            lowPass += alpha * (sample - lowPass)
        }

        val rms = sqrt(sumSquares / length)
        val bassRms = sqrt(lowPass * lowPass) * bassBoost
        val bassRatio = if (rms > 0.001) (bassRms / rms).coerceIn(0.5, 2.5) else 1.0

        analyzeEnergy(rms, bassRatio)
    }

    private fun analyzeEnergy(currentEnergy: Double, bassEnergyRatio: Double) {
        val now = System.currentTimeMillis()
        val dt = now - lastAnalysisTimestamp
        lastAnalysisTimestamp = now

        // Check silence
        if (currentEnergy < silenceThreshold) {
            quietDurationMs += dt
            return
        }

        // Running energy stats
        energyHistory[historyIndex] = currentEnergy
        historyIndex = (historyIndex + 1) % energyHistory.size

        var sum = 0.0
        var maxPast = 0.0
        for (e in energyHistory) {
            sum += e
            if (e > maxPast) maxPast = e
        }
        val avgEnergy = sum / energyHistory.size

        // Variance / dynamic threshold
        var varianceSum = 0.0
        for (e in energyHistory) {
            val diff = e - avgEnergy
            varianceSum += diff * diff
        }
        val stdDev = sqrt(varianceSum / energyHistory.size)
        val dynamicThreshold = avgEnergy + (stdDev * 1.35 * sensitivityThreshold)

        // Drop Detection: Energy surge (> 2.8x average) following a quiet period >= 700ms
        val isDrop = (quietDurationMs >= 700L) && (currentEnergy > avgEnergy * 2.5) && (currentEnergy > 0.35)
        if (currentEnergy >= silenceThreshold) {
            quietDurationMs = 0L
        }

        // Rate limiting check
        if (now - windowStartMs > 1000L) {
            windowStartMs = now
            beatCountWindow = 0
        }

        val timeSinceLastBeat = now - lastBeatTimestamp
        if (timeSinceLastBeat < minBeatIntervalMs || beatCountWindow >= maxBeatsPerSecond) {
            return
        }

        // Check if beat threshold exceeded or drop detected
        if (isDrop && (now - lastDropTimestamp > 1500L)) {
            lastDropTimestamp = now
            lastBeatTimestamp = now
            beatCountWindow++
            triggerHaptic(BeatType.DROP, strength = 1.0)
            emitBeatEvent(BeatType.DROP, 1.0, currentEnergy)
        } else if (currentEnergy > dynamicThreshold && currentEnergy > 0.08) {
            lastBeatTimestamp = now
            beatCountWindow++

            // Classify beat type
            val beatType: BeatType
            val rawStrength: Double

            if (bassEnergyRatio > 1.35 && currentEnergy > avgEnergy * 1.5) {
                beatType = BeatType.KICK
                rawStrength = min(1.0, (currentEnergy / (maxPast + 0.01)) * 1.2)
            } else if (currentEnergy > avgEnergy * 1.8) {
                beatType = BeatType.STRONG_BEAT
                rawStrength = min(1.0, currentEnergy / (maxPast + 0.01))
            } else if (bassEnergyRatio < 0.85 && currentEnergy > avgEnergy * 1.2) {
                beatType = BeatType.SNARE
                rawStrength = 0.7
            } else {
                beatType = BeatType.SOFT_BEAT
                rawStrength = 0.45
            }

            val finalStrength = (rawStrength * intensityMultiplier).coerceIn(0.1, 1.0)
            triggerHaptic(beatType, finalStrength)
            emitBeatEvent(beatType, finalStrength, currentEnergy)
        }
    }

    fun triggerTestPulse() {
        triggerHaptic(BeatType.KICK, strength = 0.85)
        emitBeatEvent(BeatType.KICK, 0.85, 0.75)
    }

    private fun triggerHaptic(type: BeatType, strength: Double) {
        val vib = vibrator ?: return
        if (!vib.hasVibrator()) return

        val durationMs: Long
        val amplitude: Int = (255 * strength).toInt().coerceIn(1, 255)

        when (type) {
            BeatType.DROP -> {
                durationMs = 60L
            }
            BeatType.KICK -> {
                durationMs = 45L
            }
            BeatType.STRONG_BEAT -> {
                durationMs = 35L
            }
            BeatType.SNARE -> {
                durationMs = 25L
            }
            BeatType.TRANSIENT -> {
                durationMs = 20L
            }
            BeatType.SOFT_BEAT -> {
                durationMs = 18L
            }
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (vib.hasAmplitudeControl()) {
                    val effect = VibrationEffect.createOneShot(durationMs, amplitude)
                    vib.vibrate(effect)
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val effect = when (type) {
                        BeatType.DROP, BeatType.KICK -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK)
                        BeatType.STRONG_BEAT, BeatType.SNARE -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
                        else -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK)
                    }
                    vib.vibrate(effect)
                } else {
                    val effect = VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE)
                    vib.vibrate(effect)
                }
            } else {
                @Suppress("DEPRECATION")
                vib.vibrate(durationMs)
            }
        } catch (_: Exception) {}
    }

    private fun emitBeatEvent(type: BeatType, strength: Double, energy: Double) {
        val data = mapOf(
            "timestamp" to System.currentTimeMillis(),
            "type" to type.name.lowercase(),
            "strength" to strength,
            "energy" to energy
        )
        mainHandler.post {
            eventSink?.success(data)
        }
    }

    enum class BeatType {
        KICK,
        SNARE,
        TRANSIENT,
        STRONG_BEAT,
        SOFT_BEAT,
        DROP
    }
}
