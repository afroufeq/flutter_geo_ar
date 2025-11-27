import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/logger.dart';
import '../sensors/pose_manager.dart';
import '../sensors/fused_data.dart';
import '../utils/persistent_isolate.dart';
import '../utils/project_worker.dart';
import '../poi/poi_model.dart';
import '../poi/poi_painter.dart';
import '../poi/poi_loader.dart';
import '../poi/dem_service.dart';
import '../poi/declutter_mode.dart';
import '../storage/calibration_service.dart';
import '../visual/visual_tracking.dart';
import '../horizon/horizon_generator.dart';
import '../horizon/horizon_painter.dart';
import '../utils/telemetry_service.dart';
import '../i18n/strings.g.dart';
import 'debug_overlay.dart';

class GeoArView extends StatefulWidget {
  final List<Poi> pois;
  final CameraDescription? camera;
  final double focalLength;

  /// Ruta al archivo DEM (Digital Elevation Model) en formato GeoTIFF
  /// Ejemplo: 'assets/data/dem/tenerife_cog.tif'
  final String? demPath;

  /// Ruta al archivo JSON con los POIs (si no se proporcionan directamente)
  /// Ejemplo: 'assets/data/pois/tenerife_pois.json'
  final String? poisPath;

  /// Habilita la visualización de la línea del horizonte
  final bool showHorizon;

  /// Color de la línea del horizonte
  final Color horizonLineColor;

  /// Grosor de la línea del horizonte
  final double horizonLineWidth;

  /// Muestra información de debug sobre el horizonte
  final bool showHorizonDebug;

  /// Modo debug: Oculta la imagen de la cámara pero mantiene los sensores activos
  /// Útil para visualizar mejor los POIs y el horizonte en pruebas
  final bool debugMode;

  /// Modo de estabilización visual usando el giroscopio
  /// - VisualTrackingMode.off: Sin estabilización (máximo ahorro de batería)
  /// - VisualTrackingMode.lite: Estabilización ligera con throttling a 20Hz (por defecto)
  final VisualTrackingMode visualStabilization;

  /// Modo de bajo consumo de energía
  /// Cuando está activado, desactiva automáticamente la estabilización visual
  /// independientemente del valor de visualStabilization
  final bool lowPowerMode;

  /// Muestra el overlay de debug con métricas en tiempo real
  final bool showDebugOverlay;

  /// Muestra la sección de métricas de rendimiento en el debug overlay
  final bool showPerformanceMetrics;

  /// Idioma de la interfaz del plugin ('es' para español, 'en' para inglés)
  /// Por defecto es español ('es')
  final String language;

  /// Modo de declutter para controlar solapamientos entre etiquetas de POIs
  ///
  /// Controla cómo se manejan los solapamientos entre etiquetas:
  /// - DeclutterMode.off: Sin filtrado, muestra todos los POIs
  /// - DeclutterMode.light: Solo evita overlaps grandes (>80%)
  /// - DeclutterMode.normal: Evita cualquier overlap (default)
  /// - DeclutterMode.aggressive: Mayor spacing entre etiquetas
  final DeclutterMode declutterMode;

  /// Distancia máxima en metros para mostrar POIs
  ///
  /// Los POIs que estén más lejos que esta distancia no se mostrarán.
  /// Por defecto es 20000 metros (20 km).
  final double maxDistance;

  /// Importancia mínima de los POIs a mostrar (escala 1-10)
  ///
  /// Los POIs con importancia menor que este valor no se mostrarán.
  /// - 1: Muestra todos los POIs
  /// - 5: Muestra POIs de importancia media y alta (default)
  /// - 10: Solo muestra POIs muy importantes
  final int minImportance;

