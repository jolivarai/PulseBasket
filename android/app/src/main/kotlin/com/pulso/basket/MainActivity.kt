package com.pulso.basket

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Puente Dart <-> Android para el control del entrenamiento.
 *
 * - Dart llama a `start`, `update` y `stop` para gobernar la notificación.
 * - El servicio devuelve `onAction` ("pause" / "resume" / "stop") cuando el
 *   usuario pulsa un botón en la pantalla de bloqueo.
 *
 * El canal se registra en `configureFlutterEngine`, que es el punto en el que
 * el motor de Flutter ya existe pero la app todavía no ha pintado.
 */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null

    private val uiReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val event = intent?.getStringExtra(TrackingForegroundService.EXTRA_EVENT) ?: return
            channel?.invokeMethod("onAction", event)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pulso/tracking_service"
        )

        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val title = call.argument<String>("title") ?: "Entreno"
                    TrackingForegroundService.start(this, title)
                    result.success(null)
                }

                "update" -> {
                    TrackingForegroundService.update(
                        context = this,
                        paused = call.argument<Boolean>("paused") ?: false,
                        title = call.argument<String>("title") ?: "Entreno",
                        distance = call.argument<String>("distance") ?: "0 m",
                        pace = call.argument<String>("pace") ?: "--",
                        remaining = call.argument<String>("remaining") ?: "",
                        progress = (call.argument<Double>("progress") ?: 0.0).toFloat()
                    )
                    result.success(null)
                }

                "stop" -> {
                    TrackingForegroundService.stop(this)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        // Android 13+ exige indicar si el receptor es exportado. Al ser un
        // broadcast interno de la propia app, NO_EXPORTED es lo correcto.
        ContextCompat.registerReceiver(
            this,
            uiReceiver,
            IntentFilter(TrackingForegroundService.ACTION_UI_EVENT),
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(uiReceiver)
        } catch (_: IllegalArgumentException) {
            // Ya estaba desregistrado: no es un error.
        }
        super.onDestroy()
    }
}
