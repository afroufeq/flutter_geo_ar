import 'dart:math';
import 'package:flutter/material.dart';
import 'horizon_generator.dart';
import '../sensors/fused_data.dart';

/// Painter que dibuja la silueta del horizonte sobre la vista AR
///
/// Proyecta el perfil del horizonte calculado en coordenadas de pantalla
/// para crear una línea que coincide con las montañas reales visibles.
class HorizonPainter extends CustomPainter {
  final HorizonProfile? profile;
  final FusedData? sensors;
  final double focalLength;
  final double calibration;
  final Color lineColor;
  final double lineWidth;
  final bool showDebugInfo;

  HorizonPainter({
    required this.profile,
    required this.sensors,
    this.focalLength = 500.0,
    this.calibration = 0.0,
    this.lineColor = Colors.yellow,
    this.lineWidth = 2.0,
    this.showDebugInfo = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (profile == null || sensors == null) return;
    if (sensors!.heading == null || sensors!.pitch == null) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    bool firstPoint = true;

    // Obtener el heading actual (con calibración)
    final currentHeading = ((sensors!.heading! + calibration) % 360.0);
    final currentPitch = sensors!.pitch!;

    // Convertir pitch a radianes con ajuste para uso en posición vertical
    // Sumar 90° porque el pitch es negativo cuando el dispositivo está vertical
    // pitch=-90° (vertical) + 90° = 0° → Ver horizonte al frente
    // pitch=0° (horizontal) + 90° = 90° → Mirar arriba (no ver horizonte)
    final pitchRad = (currentPitch + 90.0) * pi / 180.0;
    final cosPitch = cos(pitchRad);
    final sinPitch = sin(pitchRad);

    // Recorrer cada píxel horizontal de la pantalla
    final int screenWidth = size.width.toInt();

    for (int screenX = 0; screenX < screenWidth; screenX++) {
      // Calcular el ángulo de bearing para este píxel
      // La pantalla va de -FOV/2 a +FOV/2 respecto al heading actual
      final double fov = 2 * atan(size.width / (2 * focalLength)) * 180 / pi;
      final double bearingOffset = (screenX - size.width / 2) / size.width * fov;
      double bearing = (currentHeading + bearingOffset) % 360.0;
      if (bearing < 0) bearing += 360.0;

      // Obtener la elevación del horizonte para este bearing
      final int idx = (bearing / profile!.step).floor() % profile!.angles.length;
      final double horizonElevation = profile!.angles[idx];

      // Convertir el ángulo de elevación del horizonte a radianes
      final elevationRad = horizonElevation * pi / 180.0;

      // Simular un punto del horizonte a gran distancia (1000m) para mantener proporciones
      final distance = 1000.0;

      // Calcular el offset angular desde el heading actual
      final angleDiff = (bearing - currentHeading) * pi / 180.0;

      // Coordenadas 3D del punto del horizonte (en sistema rotado por heading)
      // Ignoramos la componente X (lateral) ya que solo nos interesa la altura en pantalla
      final y = distance * cos(angleDiff); // Distancia frontal
      final z = distance * sin(elevationRad); // Altura según elevación del terreno

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

      // Proyección perspectiva corregida
      final double screenY = size.height / 2 - (zRotated / yRotated) * focalLength;

      // Solo dibujar si está dentro de los límites de la pantalla
      if (screenY >= -50 && screenY <= size.height + 50) {
        if (firstPoint) {
          path.moveTo(screenX.toDouble(), screenY);
          firstPoint = false;
        } else {
          path.lineTo(screenX.toDouble(), screenY);
        }
      } else if (!firstPoint) {
        // Si salimos de los límites, empezar un nuevo segmento
        firstPoint = true;
      }
    }

    canvas.drawPath(path, paint);

    // Información de debug opcional
    if (showDebugInfo) {
      _drawDebugInfo(canvas, size, currentHeading, currentPitch);
    }
  }

  void _drawDebugInfo(Canvas canvas, Size size, double heading, double pitch) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final debugText = 'Heading: ${heading.toStringAsFixed(1)}° | '
        'Pitch: ${pitch.toStringAsFixed(1)}° | '
        'Profile: ${profile!.angles.length} points';

    textPainter.text = TextSpan(
      text: debugText,
      style: const TextStyle(
        color: Colors.yellow,
        fontSize: 12,
        backgroundColor: Colors.black54,
      ),
    );

    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(HorizonPainter oldDelegate) {
    // Repintar si cambia el perfil, los sensores o la configuración visual
    return profile != oldDelegate.profile ||
        sensors != oldDelegate.sensors ||
        calibration != oldDelegate.calibration ||
        focalLength != oldDelegate.focalLength ||
        lineColor != oldDelegate.lineColor ||
        lineWidth != oldDelegate.lineWidth ||
        showDebugInfo != oldDelegate.showDebugInfo;
  }
}
