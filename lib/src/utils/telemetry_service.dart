import 'dart:collection';
import 'dart:developer';

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._();
  factory TelemetryService() => _instance;
  TelemetryService._();

  final Queue<int> _frameTimes = Queue<int>();
  final int _maxSamples = 200;
  int callbacks = 0;

  void recordFrameTime(int ms) {
    _frameTimes.addLast(ms);
    if (_frameTimes.length > _maxSamples) _frameTimes.removeFirst();
  }

  double avgFrameMs() {
    if (_frameTimes.isEmpty) return 0.0;
    return _frameTimes.reduce((a,b)=>a+b) / _frameTimes.length;
  }

  void tickCallback() {
    callbacks++;
  }

  void debugLog() {
    log('Telemetry: Avg Frame: ${avgFrameMs().toStringAsFixed(1)}ms | Callbacks: $callbacks');
  }
}