  const GeoArView({
    super.key,
    this.pois = const [],
    this.camera,
    this.focalLength = 500,
    this.demPath,
    this.poisPath,
    this.showHorizon = true,
    this.horizonLineColor = Colors.yellow,
    this.horizonLineWidth = 2.0,
    this.showHorizonDebug = false,
    this.debugMode = false,
    this.visualStabilization = VisualTrackingMode.lite,
    this.lowPowerMode = false,
    this.showDebugOverlay = false,
    this.showPerformanceMetrics = true,
    this.language = 'es',
    this.declutterMode = DeclutterMode.normal,
    this.maxDistance = 20000.0,
    this.minImportance = 5,
  }) : assert(
          pois.length > 0 || poisPath != null,
          'Debe proporcionar POIs directamente o mediante poisPath',
        );

  @override
  State<GeoArView> createState() => _GeoArViewState();
}

class _GeoArViewState extends State<GeoArView> with WidgetsBindingObserver {
  CameraController? _camController;
  final PoseManager _pose = PoseManager();
  final CalibrationService _calib = CalibrationService();
  final PersistentIsolate _isolate = PersistentIsolate();
  late final VisualTracker _tracker;

  List<Map<String, dynamic>> _projectedPois = [];
  List<Poi> _loadedPois = [];
  double _calibrationOffset = 0.0;
  bool _isCalibrating = false;
  bool _showDebugOverlay = false;
  bool _showCameraInDebug = false; // Controla si se muestra la cámara en modo debug

  // Telemetry service para métricas de debug
  final TelemetryService _telemetry = TelemetryService();

  // Variables para cache de proyecciones
  double? _lastCachedLat;
  double? _lastCachedLon;
  double? _lastCachedHeading;
  List<Map<String, dynamic>>? _cachedProjectedPois;

  // Variables para el horizonte
  HorizonProfile? _horizonProfile;
  HorizonGenerator? _horizonGenerator;
  DemService? _demService;
  FusedData? _currentSensorData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Configurar el idioma del plugin
    _setLanguage(widget.language);

    // Inicializar VisualTracker con configuración adecuada
    // lowPowerMode tiene prioridad y fuerza off independientemente de visualStabilization
    final effectiveMode = widget.lowPowerMode ? VisualTrackingMode.off : widget.visualStabilization;

    _tracker = VisualTracker(mode: effectiveMode);

    // Logging de configuración
    utilLog('[GeoAR] 🔧 Configuración de estabilización visual:');
    utilLog('[GeoAR]    - visualStabilization: ${widget.visualStabilization}');
    utilLog('[GeoAR]    - lowPowerMode: ${widget.lowPowerMode}');
    utilLog('[GeoAR]    - Modo efectivo: $effectiveMode');
    if (widget.lowPowerMode && widget.visualStabilization != VisualTrackingMode.off) {
      utilLog('[GeoAR] ⚡ Modo de bajo consumo activo - estabilización forzada a OFF');
    }

