package com.trackingsport.geoar

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Throttler para eventos de sensores que acumula datos y los emite a una frecuencia controlada.
 * Esto reduce el tráfico entre el código nativo y Dart, mejorando la eficiencia.
 */
class SensorEventThrottler(
    private val eventSink: EventChannel.EventSink?,
    private val throttleMs: Long
) {
    private val handler = Handler(Looper.getMainLooper())
    private var pendingData: MutableMap<String, Any> = mutableMapOf()
    private var lastEmitTime: Long = 0
    private var isScheduled: Boolean = false

    /**
     * Agrega datos al buffer. Si ha pasado suficiente tiempo desde la última emisión,
     * emite inmediatamente. De lo contrario, programa una emisión futura.
     */
    @Synchronized
    fun push(data: Map<String, Any>) {
        // Fusionar nuevos datos con datos pendientes
        pendingData.putAll(data)

        val now = System.currentTimeMillis()
        val timeSinceLastEmit = now - lastEmitTime

        if (timeSinceLastEmit >= throttleMs) {
            emitNow()
        } else if (!isScheduled) {
            isScheduled = true
            val remainingTime = throttleMs - timeSinceLastEmit
            handler.postDelayed({
                emitNow()
            }, remainingTime)
        }
    }

    /**
     * Emite los datos acumulados inmediatamente y reinicia el buffer.
     */
    @Synchronized
    private fun emitNow() {
        isScheduled = false
        if (pendingData.isNotEmpty()) {
            eventSink?.success(HashMap(pendingData))
            lastEmitTime = System.currentTimeMillis()
            pendingData.clear()
        }
    }

    /**
     * Limpia recursos cuando se detiene el stream.
     */
    fun cleanup() {
        handler.removeCallbacksAndMessages(null)
        synchronized(this) {
            pendingData.clear()
            isScheduled = false
        }
    }
}
