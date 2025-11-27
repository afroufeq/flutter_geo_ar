import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../poi/poi_renderer.dart'; // Para RenderedPoi

enum VisualTrackingMode { off, lite }

class VisualTracker {
  final VisualTrackingMode mode;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  StreamSubscription? _gyroSub;
  final double pixelPerRadian;

  VisualTracker({this.mode = VisualTrackingMode.off, this.pixelPerRadian = 500.0});

  void start() {
    if (mode == VisualTrackingMode.lite) {
      // Usamos giroscopio para estimar desplazamiento de píxeles (fake optical flow)
      // Esto suaviza el jitter visual.
      _gyroSub = gyroscopeEventStream().listen((g) {
        // g.y (rotación eje Y) -> movimiento X en pantalla
        // g.x (rotación eje X) -> movimiento Y en pantalla
        _offsetX += g.y * 0.02 * pixelPerRadian;
        _offsetY += g.x * 0.02 * pixelPerRadian;

        // Decay (retorno al centro suave) para evitar deriva infinita
        _offsetX *= 0.94;
        _offsetY *= 0.94;
      });
    }
  }

  void stop() {
    _gyroSub?.cancel();
    _offsetX = 0.0;
    _offsetY = 0.0;
  }

  // Aplica el offset calculado a los POIs proyectados
  List<RenderedPoi> applyOffset(List<RenderedPoi> inPois) {
    if (mode == VisualTrackingMode.off) return inPois;
    return inPois
        .map((p) => RenderedPoi(x: p.x + _offsetX, y: p.y + _offsetY, size: p.size, poi: p.poi, distance: p.distance))
        .toList();
  }
}
