import 'dart:collection';
import 'dart:developer';
import 'debug_metrics.dart';

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._();
  factory TelemetryService() => _instance;
  TelemetryService._();

  // Frame timing
  final Queue<int> _frameTimes = Queue<int>();
  final int _maxSamples = 60; // 60 frames para cálculo de FPS

  // Performance metrics
  double _projectionMs = 0.0;
  double _declutterMs = 0.0;

  // Cache metrics
  int _cacheHits = 0;
  int _cacheMisses = 0;

  // POI metrics
  int _poisVisible = 0;
  int _poisTotal = 0;
  int _horizonCulledPois = 0;
  int _importanceFilteredPois = 0;
  int _categoryFilteredPois = 0;

  // Sensor data
  double? _lat;
  double? _lon;
  double? _alt;
  double? _heading;
  double? _pitch;
  double? _roll;
  double _calibrationOffset = 0.0;

  // System metrics
  int _callbacks = 0;

  // Public getter for callbacks
  int get callbacks => _callbacks;

  // Record frame time (in microseconds)
  void recordFrameTime(int microseconds) {
    _frameTimes.addLast(microseconds);
    if (_frameTimes.length > _maxSamples) {
      _frameTimes.removeFirst();
    }
  }

  // Record projection time (in milliseconds)
  void recordProjectionTime(double ms) {
    _projectionMs = ms;
  }

  // Record declutter time (in milliseconds)
  void recordDeclutterTime(double ms) {
    _declutterMs = ms;
  }

  // Record cache hit
  void recordCacheHit() {
    _cacheHits++;
  }

  // Record cache miss
  void recordCacheMiss() {
    _cacheMisses++;
  }

  // Update POI metrics
  void updatePoiMetrics({
    required int visible,
    required int total,
    int horizonCulled = 0,
    int importanceFiltered = 0,
    int categoryFiltered = 0,
  }) {
    _poisVisible = visible;
    _poisTotal = total;
    _horizonCulledPois = horizonCulled;
    _importanceFilteredPois = importanceFiltered;
    _categoryFilteredPois = categoryFiltered;
  }

  // Update sensor data
  void updateSensorData({
    double? lat,
    double? lon,
    double? alt,
    double? heading,
    double? pitch,
    double? roll,
    double calibrationOffset = 0.0,
  }) {
    _lat = lat;
    _lon = lon;
    _alt = alt;
    _heading = heading;
    _pitch = pitch;
    _roll = roll;
    _calibrationOffset = calibrationOffset;
  }

  // Tick callback counter
  void tickCallback() {
    _callbacks++;
  }

  // Calculate average frame time in milliseconds
  double avgFrameMs() {
    if (_frameTimes.isEmpty) return 0.0;
    final avgMicros = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    return avgMicros / 1000.0; // Convert to milliseconds
  }

  // Calculate FPS
  double get fps {
    final avgMs = avgFrameMs();
    if (avgMs == 0.0) return 0.0;
    return 1000.0 / avgMs;
  }

  // Calculate cache hit rate (0.0 to 1.0)
  double get cacheHitRate {
    final total = _cacheHits + _cacheMisses;
    if (total == 0) return 0.0;
    return _cacheHits / total;
  }

  // Get current metrics
  DebugMetrics getMetrics() {
    return DebugMetrics(
      fps: fps,
      poisVisible: _poisVisible,
      poisTotal: _poisTotal,
      cacheHitRate: cacheHitRate,
      projectionMs: _projectionMs,
      declutterMs: _declutterMs,
      horizonCulledPois: _horizonCulledPois,
      importanceFilteredPois: _importanceFilteredPois,
      categoryFilteredPois: _categoryFilteredPois,
      lat: _lat,
      lon: _lon,
      alt: _alt,
      heading: _heading,
      pitch: _pitch,
      roll: _roll,
      calibrationOffset: _calibrationOffset,
      isolateCallbacks: _callbacks,
      cacheActive: cacheHitRate > 0.0,
    );
  }

  // Debug logging
  void debugLog() {
    log('Telemetry: FPS: ${fps.toStringAsFixed(1)} | '
        'POIs: $_poisVisible/$_poisTotal | '
        'Cache: ${(cacheHitRate * 100).toStringAsFixed(0)}% | '
        'Projection: ${_projectionMs.toStringAsFixed(1)}ms | '
        'Callbacks: $_callbacks');
  }

  // Reset all metrics (useful for tests)
  void reset() {
    _frameTimes.clear();
    _projectionMs = 0.0;
    _declutterMs = 0.0;
    _cacheHits = 0;
    _cacheMisses = 0;
    _poisVisible = 0;
    _poisTotal = 0;
    _horizonCulledPois = 0;
    _importanceFilteredPois = 0;
    _categoryFilteredPois = 0;
    _lat = null;
    _lon = null;
    _alt = null;
    _heading = null;
    _pitch = null;
    _roll = null;
    _calibrationOffset = 0.0;
    _callbacks = 0;
  }
}
