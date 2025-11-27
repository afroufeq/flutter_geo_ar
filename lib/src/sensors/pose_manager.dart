import 'dart:async';
import 'native_event_channel.dart';
import 'fused_data.dart';
import '../utils/logger.dart';

/// Gestiona los sensores nativos con optimizaciones de batería
///
/// Proporciona un stream unificado de datos de orientación (heading, pitch, roll)
/// y ubicación (lat, lon, alt) desde los sensores nativos de Android e iOS.
///
/// Soporta dos modos de operación:
/// - **Modo Normal**: Máxima precisión, 10 eventos/segundo, ideal para sesiones cortas
/// - **Modo Low Power**: Optimizado para batería, 5 eventos/segundo, ideal para sesiones largas
///
/// Ejemplo de uso:
/// ```dart
/// final poseManager = PoseManager();
///
/// // Modo normal
/// poseManager.start();
///
/// // Modo bajo consumo
/// poseManager.start(lowPowerMode: true, throttleHz: 5.0);
///
/// // Escuchar eventos
/// poseManager.stream.listen((data) {
///   utilLog('Heading: ${data.heading}, Lat: ${data.lat}');
/// });
/// ```
class PoseManager {
  static final PoseManager _instance = PoseManager._();
  factory PoseManager() => _instance;
  PoseManager._();

  final NativeEventChannel _channel = NativeEventChannel();
  final _ctrl = StreamController<FusedData>.broadcast();
  StreamSubscription? _nativeSub;

  /// Stream de datos fusionados de sensores (orientación + ubicación)
  Stream<FusedData> get stream => _ctrl.stream;

  // Estado interno
  double? _heading, _pitch, _roll, _lat, _lon, _alt;
  bool _listening = false;

  /// Inicia la escucha de sensores nativos
  ///
  /// [lowPowerMode] - Activa optimizaciones de bajo consumo:
  ///   - Android: Cambia de SENSOR_DELAY_NORMAL a SENSOR_DELAY_UI
  ///   - iOS: Usa kCLLocationAccuracyNearestTenMeters en GPS
  ///   - Reduce frecuencia de eventos para ahorrar batería
  ///
  /// [throttleHz] - Frecuencia de eventos por segundo (por defecto 10Hz en modo normal, 5Hz en lowPowerMode)
  ///   - Valores típicos: 10.0 (normal), 5.0 (bajo consumo), 20.0 (alta frecuencia)
  ///   - En lowPowerMode, se fuerza automáticamente a 5Hz si se especifica un valor mayor
  ///
  /// Beneficios del modo Low Power:
  /// - ~30-40% menos consumo de batería
  /// - Menor calentamiento del dispositivo
  /// - Experiencia más suave y predecible
  /// - Ideal para sesiones largas (>1 hora)
  void start({
    bool lowPowerMode = false,
    double throttleHz = 10.0,
  }) {
    if (_listening) return;

    // En modo bajo consumo, forzar frecuencia a 5Hz máximo
    final effectiveHz = lowPowerMode && throttleHz > 5.0 ? 5.0 : throttleHz;
    final throttleMs = (1000.0 / effectiveHz).round();

    _listening = true;
    _nativeSub = _channel
        .receiveBroadcastStream(
      throttleMs: throttleMs,
      lowPowerMode: lowPowerMode,
    )
        .listen((event) {
      if (event is Map) {
        if (event.containsKey('heading')) _heading = (event['heading'] as num).toDouble();
        if (event.containsKey('pitch')) _pitch = (event['pitch'] as num).toDouble();
        if (event.containsKey('roll')) _roll = (event['roll'] as num).toDouble();
        if (event.containsKey('lat')) _lat = (event['lat'] as num).toDouble();
        if (event.containsKey('lon')) _lon = (event['lon'] as num).toDouble();
        if (event.containsKey('alt')) _alt = (event['alt'] as num).toDouble();

        final ts = event['ts'] ?? DateTime.now().millisecondsSinceEpoch;
        _ctrl.add(FusedData(
            heading: _heading, pitch: _pitch, roll: _roll, lat: _lat, lon: _lon, alt: _alt, ts: (ts as num).toInt()));
      }
    }, onError: (e) => utilLog("Error sensores: $e"));
  }

  /// Detiene la escucha de sensores
  void stop() {
    _nativeSub?.cancel();
    _nativeSub = null;
    _listening = false;
  }

  /// Libera todos los recursos
  void dispose() {
    stop();
    _ctrl.close();
  }
}
