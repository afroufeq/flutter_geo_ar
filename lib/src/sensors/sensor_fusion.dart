import 'dart:math';
import 'fused_data.dart';

/// Lógica de fusión complementaria en Dart (opcional si ya viene fusionado de nativo).
/// Útil para suavizar aún más los datos brutos que llegan del canal.
class SensorFusionLogic {
  double _pitch = 0.0;
  double _roll = 0.0;
  static const double alpha = 0.98; // Peso del filtro

  FusedData process(double accelX, double accelY, double accelZ, double gyroX, double gyroY, double gyroZ, double heading, double dt) {
    
    // Pitch/Roll por acelerómetro (gravedad)
    final pitchAcc = atan2(-accelX, sqrt(accelY * accelY + accelZ * accelZ)) * 180 / pi;
    final rollAcc = atan2(accelY, accelZ) * 180 / pi;

    // Integración giroscopio
    _pitch += gyroX * dt * 180 / pi;
    _roll += gyroY * dt * 180 / pi;

    // Fusión
    _pitch = alpha * _pitch + (1 - alpha) * pitchAcc;
    _roll = alpha * _roll + (1 - alpha) * rollAcc;

    return FusedData(
      heading: heading, 
      pitch: _pitch, 
      roll: _roll, 
      ts: DateTime.now().millisecondsSinceEpoch
    );
  }
}