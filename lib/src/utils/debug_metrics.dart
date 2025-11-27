/// Clase que contiene todas las métricas del Debug Overlay
class DebugMetrics {
  // Rendimiento
  final double fps;
  final int poisVisible;
  final int poisTotal;
  final double cacheHitRate;
  final double projectionMs;
  final double declutterMs;

  // Filtros
  final int horizonCulledPois;
  final int importanceFilteredPois;
  final int categoryFilteredPois;

  // Sensores
  final double? lat;
  final double? lon;
  final double? alt;
  final double? heading;
  final double? pitch;
  final double? roll;
  final double calibrationOffset;

  // Sistema
  final double memoryMb;
  final int isolateCallbacks;
  final bool cacheActive;

  const DebugMetrics({
    this.fps = 0.0,
    this.poisVisible = 0,
    this.poisTotal = 0,
    this.cacheHitRate = 0.0,
    this.projectionMs = 0.0,
    this.declutterMs = 0.0,
    this.horizonCulledPois = 0,
    this.importanceFilteredPois = 0,
    this.categoryFilteredPois = 0,
    this.lat,
    this.lon,
    this.alt,
    this.heading,
    this.pitch,
    this.roll,
    this.calibrationOffset = 0.0,
    this.memoryMb = 0.0,
    this.isolateCallbacks = 0,
    this.cacheActive = false,
  });

  DebugMetrics copyWith({
    double? fps,
    int? poisVisible,
    int? poisTotal,
    double? cacheHitRate,
    double? projectionMs,
    double? declutterMs,
    int? horizonCulledPois,
    int? importanceFilteredPois,
    int? categoryFilteredPois,
    double? lat,
    double? lon,
    double? alt,
    double? heading,
    double? pitch,
    double? roll,
    double? calibrationOffset,
    double? memoryMb,
    int? isolateCallbacks,
    bool? cacheActive,
  }) {
    return DebugMetrics(
      fps: fps ?? this.fps,
      poisVisible: poisVisible ?? this.poisVisible,
      poisTotal: poisTotal ?? this.poisTotal,
      cacheHitRate: cacheHitRate ?? this.cacheHitRate,
      projectionMs: projectionMs ?? this.projectionMs,
      declutterMs: declutterMs ?? this.declutterMs,
      horizonCulledPois: horizonCulledPois ?? this.horizonCulledPois,
      importanceFilteredPois: importanceFilteredPois ?? this.importanceFilteredPois,
      categoryFilteredPois: categoryFilteredPois ?? this.categoryFilteredPois,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      alt: alt ?? this.alt,
      heading: heading ?? this.heading,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      calibrationOffset: calibrationOffset ?? this.calibrationOffset,
      memoryMb: memoryMb ?? this.memoryMb,
      isolateCallbacks: isolateCallbacks ?? this.isolateCallbacks,
      cacheActive: cacheActive ?? this.cacheActive,
    );
  }
}