    _initSystem();
  }

  /// Configura el idioma del plugin
  void _setLanguage(String languageCode) {
    try {
      final locale = AppLocale.values.firstWhere(
        (l) => l.languageCode == languageCode,
        orElse: () => AppLocale.es,
      );
      LocaleSettings.setLocale(locale);
      utilLog('[GeoAR] 🌐 Idioma configurado: ${locale.languageCode}');
    } catch (e) {
      utilLog('[GeoAR] ⚠️ Error configurando idioma "$languageCode", usando español por defecto: $e');
      LocaleSettings.setLocale(AppLocale.es);
    }
  }

  Future<void> _initSystem() async {
    await _calib.init();
    _calibrationOffset = await _calib.loadCalibration();

    // Cargar POIs desde archivo si se proporciona poisPath
    if (widget.poisPath != null) {
      try {
        _loadedPois = await PoiLoader.loadFromAsset(widget.poisPath!);
        utilLog('[GeoAR] ✅ POIs cargados desde ${widget.poisPath}: ${_loadedPois.length} POIs');
      } catch (e) {
        utilLog('[GeoAR] ❌ Error cargando POIs: $e');
        _loadedPois = [];
      }
    } else {
      _loadedPois = widget.pois;
      utilLog('[GeoAR] ✅ Usando ${_loadedPois.length} POIs proporcionados directamente');
    }

    // Cargar elevaciones desde DEM si están faltando y hay un DEM disponible
    if (widget.demPath != null) {
      await _loadElevationsFromDem();
    }

    if (widget.camera != null) {
      _camController = CameraController(widget.camera!, ResolutionPreset.medium, enableAudio: false);
      await _camController!.initialize();
    }

    await _isolate.spawn(projectWorkerEntry);
    _tracker.start();

    utilLog('[GeoAR] 🚀 Iniciando PoseManager...');
    _pose.start();
    utilLog('[GeoAR] 🎧 Escuchando stream de sensores...');

    _pose.stream.listen((fused) {
      utilLog('[GeoAR] 📡 Datos recibidos del stream - mounted: $mounted, lat: ${fused.lat}');

      if (!mounted || fused.lat == null) {
        utilLog('[GeoAR] ⚠️ Stream ignorado - mounted: $mounted, lat: ${fused.lat}');
        return;
      }

      // Guardar los datos actuales del sensor para el HorizonPainter
      _currentSensorData = fused;

      // Actualizar métricas de sensores para el debug overlay
      if (widget.showDebugOverlay) {
        _telemetry.updateSensorData(
          lat: fused.lat,
          lon: fused.lon,
          alt: fused.alt,
          heading: fused.heading,
          pitch: fused.pitch,
          roll: fused.roll,
          calibrationOffset: _calibrationOffset,
        );
      }

      final Size size = MediaQuery.of(context).size;

      utilLog(
          '[GeoAR] 📍 Usuario: lat=${fused.lat?.toStringAsFixed(6)}, lon=${fused.lon?.toStringAsFixed(6)}, alt=${fused.alt?.toStringAsFixed(1)}m | heading=${fused.heading?.toStringAsFixed(1)}°, pitch=${fused.pitch?.toStringAsFixed(1)}°');

      // Calcular perfil del horizonte si es necesario
      if (widget.showHorizon && _horizonGenerator != null && _horizonProfile == null) {
        _computeHorizonProfile(fused.lat!, fused.lon!, fused.alt ?? 0.0);
      }

      // Sistema de cache: evitar reprocesar si el usuario está quieto
      bool useCache = false;
      if (_lastCachedLat != null && _lastCachedLon != null && _lastCachedHeading != null) {
        // Diferencias absolutas en coordenadas (aprox. 1° = 111km, usamos umbral de ~2m)
        final latDiff = (fused.lat! - _lastCachedLat!).abs();
        final lonDiff = (fused.lon! - _lastCachedLon!).abs();
        final headingDiff = (fused.heading! - _lastCachedHeading!).abs();

        // Normalizar la diferencia de heading para manejar el wrap-around de 360°
        final normalizedHeadingDiff = headingDiff > 180.0 ? 360.0 - headingDiff : headingDiff;

        // Umbrales: 2m de movimiento (~0.00002°), 2° de rotación
        if (latDiff < 0.00002 && lonDiff < 0.00002 && normalizedHeadingDiff < 2.0) {
          useCache = true;
          if (widget.showDebugOverlay) {
            _telemetry.recordCacheHit();
          }
        } else {
          if (widget.showDebugOverlay) {
            _telemetry.recordCacheMiss();
          }
        }
      } else {
        // Primera iteración, no hay cache disponible
        if (widget.showDebugOverlay) {
          _telemetry.recordCacheMiss();
        }
      }

      // Si podemos usar el cache, evitamos el cómputo
      if (useCache && _cachedProjectedPois != null) {
        utilLog('[GeoAR] 💾 Usando cache de proyección');

        if (widget.showDebugOverlay) {
          // Aún medimos el "frame time" aunque sea cache (será muy rápido)
          final frameStart = DateTime.now();
          final frameEnd = DateTime.now();
          final frameMicros = frameEnd.difference(frameStart).inMicroseconds;
          _telemetry.recordFrameTime(frameMicros);
        }

        setState(() {
          _projectedPois = _cachedProjectedPois!;
        });
        return;
      }

      // No hay cache o los datos cambiaron, procesar normalmente
      final task = {
        'pois': _loadedPois.map((p) => p.toMap()).toList(),
        'sensors': fused.toMap(),
        'userLat': fused.lat ?? 0.0,
        'userLon': fused.lon ?? 0.0,
        'userAlt': fused.alt ?? 0.0,
        'width': size.width,
        'height': size.height,
        'calibration': _calibrationOffset,
        'focal': widget.focalLength,
        'demPath': widget.demPath, // Pasar demPath para el worker
        'maxDistance': widget.maxDistance,
        'minImportance': widget.minImportance,
        'horizonProfile': _horizonProfile?.toMap(), // Enviar perfil del horizonte si está disponible
      };

      final frameStart = DateTime.now();

      _isolate.compute(task).then((result) {
        if (!mounted) return;

        if (result is Map) {
          // Nuevo formato con métricas
          final poisData = result['pois'] as List?;
          final metricsData = result['metrics'] as Map?;

          if (poisData != null) {
            final projected = _tracker.applyOffset(List<Map<String, dynamic>>.from(poisData));

            if (projected.isNotEmpty) {
              utilLog(
                  '[GeoAR] ✅ ${projected.length} POIs proyectados | Ejemplo: ${projected.first['poiName']} en (${projected.first['x']?.toStringAsFixed(1)}, ${projected.first['y']?.toStringAsFixed(1)}) a ${projected.first['distance']?.toStringAsFixed(0)}m');
            } else {
              utilLog('[GeoAR] ⚠️  0 POIs proyectados (pueden estar fuera del campo de visión)');
            }

            // Actualizar métricas para el debug overlay
            if (widget.showDebugOverlay) {
              // Medir FPS
              final frameEnd = DateTime.now();
              final frameMicros = frameEnd.difference(frameStart).inMicroseconds;
              _telemetry.recordFrameTime(frameMicros);

              // Actualizar tiempos de procesamiento desde el worker
              if (metricsData != null) {
                final projectionMs = (metricsData['projectionMs'] as num?)?.toDouble() ?? 0.0;
                final declutterMs = (metricsData['declutterMs'] as num?)?.toDouble() ?? 0.0;

                _telemetry.recordProjectionTime(projectionMs);
                _telemetry.recordDeclutterTime(declutterMs);

                // Actualizar métricas de POIs con estadísticas detalladas
                final totalPois = (metricsData['totalPois'] as num?)?.toInt() ?? _loadedPois.length;
                final behindUser = (metricsData['behindUser'] as num?)?.toInt() ?? 0;
                final tooFar = (metricsData['tooFar'] as num?)?.toInt() ?? 0;
                final horizonCulled = (metricsData['horizonCulled'] as num?)?.toInt() ?? 0;

                _telemetry.updatePoiMetrics(
                  visible: projected.length,
                  total: totalPois,
                  horizonCulled: horizonCulled,
                  importanceFiltered: behindUser, // Reutilizamos este campo para "detrás del usuario"
                  categoryFiltered: tooFar, // Reutilizamos este campo para "demasiado lejos"
                );
              } else {
                // Sin métricas detalladas, usar valores básicos
                _telemetry.updatePoiMetrics(
                  visible: projected.length,
                  total: _loadedPois.length,
                );
              }
            }

            // Actualizar cache
            _lastCachedLat = fused.lat;
            _lastCachedLon = fused.lon;
            _lastCachedHeading = fused.heading;
            _cachedProjectedPois = projected;

            setState(() {
              _projectedPois = projected;
            });
          }
        } else if (result is List) {
          // Formato antiguo (retrocompatibilidad)
          final projected = _tracker.applyOffset(List<Map<String, dynamic>>.from(result));

          if (widget.showDebugOverlay) {
            final frameEnd = DateTime.now();
            final frameMicros = frameEnd.difference(frameStart).inMicroseconds;
            _telemetry.recordFrameTime(frameMicros);

            _telemetry.updatePoiMetrics(
              visible: projected.length,
              total: _loadedPois.length,
            );
          }

          // Actualizar cache (formato antiguo)
          _lastCachedLat = fused.lat;
          _lastCachedLon = fused.lon;
          _lastCachedHeading = fused.heading;
          _cachedProjectedPois = projected;

          setState(() {
            _projectedPois = projected;
          });
        }
      });
    });

    setState(() {});
  }

  /// Calcula el perfil del horizonte de forma asíncrona
  Future<void> _computeHorizonProfile(double lat, double lon, double alt) async {
    if (_horizonGenerator == null) return;

    try {
      utilLog('[GeoAR] 🗻 Calculando perfil del horizonte...');
      final profile = await _horizonGenerator!.compute(lat, lon, alt, angularRes: 2.0);
      if (mounted) {
        setState(() {
          _horizonProfile = profile;
        });
        utilLog('[GeoAR] ✅ Perfil del horizonte calculado: ${profile.angles.length} puntos');
      }
    } catch (e) {
      utilLog('[GeoAR] ❌ Error calculando perfil del horizonte: $e');
    }
  }

  Future<void> _loadElevationsFromDem() async {
    try {
      _demService = DemService();
      utilLog('[GeoAR] 📂 Inicializando DemService con path: ${widget.demPath}');
      await _demService!.init(widget.demPath!);
      utilLog('[GeoAR] ✅ DemService inicializado correctamente');

      int poisUpdated = 0;
      int poisFailed = 0;
      for (var poi in _loadedPois) {
        if (poi.elevation == null) {
          try {
            final elevation = _demService!.getElevation(poi.lat, poi.lon);
            if (elevation != null && elevation > -100 && elevation < 5000) {
              poi.elevation = elevation;
              poisUpdated++;
            } else {
              poisFailed++;
              // Usar una elevación predeterminada razonable para Gran Canaria (nivel medio del terreno)
              poi.elevation = 500.0;
            }
          } catch (e) {
            poisFailed++;
            poi.elevation = 500.0;
            utilLog('[GeoAR] ⚠️  Error obteniendo elevación para POI ${poi.name}: $e');
          }
        }
      }

      utilLog('[GeoAR] 📊 Elevaciones DEM: $poisUpdated POIs actualizados, $poisFailed con valor predeterminado');
      utilLog('[GeoAR] 📊 Total POIs con elevación: ${_loadedPois.where((p) => p.elevation != null).length}');

      // Inicializar el generador de horizonte si showHorizon está habilitado
      if (widget.showHorizon) {
        _horizonGenerator = HorizonGenerator(_demService!);
        utilLog('[GeoAR] ✅ HorizonGenerator inicializado');
      }
    } catch (e) {
      utilLog('[GeoAR] ❌ Error cargando elevaciones desde DEM: $e');
      utilLog('[GeoAR] Stack trace: ${StackTrace.current}');
      // Asignar elevación predeterminada a todos los POIs sin elevación
      for (var poi in _loadedPois) {
        poi.elevation ??= 500.0;
      }
    }
  }

  @override
  void dispose() {
    _pose.stop();
    _tracker.stop();
    _isolate.dispose();
    _camController?.dispose();
    _calib.saveCalibration(_calibrationOffset);
    _calib.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pose.stop();
      _camController?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      _pose.start();
      _camController?.resumePreview();
    }
  }

  /// Construye la vista de cámara escalada para llenar toda la pantalla
  ///
  /// Calcula la relación de aspecto de la cámara vs la pantalla y aplica
  /// una transformación de escala para que la vista ocupe todo el espacio
  /// disponible, similar a BoxFit.cover.
  ///
  /// **Beneficios:**
  /// - Elimina barras negras laterales
  /// - Experiencia inmersiva de pantalla completa
  /// - Compatible con cualquier resolución de cámara y dispositivo
  Widget _buildScaledCameraPreview() {
    // Si está en modo debug Y no se ha activado la vista de cámara, mostrar fondo de debug
    if (widget.debugMode && !_showCameraInDebug) {
      return CustomPaint(
        painter: _DebugBackgroundPainter(),
        child: Container(),
      );
    }

    // Si la cámara está inicializada, usarla
    if (_camController != null && _camController!.value.isInitialized) {
      final size = MediaQuery.of(context).size;

      // Obtener el aspect ratio de la cámara
      var cameraAspectRatio = _camController!.value.aspectRatio;

      // Aspect ratio de la pantalla (height/width porque la cámara está en portrait)
      var screenAspectRatio = size.height / size.width;

      // Calcular la escala necesaria para llenar toda la pantalla
      double scale;
      if (cameraAspectRatio < screenAspectRatio) {
        // La cámara es más "ancha" que la pantalla, escalar por altura
        scale = screenAspectRatio / cameraAspectRatio;
      } else {
        // La cámara es más "alta" que la pantalla, escalar por ancho
        scale = cameraAspectRatio / screenAspectRatio;
      }

      return Transform.scale(
        scale: scale,
        child: Center(
          child: CameraPreview(_camController!),
        ),
      );
    }

    // Sin cámara: mostrar fondo negro
    return Container(color: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    final translations = t;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Botón para alternar cámara/fondo azul solo en modo DEBUG
          if (widget.debugMode && _camController != null && _camController!.value.isInitialized)
            IconButton(
              icon: Icon(
                _showCameraInDebug ? Icons.videocam : Icons.videocam_off,
                color: _showCameraInDebug ? Colors.green : Colors.white,
              ),
              onPressed: () => setState(() => _showCameraInDebug = !_showCameraInDebug),
              tooltip: _showCameraInDebug ? 'Ocultar cámara' : 'Mostrar cámara',
            ),
          if (widget.showDebugOverlay)
            IconButton(
              icon: Icon(
                _showDebugOverlay ? Icons.bug_report : Icons.bug_report_outlined,
                color: _showDebugOverlay ? Colors.green : Colors.white,
              ),
              onPressed: () => setState(() => _showDebugOverlay = !_showDebugOverlay),
              tooltip: _showDebugOverlay ? translations.debug.actions.hideDebug : translations.debug.actions.showDebug,
            ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _isCalibrating = true),
        onHorizontalDragUpdate: (d) => setState(() => _calibrationOffset += d.delta.dx * 0.1),
        onHorizontalDragEnd: (_) {
          setState(() => _isCalibrating = false);
          _calib.saveCalibration(_calibrationOffset);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildScaledCameraPreview(),
            CustomPaint(
              size: Size.infinite,
              painter: PoiPainter(
                _projectedPois,
                debugMode: widget.debugMode,
                declutterMode: widget.declutterMode,
              ),
            ),
            // Dibujar el horizonte si está habilitado y disponible
            if (widget.showHorizon && _horizonProfile != null && _currentSensorData != null)
              CustomPaint(
                size: Size.infinite,
                painter: HorizonPainter(
                  profile: _horizonProfile,
                  sensors: _currentSensorData,
                  focalLength: widget.focalLength,
                  calibration: _calibrationOffset,
                  lineColor: widget.horizonLineColor,
                  lineWidth: widget.horizonLineWidth,
                  showDebugInfo: widget.showHorizonDebug,
                ),
              ),
            if (_isCalibrating)
              Center(
                  child: Text(
                      translations.debug.actions.calibrating
                          .replaceAll('{offset}', _calibrationOffset.toStringAsFixed(1)),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
            // Debug overlay
            if (widget.showDebugOverlay && _showDebugOverlay)
              DebugOverlay(
                showPerformanceMetrics: widget.showPerformanceMetrics,
              ),
          ],
        ),
      ),
    );
  }
}

/// Painter para el fondo de debug - Solo un degradado simple sin elementos estáticos
/// Los POIs y el horizonte se mueven dinámicamente según los sensores del dispositivo
class _DebugBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fondo degradado cielo simple - Sin elementos estáticos
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0F172A), // Azul muy oscuro arriba
        Color(0xFF1E3A8A), // Azul oscuro
        Color(0xFF3B82F6), // Azul medio
        Color(0xFF60A5FA), // Azul claro abajo
      ],
      stops: [0.0, 0.3, 0.6, 1.0],
    );

    final skyPaint = Paint()..shader = skyGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Texto de modo debug en la esquina
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: t.debug.mode.debugMode,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(_DebugBackgroundPainter oldDelegate) => false;
}
