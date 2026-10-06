package com.soundshare.soundshare

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class AudioShareForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "soundshare_audio_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "ACTION_START_SHARING"
        const val ACTION_ENABLE_PROJECTION = "ACTION_ENABLE_PROJECTION"
        const val ACTION_STOP = "ACTION_STOP_SHARING"

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

        fun enableProjectionMode(context: Context) {
            try {
                val intent = Intent(context, AudioShareForegroundService::class.java).apply {
                    action = ACTION_ENABLE_PROJECTION
                }
                context.startService(intent)
            } catch (e: Throwable) {
                Log.e("AudioShareService", "Failed to enable projection mode: ${e.message}", e)
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
                    // Start initially with MEDIA_PLAYBACK only to avoid Android 14 SecurityException
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
                    Log.e("AudioShareService", "startForeground MEDIA_PLAYBACK fallback: ${t.message}", t)
                    try {
                        startForeground(NOTIFICATION_ID, notification)
                    } catch (_: Throwable) {}
                }
            }
            ACTION_ENABLE_PROJECTION -> {
                val notification = buildNotification()
                try {
                    // Promote to MEDIA_PROJECTION only after user consent token has been granted
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
                    Log.e("AudioShareService", "startForeground MEDIA_PROJECTION fallback: ${t.message}", t)
                    try {
                        startForeground(NOTIFICATION_ID, notification)
                    } catch (_: Throwable) {}
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
