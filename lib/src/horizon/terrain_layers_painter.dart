import 'dart:math';
import 'package:flutter/material.dart';
import '../poi/dem_service.dart';
import '../sensors/fused_data.dart';

/// Define una capa de terreno a una distancia específica
class TerrainLayer {
  final double distance; // Distancia en metros
  final Color color;
  final double strokeWidth;
  final String label;

  const TerrainLayer({
    required this.distance,
    required this.color,
    this.strokeWidth = 1.5,
    this.label = '',
  });
}

/// Painter que dibuja múltiples capas del perfil del terreno
/// Similar a HorizonPainter pero con varias líneas a diferentes distancias
class TerrainLayersPainter extends CustomPainter {
  final DemService dem;
  final FusedData? sensors;
  final double focalLength;
  final double calibration;
  final List<TerrainLayer> layers;
  final bool showLabels;

  TerrainLayersPainter({
    required this.dem,
    required this.sensors,
    this.focalLength = 500.0,
    this.calibration = 0.0,
    required this.layers,
    this.showLabels = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sensors == null) return;
    if (sensors!.heading == null || sensors!.pitch == null) return;
    if (sensors!.lat == null || sensors!.lon == null) return;

    // Obtener el heading actual (con calibración)
    final currentHeading = ((sensors!.heading! + calibration) % 360.0);
    final currentPitch = sensors!.pitch!;
    final userLat = sensors!.lat!;
    final userLon = sensors!.lon!;
    final userAlt = sensors!.alt ?? 0.0;

    // Convertir pitch a radianes con ajuste para uso en posición vertical
    final pitchRad = (currentPitch + 90.0) * pi / 180.0;
    final cosPitch = cos(pitchRad);
    final sinPitch = sin(pitchRad);

    final int screenWidth = size.width.toInt();

    // Dibujar cada capa de terreno
    for (final layer in layers) {
      final paint = Paint()
        ..color = layer.color
        ..strokeWidth = layer.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      bool firstPoint = true;
      double? labelX;
      double? labelY;

      // Recorrer cada píxel horizontal de la pantalla
      for (int screenX = 0; screenX < screenWidth; screenX++) {
        // Calcular el ángulo de bearing para este píxel
        final double fov = 2 * atan(size.width / (2 * focalLength)) * 180 / pi;
        final double bearingOffset = (screenX - size.width / 2) / size.width * fov;
        double bearing = (currentHeading + bearingOffset) % 360.0;
        if (bearing < 0) bearing += 360.0;

        // Calcular destino a la distancia de esta capa
        final dest = _destination(userLat, userLon, layer.distance, bearing);

        // Obtener elevación del terreno en ese punto
        final terrainAlt = dem.getElevation(dest[0], dest[1]);

        if (terrainAlt == null) {
          if (!firstPoint) {
            firstPoint = true;
          }
          continue;
        }

        // Calcular ángulo de elevación del terreno relativo al observador
        final elevationAngle = atan2(terrainAlt - userAlt, layer.distance) * 180 / pi;
        final elevationRad = elevationAngle * pi / 180.0;

        // Calcular el offset angular desde el heading actual
        final angleDiff = (bearing - currentHeading) * pi / 180.0;

        // Coordenadas 3D del punto del terreno
        final y = layer.distance * cos(angleDiff); // Distancia frontal
        final z = layer.distance * sin(elevationRad); // Altura según elevación del terreno

        // Aplicar rotación de pitch
        final yRotated = y * cosPitch - z * sinPitch;
        final zRotated = y * sinPitch + z * cosPitch;

        // Solo dibujar si está delante (yRotated > 0)
        if (yRotated <= 0) {
          if (!firstPoint) {
            firstPoint = true;
          }
          continue;
        }

        // Proyección perspectiva
        final double screenY = size.height / 2 - (zRotated / yRotated) * focalLength;

        // Solo dibujar si está dentro de los límites de la pantalla
        if (screenY >= -50 && screenY <= size.height + 50) {
          if (firstPoint) {
            path.moveTo(screenX.toDouble(), screenY);
            firstPoint = false;
          } else {
            path.lineTo(screenX.toDouble(), screenY);
          }

          // Guardar posición para etiqueta cuando estamos cerca del centro de la pantalla
          if (labelX == null && screenX >= (size.width / 2 - 10) && screenX <= (size.width / 2 + 10)) {
            labelX = size.width / 2;
            labelY = screenY;
          }
        } else if (!firstPoint) {
          firstPoint = true;
        }
      }

      canvas.drawPath(path, paint);

      // Dibujar etiqueta si está habilitado y tenemos una posición válida
      if (showLabels && labelX != null && labelY != null && layer.label.isNotEmpty) {
        _drawLabel(canvas, layer.label, labelX, labelY, layer.color);
      }
    }
  }

  /// Dibuja una etiqueta de texto sutil para identificar la capa
  void _drawLabel(Canvas canvas, String text, double x, double y, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.6),
            offset: const Offset(0.5, 0.5),
            blurRadius: 1.5,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Centrar la etiqueta horizontalmente y posicionarla justo encima de la línea
    final offset = Offset(x - textPainter.width / 2, y - textPainter.height - 4);

    // Dibujar fondo semi-transparente sutil
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        offset.dx - 3,
        offset.dy - 1,
        textPainter.width + 6,
        textPainter.height + 2,
      ),
      const Radius.circular(3),
    );

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(bgRect, bgPaint);

    // Dibujar texto
    textPainter.paint(canvas, offset);
  }

  /// Calcula las coordenadas de destino dados un punto de origen, distancia y bearing
  List<double> _destination(double lat, double lon, double dist, double bearing) {
    const R = 6371000.0; // Radio de la Tierra en metros
    double latRad = lat * pi / 180;
    double lonRad = lon * pi / 180;
    double bRad = bearing * pi / 180;

    double lat2 = asin(sin(latRad) * cos(dist / R) + cos(latRad) * sin(dist / R) * cos(bRad));
    double lon2 = lonRad + atan2(sin(bRad) * sin(dist / R) * cos(latRad), cos(dist / R) - sin(latRad) * sin(lat2));

    return [lat2 * 180 / pi, lon2 * 180 / pi];
  }

  @override
  bool shouldRepaint(TerrainLayersPainter oldDelegate) {
    return sensors != oldDelegate.sensors ||
        calibration != oldDelegate.calibration ||
        focalLength != oldDelegate.focalLength ||
        layers != oldDelegate.layers ||
        showLabels != oldDelegate.showLabels;
  }
}
