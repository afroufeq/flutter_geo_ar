import 'package:flutter/services.dart';

class NativeEventChannel {
  // El nombre debe coincidir con el definido en Android (Kotlin) e iOS (Swift)
  static const EventChannel _channel = EventChannel('flutter_geo_ar/sensors');

  /// Recibe el stream de eventos de sensores nativos con configuración opcional
  ///
  /// [throttleMs] - Intervalo mínimo entre eventos en milisegundos (por defecto 100ms = 10Hz)
  /// [lowPowerMode] - Activa optimizaciones de bajo consumo (por defecto false)
  Stream<dynamic> receiveBroadcastStream({
    int throttleMs = 100,
    bool lowPowerMode = false,
  }) {
    return _channel.receiveBroadcastStream({
      'throttleMs': throttleMs,
      'lowPowerMode': lowPowerMode,
    });
  }
}
