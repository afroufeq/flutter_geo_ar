import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../sensors/pose_manager.dart';
import '../sensors/fused_data.dart';
import '../utils/persistent_isolate.dart';
import '../utils/project_worker.dart';
import '../poi/poi_model.dart';
import '../poi/poi_painter.dart';
import '../poi/poi_loader.dart';
import '../poi/dem_service.dart';
import '../storage/calibration_service.dart';
import '../visual/visual_tracking.dart';
import '../horizon/horizon_generator.dart';
import '../horizon/horizon_painter.dart';

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
  final VisualTracker _tracker = VisualTracker(mode: VisualTrackingMode.lite);

  List<Map<String, dynamic>> _projectedPois = [];
  List<Poi> _loadedPois = [];
  double _calibrationOffset = 0.0;
  bool _isCalibrating = false;

  // Variables para el horizonte
  HorizonProfile? _horizonProfile;
  HorizonGenerator? _horizonGenerator;
  DemService? _demService;
  FusedData? _currentSensorData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSystem();
  }

  Future<void> _initSystem() async {
    await _calib.init();
    _calibrationOffset = await _calib.loadCalibration();

    // Cargar POIs desde archivo si se proporciona poisPath
    if (widget.poisPath != null) {
      try {
        _loadedPois = await PoiLoader.loadFromAsset(widget.poisPath!);
        print('[GeoAR] ✅ POIs cargados desde ${widget.poisPath}: ${_loadedPois.length} POIs');
      } catch (e) {
        print('[GeoAR] ❌ Error cargando POIs: $e');
        _loadedPois = [];
      }
    } else {
      _loadedPois = widget.pois;
      print('[GeoAR] ✅ Usando ${_loadedPois.length} POIs proporcionados directamente');
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

    print('[GeoAR] 🚀 Iniciando PoseManager...');
    _pose.start();
    print('[GeoAR] 🎧 Escuchando stream de sensores...');

    _pose.stream.listen((fused) {
      print('[GeoAR] 📡 Datos recibidos del stream - mounted: $mounted, lat: ${fused.lat}');

      if (!mounted || fused.lat == null) {
        print('[GeoAR] ⚠️ Stream ignorado - mounted: $mounted, lat: ${fused.lat}');
        return;
      }

      // Guardar los datos actuales del sensor para el HorizonPainter
      _currentSensorData = fused;

      final Size size = MediaQuery.of(context).size;

      print(
          '[GeoAR] 📍 Usuario: lat=${fused.lat?.toStringAsFixed(6)}, lon=${fused.lon?.toStringAsFixed(6)}, alt=${fused.alt?.toStringAsFixed(1)}m | heading=${fused.heading?.toStringAsFixed(1)}°, pitch=${fused.pitch?.toStringAsFixed(1)}°');

      // Calcular perfil del horizonte si es necesario
      if (widget.showHorizon && _horizonGenerator != null && _horizonProfile == null) {
        _computeHorizonProfile(fused.lat!, fused.lon!, fused.alt ?? 0.0);
      }

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
      };

      _isolate.compute(task).then((result) {
        if (mounted && result is List) {
          final projected = _tracker.applyOffset(List<Map<String, dynamic>>.from(result));
          if (projected.isNotEmpty) {
            print(
                '[GeoAR] ✅ ${projected.length} POIs proyectados | Ejemplo: ${projected.first['poiName']} en (${projected.first['x']?.toStringAsFixed(1)}, ${projected.first['y']?.toStringAsFixed(1)}) a ${projected.first['distance']?.toStringAsFixed(0)}m');
          } else {
            print('[GeoAR] ⚠️  0 POIs proyectados (pueden estar fuera del campo de visión)');
          }
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
      print('[GeoAR] 🗻 Calculando perfil del horizonte...');
      final profile = await _horizonGenerator!.compute(lat, lon, alt, angularRes: 2.0);
      if (mounted) {
        setState(() {
          _horizonProfile = profile;
        });
        print('[GeoAR] ✅ Perfil del horizonte calculado: ${profile.angles.length} puntos');
      }
    } catch (e) {
      print('[GeoAR] ❌ Error calculando perfil del horizonte: $e');
    }
  }

  Future<void> _loadElevationsFromDem() async {
    try {
      _demService = DemService();
      print('[GeoAR] 📂 Inicializando DemService con path: ${widget.demPath}');
      await _demService!.init(widget.demPath!);
      print('[GeoAR] ✅ DemService inicializado correctamente');

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
            print('[GeoAR] ⚠️  Error obteniendo elevación para POI ${poi.name}: $e');
          }
        }
      }

      print('[GeoAR] 📊 Elevaciones DEM: $poisUpdated POIs actualizados, $poisFailed con valor predeterminado');
      print('[GeoAR] 📊 Total POIs con elevación: ${_loadedPois.where((p) => p.elevation != null).length}');

      // Inicializar el generador de horizonte si showHorizon está habilitado
      if (widget.showHorizon) {
        _horizonGenerator = HorizonGenerator(_demService!);
        print('[GeoAR] ✅ HorizonGenerator inicializado');
      }
    } catch (e) {
      print('[GeoAR] ❌ Error cargando elevaciones desde DEM: $e');
      print('[GeoAR] Stack trace: ${StackTrace.current}');
      // Asignar elevación predeterminada a todos los POIs sin elevación
      for (var poi in _loadedPois) {
        if (poi.elevation == null) {
          poi.elevation = 500.0;
        }
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
    // Si está en modo debug, mostrar fondo de debug aunque la cámara esté inicializada
    if (widget.debugMode) {
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
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
            CustomPaint(size: Size.infinite, painter: PoiPainter(_projectedPois, debugMode: widget.debugMode)),
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
                  child: Text("Calibrando: ${_calibrationOffset.toStringAsFixed(1)}°",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
            SafeArea(
                child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop()))),
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
      text: 'MODO DEBUG',
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));
  }

  @override
  bool shouldRepaint(_DebugBackgroundPainter oldDelegate) => false;
}
