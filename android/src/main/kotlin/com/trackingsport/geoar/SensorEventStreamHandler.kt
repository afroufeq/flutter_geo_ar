package com.trackingsport.geoar

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import io.flutter.plugin.common.EventChannel
import kotlin.math.atan2
import kotlin.math.sqrt

/**
 * Stream handler para sensores con optimizaciones de batería:
 * - Usa TYPE_ROTATION_VECTOR para orientación fusionada
 * - GPS optimizado con actualizaciones cada 5s o 10m
 * - Throttling unificado para reducir tráfico nativo-Dart
 * - Modo bajo consumo configurable que ajusta la velocidad del sensor
 */
class SensorEventStreamHandler(private val context: Context) :
    EventChannel.StreamHandler,
    SensorEventListener,
    LocationListener {

    private var sensorManager: SensorManager? = null
    private var locationManager: LocationManager? = null
    private var rotationSensor: Sensor? = null
    private var throttler: SensorEventThrottler? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events

        // Obtener configuración de throttle y modo bajo consumo desde los argumentos
        val throttleMs: Long
        val lowPowerMode: Boolean

        if (arguments is Map<*, *>) {
            throttleMs = (arguments["throttleMs"] as? Number)?.toLong() ?: 100L
            lowPowerMode = (arguments["lowPowerMode"] as? Boolean) ?: false
        } else {
            throttleMs = 100L
            lowPowerMode = false
        }

        // Inicializar throttler con la frecuencia configurada
        throttler = SensorEventThrottler(eventSink, throttleMs)

        // Configurar sensor de orientación
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

        // En modo bajo consumo, usar SENSOR_DELAY_UI (más lento) para ahorrar batería
        // En modo normal, usar SENSOR_DELAY_NORMAL para mejor precisión
        val sensorDelay = if (lowPowerMode) SensorManager.SENSOR_DELAY_UI else SensorManager.SENSOR_DELAY_NORMAL

        rotationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        rotationSensor?.also { s ->
            sensorManager?.registerListener(this, s, sensorDelay)
        }

        // Configurar GPS con optimización de batería
        locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        try {
            // Verificar que el GPS está habilitado
            val isGpsEnabled = locationManager?.isProviderEnabled(LocationManager.GPS_PROVIDER) ?: false
            val isNetworkEnabled = locationManager?.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ?: false
            
            android.util.Log.d("GeoAR", "[GeoAR] 🛰️ GPS habilitado: $isGpsEnabled")
            android.util.Log.d("GeoAR", "[GeoAR] 📶 Network habilitado: $isNetworkEnabled")
            
            if (!isGpsEnabled && !isNetworkEnabled) {
                android.util.Log.e("GeoAR", "[GeoAR] ❌ No hay proveedores de ubicación disponibles")
                eventSink?.error("NO_LOCATION_PROVIDER", "GPS y Network deshabilitados", null)
            } else {
                // Intentar obtener última ubicación conocida
                val lastKnownLocation = locationManager?.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                    ?: locationManager?.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                
                if (lastKnownLocation != null) {
                    android.util.Log.d("GeoAR", "[GeoAR] 📍 Última ubicación conocida: ${lastKnownLocation.latitude}, ${lastKnownLocation.longitude}")
                    // Enviar inmediatamente la última ubicación conocida
                    val locationData = mapOf(
                        "lat" to lastKnownLocation.latitude,
                        "lon" to lastKnownLocation.longitude,
                        "alt" to lastKnownLocation.altitude,
                        "accuracy" to lastKnownLocation.accuracy,
                        "ts" to System.currentTimeMillis()
                    )
                    throttler?.push(locationData)
                } else {
                    android.util.Log.d("GeoAR", "[GeoAR] ⚠️ No hay última ubicación conocida")
                }
                
                // GPS optimizado: Actualizaciones cada 5 segundos O 10 metros de movimiento
                // Priorizar NETWORK_PROVIDER si GPS está deshabilitado o tarda mucho
                val provider = if (isNetworkEnabled) LocationManager.NETWORK_PROVIDER else LocationManager.GPS_PROVIDER
                android.util.Log.d("GeoAR", "[GeoAR] 📡 Solicitando actualizaciones de ubicación con proveedor: $provider")
                
                locationManager?.requestLocationUpdates(
                    provider,
                    5000L,  // minTime: 5 segundos
                    10f,    // minDistance: 10 metros
                    this
                )
                android.util.Log.d("GeoAR", "[GeoAR] ✅ Actualizaciones de ubicación solicitadas correctamente")
            }
        } catch (e: SecurityException) {
            android.util.Log.e("GeoAR", "[GeoAR] ❌ Error de permisos: ${e.message}")
            eventSink?.error("PERMISSION_DENIED", "Permisos de ubicación no concedidos", null)
        } catch (e: Exception) {
            android.util.Log.e("GeoAR", "[GeoAR] ❌ Error al configurar ubicación: ${e.message}")
            eventSink?.error("LOCATION_ERROR", "Error al configurar GPS: ${e.message}", null)
        }
    }

    override fun onCancel(arguments: Any?) {
        // Limpiar recursos
        sensorManager?.unregisterListener(this)
        locationManager?.removeUpdates(this)
        throttler?.cleanup()
        throttler = null
        eventSink = null
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_ROTATION_VECTOR) {
            // Convertir rotation vector a ángulos de Euler
            val rotationMatrix = FloatArray(9)
            SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)

            val orientation = FloatArray(3)
            SensorManager.getOrientation(rotationMatrix, orientation)

            // Convertir radianes a grados
            val azimuth = Math.toDegrees(orientation[0].toDouble()).toFloat()
            val pitch = Math.toDegrees(orientation[1].toDouble()).toFloat()
            val roll = Math.toDegrees(orientation[2].toDouble()).toFloat()

            // Normalizar azimuth a 0-360
            val heading = if (azimuth < 0) azimuth + 360f else azimuth

            // Enviar datos de orientación al throttler
            val orientationData = mapOf(
                "heading" to heading,
                "pitch" to pitch,
                "roll" to roll,
                "ts" to System.currentTimeMillis()
            )
            throttler?.push(orientationData)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No se requiere acción para cambios de precisión
    }

    override fun onLocationChanged(location: Location) {
        // Enviar datos de ubicación al throttler
        val locationData = mapOf(
            "lat" to location.latitude,
            "lon" to location.longitude,
            "alt" to location.altitude,
            "accuracy" to location.accuracy,
            "ts" to System.currentTimeMillis()
        )
        throttler?.push(locationData)
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {
        // Método deprecated pero requerido por la interfaz
    }

    override fun onProviderEnabled(provider: String) {
        // Proveedor GPS habilitado
    }

    override fun onProviderDisabled(provider: String) {
        // Proveedor GPS deshabilitado
        eventSink?.error("GPS_DISABLED", "GPS deshabilitado", null)
    }
}
