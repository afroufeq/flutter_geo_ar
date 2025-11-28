import 'fused_data.dart';

/// Nivel de precisión del sensor (brújula/magnetómetro)
enum SensorAccuracy {
  /// Alta precisión - Calibración óptima
  high,

  /// Precisión media - Puede requerir calibración
  medium,

  /// Precisión baja - Calibración recomendada
  low,

  /// No fiable - Interferencia magnética detectada, calibración necesaria
  unreliable;

  /// Obtiene el nivel de precisión desde los datos del sensor
  static SensorAccuracy fromFusedData(FusedData? data) {
    if (data == null) return SensorAccuracy.unreliable;

    // Android: usa magnetometerAccuracy (0-3)
    if (data.magnetometerAccuracy != null) {
      switch (data.magnetometerAccuracy!) {
        case 3:
          return SensorAccuracy.high;
        case 2:
          return SensorAccuracy.medium;
        case 1:
          return SensorAccuracy.low;
        default:
          return SensorAccuracy.unreliable;
      }
    }

    // iOS: usa headingAccuracy (grados)
    if (data.headingAccuracy != null) {
      final accuracy = data.headingAccuracy!;

      if (accuracy < 0) {
        return SensorAccuracy.unreliable;
      } else if (accuracy < 10) {
        return SensorAccuracy.high;
      } else if (accuracy < 30) {
        return SensorAccuracy.medium;
      } else if (accuracy < 90) {
        return SensorAccuracy.low;
      } else {
        return SensorAccuracy.unreliable;
      }
    }

    // Sin datos de precisión disponibles aún:
    // - En Android: onAccuracyChanged no se ha llamado todavía
    // - En iOS: didUpdateHeading no se ha recibido aún
    // Asumimos precisión media (optimista) para evitar falsos positivos
    return SensorAccuracy.medium;
  }
}
