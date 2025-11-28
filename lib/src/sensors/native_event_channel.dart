import 'package:flutter/services.dart';

class NativeEventChannel {
  // El nombre debe coincidir con el definido en Android (Kotlin) e iOS (Swift)
  static const EventChannel _channel = EventChannel('flutter_geo_ar/sensors');

  /// Recibe el stream de eventos de sensores nativos con configuración opcional
  ///
  /// [throttleMs] - Intervalo mínimo entre eventos en milisegundos cuando está activo (por defecto 100ms = 10Hz)
  /// [lowPowerMode] - Activa optimizaciones de bajo consumo en los sensores nativos (por defecto false)
  /// [adaptiveThrottling] - Activa el throttling adaptativo basado en movimiento (por defecto false)
  /// [lowFrequencyMs] - Intervalo entre eventos cuando está estático, solo si adaptiveThrottling=true (por defecto 1000ms = 1Hz)
  /// [staticThreshold] - Umbral de aceleración en m/s² para considerar movimiento (por defecto 0.1)
  /// [staticDurationMs] - Tiempo en ms sin movimiento antes de entrar en modo estático (por defecto 2000ms)
  ///
  /// El throttling adaptativo ajusta automáticamente la frecuencia de actualización:
  /// - Modo ACTIVO (movimiento detectado): Usa [throttleMs] para alta frecuencia
  /// - Modo ESTÁTICO (sin movimiento): Usa [lowFrequencyMs] para baja frecuencia
  ///
  /// Beneficios del throttling adaptativo:
  /// - Ahorro de batería de hasta 70% en patrones de uso con paradas frecuentes
  /// - Ideal para senderismo, turismo, y otras actividades con pausas
  /// - Transiciones instantáneas al detectar movimiento
  /// - Funcionamiento transparente sin intervención del usuario
  Stream<dynamic> receiveBroadcastStream({
    int throttleMs = 100,
    bool lowPowerMode = false,
    bool adaptiveThrottling = false,
    int lowFrequencyMs = 1000,
    double staticThreshold = 0.1,
    int staticDurationMs = 2000,
  }) {
    return _channel.receiveBroadcastStream({
      'throttleMs': throttleMs,
      'lowPowerMode': lowPowerMode,
      'adaptiveThrottling': adaptiveThrottling,
      'lowFrequencyMs': lowFrequencyMs,
      'staticThreshold': staticThreshold,
      'staticDurationMs': staticDurationMs,
    });
  }
}
