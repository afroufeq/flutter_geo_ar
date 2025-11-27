import 'dart:async';
import '../sensors/pose_manager.dart';
import '../utils/persistent_isolate.dart';
import '../utils/project_worker.dart';
import '../utils/telemetry_service.dart';
import '../utils/logger.dart';

/// Clase que coordina el ciclo de vida completo de una sesión AR.
/// Inicia los sensores, levanta el Isolate de proyección y gestiona la telemetría.
class GeoArSessionManager {
  static final GeoArSessionManager _instance = GeoArSessionManager._();
  factory GeoArSessionManager() => _instance;
  GeoArSessionManager._();

  final PoseManager _poseManager = PoseManager();
  final PersistentIsolate _isolate = PersistentIsolate();
  final TelemetryService _telemetry = TelemetryService();

  bool _isSessionActive = false;

  /// Inicia la sesión: Sensores nativos + Isolate
  Future<void> startSession() async {
    if (_isSessionActive) return;
    _isSessionActive = true;

    // 1. Levantar Isolate para cálculos pesados
    await _isolate.spawn(projectWorkerEntry);

    // 2. Iniciar sensores (EventChannel nativo)
    _poseManager.start();

    utilLog("GeoArSessionManager: Sesión iniciada.");
  }

  /// Detiene todo para ahorrar batería
  void stopSession() {
    if (!_isSessionActive) return;
    _isSessionActive = false;

    _poseManager.stop();
    _isolate.dispose(); // Matar isolate

    utilLog("GeoArSessionManager: Sesión detenida.");
  }

  PoseManager get poseManager => _poseManager;
  PersistentIsolate get isolate => _isolate;
  TelemetryService get telemetry => _telemetry;
}
