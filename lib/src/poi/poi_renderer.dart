import 'dart:math';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import 'poi_model.dart';
import '../sensors/fused_data.dart';

class RenderedPoi {
  final double x, y, size, distance;
  final Poi poi;
  RenderedPoi({required this.x, required this.y, required this.size, required this.poi, required this.distance});
}

class PoiRenderer {
  double focalLength;
  double maxDistance;
  PoiRenderer({this.focalLength = 520.0, this.maxDistance = 20000.0});

  List<RenderedPoi> projectPois(
      List<Poi> pois, double userLat, double userLon, double userAlt, FusedData sensors, Size screenSize,
      {double calibration = 0.0}) {
    final out = <RenderedPoi>[];
    final radUserLat = radians(userLat);
    final cosUserLat = cos(radUserLat);
    final headingRad = radians(((sensors.heading ?? 0) + calibration) % 360.0);
    final cosH = cos(headingRad);
    final sinH = sin(headingRad);

    // Convertir pitch a radianes con ajuste para uso en posición vertical
    // Sumar 90° porque el pitch es negativo cuando el dispositivo está vertical
    // pitch=-90° (vertical) + 90° = 0° → Ver horizonte al frente
    // pitch=0° (horizontal) + 90° = 90° → Mirar arriba (no ver horizonte)
    final pitchRad = radians((sensors.pitch ?? 0) + 90.0);
    final cosPitch = cos(pitchRad);
    final sinPitch = sin(pitchRad);

    for (final p in pois) {
      final dx = (p.lon - userLon) * (111320.0 * cosUserLat);
      final dy = (p.lat - userLat) * 110540.0;
      final dz = (p.elevation ?? 0.0) - userAlt;

      // Rotar por heading (azimuth)
      final rx = dx * cosH - dy * sinH;
      final ry = dx * sinH + dy * cosH;

      // Aplicar rotación de pitch (el dispositivo está inclinado)
      // Cuando pitch es 0° (horizontal): miramos al frente
      // Cuando pitch es 90° (vertical hacia arriba): miramos arriba
      // Cuando pitch es -90° (vertical hacia abajo): miramos abajo
      final rzRotated = ry * cosPitch - dz * sinPitch;
      final dzRotated = ry * sinPitch + dz * cosPitch;

      // Solo proyectar si está delante del usuario
      if (rzRotated <= 0) continue;

      final dist = sqrt(dx * dx + dy * dy + dz * dz);
      if (dist > maxDistance) continue;

      // Proyección perspectiva corregida
      final px = screenSize.width / 2 + (rx / rzRotated) * focalLength;
      final py = screenSize.height / 2 - (dzRotated / rzRotated) * focalLength;

      out.add(RenderedPoi(x: px, y: py, size: 22 + p.importance.toDouble(), poi: p, distance: dist));
    }
    return out;
  }
}
