package com.soundshare.soundshare

import android.annotation.SuppressLint
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.projection.MediaProjection
import android.os.Build
import android.os.Process
import android.util.Log
import androidx.annotation.RequiresApi
import kotlin.concurrent.thread

/**
 * Captures what other apps are playing (Android 10+ playback capture) as
 * 16-bit interleaved stereo PCM and hands it out in ~20 ms chunks.
 *
 * Runs on its own thread; [listener] is called from that thread.
 */
@RequiresApi(Build.VERSION_CODES.Q)
object PlaybackCaptureEngine {

    private const val TAG = "PlaybackCapture"
    private const val CHANNELS = 2
    private const val BYTES_PER_SAMPLE = 2
    private const val CHUNK_MS = 20
    private val PREFERRED_RATES = listOf(48_000, 44_100)

    fun interface Listener {
        fun onPcm(chunk: ByteArray, sampleRate: Int)
    }

    @Volatile var listener: Listener? = null
    @Volatile var sampleRate: Int = 0
        private set
    @Volatile private var running = false
    private var worker: Thread? = null
    private var record: AudioRecord? = null

    val isRunning: Boolean get() = running

    /** Starts capturing; returns an error message, or null on success. */
    @Synchronized
    fun start(projection: MediaProjection): String? {
        if (running) return null
        val config = AudioPlaybackCaptureConfiguration.Builder(projection)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
            // Never capture our own app (ads, chimes), which would echo
            .excludeUid(Process.myUid())
            .build()

        val opened = PREFERRED_RATES.firstNotNullOfOrNull { rate -> open(config, rate) }
            ?: return "Android could not start audio capture on this phone."
        record = opened
        sampleRate = opened.sampleRate
        running = true
        opened.startRecording()
        worker = thread(name = "SoundShareCapture", isDaemon = true) { readLoop(opened) }
        Log.d(TAG, "Capture started at ${opened.sampleRate} Hz")
        return null
    }

    @SuppressLint("MissingPermission") // RECORD_AUDIO is checked before projection is requested
    private fun open(config: AudioPlaybackCaptureConfiguration, rate: Int): AudioRecord? {
        val channelMask = AudioFormat.CHANNEL_IN_STEREO
        val encoding = AudioFormat.ENCODING_PCM_16BIT
        val minBuf = AudioRecord.getMinBufferSize(rate, channelMask, encoding)
        if (minBuf <= 0) return null
        return try {
            val rec = AudioRecord.Builder()
                .setAudioPlaybackCaptureConfig(config)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(encoding)
                        .setSampleRate(rate)
                        .setChannelMask(channelMask)
                        .build()
                )
                .setBufferSizeInBytes(minBuf * 4)
                .build()
            if (rec.state == AudioRecord.STATE_INITIALIZED) rec else {
                rec.release()
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "AudioRecord at $rate Hz failed: ${e.message}")
            null
        }
    }

    private fun readLoop(rec: AudioRecord) {
        Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
        val chunkBytes = rec.sampleRate * CHUNK_MS / 1000 * CHANNELS * BYTES_PER_SAMPLE
        val buffer = ByteArray(chunkBytes)
        while (running) {
            // Fill a whole chunk so the receiver gets evenly sized packets
            var filled = 0
            while (running && filled < chunkBytes) {
                val n = rec.read(buffer, filled, chunkBytes - filled)
                if (n < 0) {
                    Log.w(TAG, "AudioRecord.read error $n")
                    running = false
                    break
                }
                filled += n
            }
            if (filled == chunkBytes) listener?.onPcm(buffer.copyOf(), rec.sampleRate)
        }
    }

    @Synchronized
    fun stop() {
        running = false
        try { worker?.join(200) } catch (_: InterruptedException) {}
        worker = null
        record?.let {
            try { it.stop() } catch (_: Exception) {}
            it.release()
        }
        record = null
        sampleRate = 0
        Log.d(TAG, "Capture stopped")
    }
}
