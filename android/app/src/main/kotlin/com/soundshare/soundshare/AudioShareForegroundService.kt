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

class AudioShareForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "soundshare_audio_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "ACTION_START_SHARING"
        const val ACTION_START_PROJECTION = "ACTION_START_PROJECTION"
        const val ACTION_STOP = "ACTION_STOP_SHARING"

        const val EXTRA_RESULT_CODE = "extra_result_code"
        const val EXTRA_DATA_INTENT = "extra_data_intent"

        var onProjectionGranted: ((MediaProjection) -> Unit)? = null
        var onProjectionFailed: ((String) -> Unit)? = null

        fun startService(context: Context) {
            try {
                val intent = Intent(context, AudioShareForegroundService::class.java).apply {
                    action = ACTION_START
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Throwable) {
                Log.e("AudioShareService", "Failed to start service: ${e.message}", e)
            }
        }

        fun startProjectionService(context: Context, resultCode: Int, data: Intent) {
            try {
                val intent = Intent(context, AudioShareForegroundService::class.java).apply {
                    action = ACTION_START_PROJECTION
                    putExtra(EXTRA_RESULT_CODE, resultCode)
                    putExtra(EXTRA_DATA_INTENT, data)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Throwable) {
                Log.e("AudioShareService", "Failed to start projection service: ${e.message}", e)
                onProjectionFailed?.invoke(e.message ?: "Failed to start projection service")
            }
        }

        fun stopService(context: Context) {
            try {
                val intent = Intent(context, AudioShareForegroundService::class.java).apply {
                    action = ACTION_STOP
                }
                context.startService(intent)
            } catch (e: Throwable) {
                Log.e("AudioShareService", "Failed to stop service: ${e.message}", e)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val notification = buildNotification()
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        startForeground(
                            NOTIFICATION_ID,
                            notification,
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                        )
                    } else {
                        startForeground(NOTIFICATION_ID, notification)
                    }
                } catch (t: Throwable) {
                    Log.e("AudioShareService", "startForeground MEDIA_PLAYBACK error: ${t.message}", t)
                }
            }
            ACTION_START_PROJECTION -> {
                val notification = buildNotification()
                try {
                    // Critical: On Android 14+ (API 34+), startForeground MUST be called with
                    // FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION before getMediaProjection() can be called
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        startForeground(
                            NOTIFICATION_ID,
                            notification,
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK or ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                        )
                    } else {
                        startForeground(NOTIFICATION_ID, notification)
                    }
                } catch (t: Throwable) {
                    Log.e("AudioShareService", "startForeground MEDIA_PROJECTION error: ${t.message}", t)
                }

                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
                val data = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(EXTRA_DATA_INTENT, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra<Intent>(EXTRA_DATA_INTENT)
                }

                if (resultCode == Activity.RESULT_OK && data != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    try {
                        val mpManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
                        val mp = mpManager?.getMediaProjection(resultCode, data)
                        if (mp != null) {
                            Handler(Looper.getMainLooper()).post {
                                onProjectionGranted?.invoke(mp)
                            }
                        } else {
                            Handler(Looper.getMainLooper()).post {
                                onProjectionFailed?.invoke("Could not obtain MediaProjection token from system.")
                            }
                        }
                    } catch (e: Throwable) {
                        Log.e("AudioShareService", "getMediaProjection inside service failed: ${e.message}", e)
                        Handler(Looper.getMainLooper()).post {
                            onProjectionFailed?.invoke(e.message ?: "Failed to get MediaProjection")
                        }
                    }
                } else {
                    Handler(Looper.getMainLooper()).post {
                        onProjectionFailed?.invoke("Screen capture permission was not granted.")
                    }
                }
            }
            ACTION_STOP -> {
                try {
                    stopForeground(true)
                } catch (_: Throwable) {}
                stopSelf()
            }
        }
        // START_NOT_STICKY prevents crash-looping if process terminates unexpectedly
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SoundShare Active Session",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows status while sharing audio to connected devices"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SoundShare Active")
            .setContentText("Sharing audio to connected devices")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
