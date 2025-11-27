import 'dart:math';
import '../poi/dem_service.dart';

class HorizonProfile {
  final List<double> angles; // Ángulo máx de elevación por grado (0..359)
  final double step;

  HorizonProfile(this.angles, this.step);

  /// Convierte a Map para serialización (útil para enviar a isolates)
  Map<String, dynamic> toMap() {
    return {
      'angles': angles,
      'step': step,
    };
  }

  /// Crea desde Map (útil para recibir de isolates)
  factory HorizonProfile.fromMap(Map<String, dynamic> map) {
    return HorizonProfile(
      List<double>.from(map['angles'] as List),
      (map['step'] as num).toDouble(),
    );
  }

  /// Comprueba si un punto (dado por su rumbo y ángulo de elevación) está oculto.
  /// [toleranceDeg] permite un margen de error para evitar parpadeo en bordes.
  bool isOccluded(double bearing, double elevationAngle, {double toleranceDeg = 0.5}) {
    double b = bearing % 360.0;
    if (b < 0) b += 360.0;

    int idx = (b / step).floor();
    if (idx >= angles.length) idx = 0;

    // Oculto si el ángulo del POI es menor que el del horizonte (montaña)
    return elevationAngle < (angles[idx] - toleranceDeg);
  }
}

class HorizonGenerator {
  final DemService dem;
  final int raySteps;
  final double stepMeters;

  HorizonGenerator(this.dem, {this.raySteps = 100, this.stepMeters = 100.0});

  /// Calcula el perfil completo del horizonte (360 grados).
  /// Ejecutar preferiblemente en un Isolate.
  Future<HorizonProfile> compute(double lat, double lon, double alt, {double angularRes = 1.0}) async {
    final int steps = (360 / angularRes).ceil();
    final List<double> angles = List.filled(steps, -90.0);

    for (int i = 0; i < steps; i++) {
      double bearing = i * angularRes;
      double maxAngle = -90.0;

      // Raycasting: Avanzamos en distancia para encontrar el punto más alto angularmente
      for (int j = 1; j <= raySteps; j++) {
        double dist = j * stepMeters;
        var dest = _destination(lat, lon, dist, bearing);

        double? terrainAlt = dem.getElevation(dest[0], dest[1]);

        if (terrainAlt != null) {
          // Ángulo relativo al observador
          double angle = atan2(terrainAlt - alt, dist) * 180 / pi;
          if (angle > maxAngle) maxAngle = angle;
        }
      }
      angles[i] = maxAngle;
    }
    return HorizonProfile(angles, angularRes);
  }

  List<double> _destination(double lat, double lon, double dist, double bearing) {
    const R = 6371000.0;
    double latRad = lat * pi / 180;
    double lonRad = lon * pi / 180;
    double bRad = bearing * pi / 180;

    double lat2 = asin(sin(latRad) * cos(dist / R) + cos(latRad) * sin(dist / R) * cos(bRad));
    double lon2 = lonRad + atan2(sin(bRad) * sin(dist / R) * cos(latRad), cos(dist / R) - sin(latRad) * sin(lat2));

    return [lat2 * 180 / pi, lon2 * 180 / pi];
  }
}
