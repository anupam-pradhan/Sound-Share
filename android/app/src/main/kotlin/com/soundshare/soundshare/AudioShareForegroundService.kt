package com.soundshare.soundshare

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Keeps sharing alive in the background. When started with a screen-capture
 * consent it also owns the MediaProjection and the [PlaybackCaptureEngine]
 * (Android 14+ requires the projection to live in a mediaProjection service).
 */
class AudioShareForegroundService : Service() {

    /** Results reported back to MainActivity on the main thread. */
    interface CaptureCallbacks {
        fun onCaptureStarted(sampleRate: Int)
        fun onCaptureStopped()
        fun onCaptureFailed(reason: String)
    }

    companion object {
        private const val TAG = "AudioShareService"
        const val CHANNEL_ID = "soundshare_audio_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "ACTION_START_SHARING"
        const val ACTION_START_CAPTURE = "ACTION_START_CAPTURE"
        const val ACTION_STOP = "ACTION_STOP_SHARING"
        private const val EXTRA_RESULT_CODE = "result_code"
        private const val EXTRA_RESULT_DATA = "result_data"

        @Volatile var callbacks: CaptureCallbacks? = null

        fun startService(context: Context) {
            start(context, Intent(context, AudioShareForegroundService::class.java).setAction(ACTION_START))
        }

        fun startCapture(context: Context, resultCode: Int, data: Intent) {
            start(
                context,
                Intent(context, AudioShareForegroundService::class.java)
                    .setAction(ACTION_START_CAPTURE)
                    .putExtra(EXTRA_RESULT_CODE, resultCode)
                    .putExtra(EXTRA_RESULT_DATA, data)
            )
        }

        fun stopService(context: Context) {
            try {
                context.startService(
                    Intent(context, AudioShareForegroundService::class.java).setAction(ACTION_STOP)
                )
            } catch (e: Exception) {
                Log.w(TAG, "stopService failed: ${e.message}")
            }
        }

        private fun start(context: Context, intent: Intent) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Could not start service: ${e.message}")
                callbacks?.onCaptureFailed("Could not start sharing: ${e.message}")
            }
        }
    }

    private val main = Handler(Looper.getMainLooper())
    private var projection: MediaProjection? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> goForeground(withProjection = false)
            ACTION_START_CAPTURE -> startCapture(intent)
            ACTION_STOP -> {
                stopCapture(notify = true)
                stopForegroundCompat()
                stopSelf()
            }
        }
        // Capture consent cannot be replayed after a restart, so never auto-restart
        return START_NOT_STICKY
    }

    private fun startCapture(intent: Intent) {
        // Must be foreground with the mediaProjection type BEFORE getMediaProjection()
        if (!goForeground(withProjection = true)) {
            fail("Android blocked the sharing service. Try again.")
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            fail("Sharing phone audio needs Android 10 or newer.")
            return
        }
        val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
        val data: Intent? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
        } else {
            @Suppress("DEPRECATION") intent.getParcelableExtra(EXTRA_RESULT_DATA)
        }
        if (resultCode != Activity.RESULT_OK || data == null) {
            fail("Screen-audio permission was not granted.")
            return
        }
        val mpm = getSystemService(MediaProjectionManager::class.java)
        val mp = try {
            mpm?.getMediaProjection(resultCode, data)
        } catch (e: Exception) {
            Log.e(TAG, "getMediaProjection failed", e)
            null
        }
        if (mp == null) {
            fail("Android did not allow audio capture.")
            return
        }
        // Mandatory on Android 14+: know when the user revokes sharing from the system UI
        mp.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                if (projection === mp) {
                    stopCapture(notify = true)
                    stopForegroundCompat()
                    stopSelf()
                }
            }
        }, main)
        projection = mp

        val error = PlaybackCaptureEngine.start(mp)
        if (error != null) {
            fail(error)
            return
        }
        val rate = PlaybackCaptureEngine.sampleRate
        main.post { callbacks?.onCaptureStarted(rate) }
    }

    private fun fail(reason: String) {
        Log.e(TAG, "Capture failed: $reason")
        stopCapture(notify = false)
        main.post { callbacks?.onCaptureFailed(reason) }
        stopForegroundCompat()
        stopSelf()
    }

    private fun stopCapture(notify: Boolean) {
        val wasRunning = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && PlaybackCaptureEngine.isRunning
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) PlaybackCaptureEngine.stop()
        val mp = projection
        projection = null
        try { mp?.stop() } catch (_: Exception) {}
        if (notify && wasRunning) main.post { callbacks?.onCaptureStopped() }
    }

    private fun goForeground(withProjection: Boolean): Boolean {
        val notification = buildNotification(withProjection)
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val type = if (withProjection) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                } else {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                }
                startForeground(NOTIFICATION_ID, notification, type)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed: ${e.message}")
            false
        }
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION") stopForeground(true)
        }
    }

    override fun onDestroy() {
        stopCapture(notify = true)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SoundShare Active Session",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows while SoundShare is sharing your audio"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(capturing: Boolean): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SoundShare is live")
            .setContentText(
                if (capturing) "Friends on your Wi-Fi can listen along"
                else "Sharing audio to your headphones"
            )
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
