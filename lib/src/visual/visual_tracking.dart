import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

enum VisualTrackingMode { off, lite }

class VisualTracker {
  final VisualTrackingMode mode;
  double _offsetX = 0.0, _offsetY = 0.0;
  StreamSubscription? _gyroSub;
  final double pixelPerRadian;

  VisualTracker({this.mode = VisualTrackingMode.off, this.pixelPerRadian = 500.0});

  void start() {
    if (mode == VisualTrackingMode.lite) {
      _gyroSub = gyroscopeEventStream().listen((g) {
        _offsetX += g.y * 0.02 * pixelPerRadian;
        _offsetY += g.x * 0.02 * pixelPerRadian;
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

  List<Map<String, dynamic>> applyOffset(List<Map<String, dynamic>> inPois) {
    if (mode == VisualTrackingMode.off) return inPois;
    for (var p in inPois) {
      p['x'] = (p['x'] as double) + _offsetX;
      p['y'] = (p['y'] as double) + _offsetY;
    }
    return inPois;
  }
}
