package com.pulso.basket

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
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

/**
 * Servicio en primer plano que mantiene vivo el proceso mientras se entrena.
 *
 * ¿Por qué es imprescindible? Android duerme los procesos en segundo plano a
 * los pocos minutos. Un servicio en primer plano con tipo `location` es la
 * única forma soportada de seguir recibiendo GPS con la pantalla apagada.
 *
 * La notificación es, a la vez:
 *   - el requisito legal del servicio en primer plano,
 *   - la "pantalla de bloqueo" del ejercicio: distancia, ritmo, restante
 *     y botones Pausar / Reanudar / Detener.
 *
 * La notificación NO se actualiza sola: Dart envía los textos ya formateados
 * cada segundo mediante `update()`. Así el formato español (comas, min/km)
 * vive en un único sitio: Dart.
 */
class TrackingForegroundService : Service() {

    companion object {
        private const val CHANNEL_ID = "pulso_tracking"
        private const val NOTIFICATION_ID = 4210

        private const val ACTION_START = "com.pulso.basket.action.START"
        private const val ACTION_UPDATE = "com.pulso.basket.action.UPDATE"
        private const val ACTION_TOGGLE = "com.pulso.basket.action.TOGGLE"
        private const val ACTION_STOP = "com.pulso.basket.action.STOP"

        /** Broadcast interno que MainActivity reenvía a Dart. */
        const val ACTION_UI_EVENT = "com.pulso.basket.action.UI_EVENT"
        const val EXTRA_EVENT = "event"

        private const val EXTRA_TITLE = "title"
        private const val EXTRA_DISTANCE = "distance"
        private const val EXTRA_PACE = "pace"
        private const val EXTRA_REMAINING = "remaining"
        private const val EXTRA_PROGRESS = "progress"
        private const val EXTRA_PAUSED = "paused"

        fun start(context: Context, title: String) {
            val intent = Intent(context, TrackingForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TITLE, title)
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun update(
            context: Context,
            paused: Boolean,
            title: String,
            distance: String,
            pace: String,
            remaining: String,
            progress: Float
        ) {
            val intent = Intent(context, TrackingForegroundService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_PAUSED, paused)
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_DISTANCE, distance)
                putExtra(EXTRA_PACE, pace)
                putExtra(EXTRA_REMAINING, remaining)
                putExtra(EXTRA_PROGRESS, progress)
            }
            // startService (no startForegroundService): el servicio ya está vivo.
            context.startService(intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, TrackingForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    private var paused = false
    private var title = "Entreno"
    private var distance = "0 m"
    private var pace = "--"
    private var remaining = ""
    private var progress = 0f

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                title = intent.getStringExtra(EXTRA_TITLE) ?: title
                startInForeground()
            }

            ACTION_UPDATE -> {
                paused = intent.getBooleanExtra(EXTRA_PAUSED, paused)
                title = intent.getStringExtra(EXTRA_TITLE) ?: title
                distance = intent.getStringExtra(EXTRA_DISTANCE) ?: distance
                pace = intent.getStringExtra(EXTRA_PACE) ?: pace
                remaining = intent.getStringExtra(EXTRA_REMAINING) ?: remaining
                progress = intent.getFloatExtra(EXTRA_PROGRESS, progress)
                notify(buildNotification())
            }

            ACTION_TOGGLE -> {
                paused = !paused
                notify(buildNotification())
                // Avisa a Flutter para que pause/reanude también la lógica
                // de GPS y el cronómetro (la notificación es solo la UI).
                emit(if (paused) "pause" else "resume")
            }

            ACTION_STOP -> {
                emit("stop")
                ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
                stopSelf()
            }

            else -> startInForeground() // reinicio por START_STICKY
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /** Si el usuario desliza la app fuera de recientes, seguimos grabando. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        // Intencionadamente vacío: el entreno continúa.
    }

    // ────────────────────────────────────────────────────────────── UI ──

    private fun startInForeground() {
        val notification = buildNotification()
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
        } else {
            0
        }
        ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, type)
    }

    private fun buildNotification(): Notification {
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val toggleIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, TrackingForegroundService::class.java).apply { action = ACTION_TOGGLE },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = PendingIntent.getService(
            this,
            2,
            Intent(this, TrackingForegroundService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val status = if (paused) "PAUSADO" else "GRABANDO"
        val body = buildString {
            append(distance)
            append("  ·  ")
            append(pace)
            if (remaining.isNotEmpty()) {
                append("  ·  ")
                append(remaining)
            }
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle("$title · $status")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setSubText("Pulso Basket")
            .setContentIntent(openApp)
            .setOngoing(true)
            .setOnlyAlertOnce(true)      // no suena cada segundo
            .setSilent(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_WORKOUT)
            // VISIBILITY_PUBLIC = se ve completo en la pantalla de bloqueo.
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setProgress(100, (progress.coerceIn(0f, 1f) * 100).toInt(), false)
            .addAction(
                0,
                if (paused) "Reanudar" else "Pausar",
                toggleIntent
            )
            .addAction(0, "Detener", stopIntent)
            .build()
    }

    private fun notify(notification: Notification) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Entrenamiento en curso",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Distancia, ritmo y controles de pausa durante el entreno"
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    private fun emit(event: String) {
        val intent = Intent(ACTION_UI_EVENT).apply {
            setPackage(packageName)
            putExtra(EXTRA_EVENT, event)
        }
        sendBroadcast(intent)
    }
}
