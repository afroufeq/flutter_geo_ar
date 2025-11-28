import 'package:flutter/material.dart';
import 'package:flutter_geo_ar/flutter_geo_ar.dart';
import 'package:camera/camera.dart';
import 'package:flutter_geo_ar/src/i18n/strings.g.dart';

/// Ejemplo de uso del botón de visualización de líneas DEM en modo debug
///
/// Este ejemplo demuestra:
/// - Botón de toggle para mostrar/ocultar líneas de DEM (capas de terreno)
/// - Visualización de capas de terreno a diferentes distancias (500m, 2km, 5km, 10km)
/// - Las líneas de DEM se superponen sobre la vista AR mostrando el perfil del terreno
/// - Visualización del slider de densidad visual para controlar filtros de POIs
class DebugViewAllExample extends StatefulWidget {
  const DebugViewAllExample({super.key});

  @override
  State<DebugViewAllExample> createState() => _DebugViewAllExampleState();
}

class _DebugViewAllExampleState extends State<DebugViewAllExample> {
  CameraDescription? _camera;
  bool _isInitialized = false;
  bool _showHelpInfo = true;
  final VisualDensityController _densityController = VisualDensityController(
    initialDensity: 0.5, // Densidad normal por defecto
  );

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      setState(() {
        _camera = cameras.first;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _densityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return TranslationProvider(
      child: Scaffold(
        body: Stack(
          children: [
            // Vista AR con debug overlay habilitado
            ListenableBuilder(
              listenable: _densityController,
              builder: (context, _) {
                return GeoArView(
                  camera: _camera,
                  poisPath: 'assets/data/pois/gran_canaria_pois.json',
                  demPath: 'assets/data/dem/gran_canaria_cog.tif',
                  focalLength: 500,

                  // Configuración de debug
                  debugMode: true,
                  showDebugOverlay: true,
                  showPerformanceMetrics: true,

                  // Configuración de visualización controlada por el slider
                  maxDistance: _densityController.maxDistance,
                  minImportance: _densityController.minImportance,
                  declutterMode: _densityController.declutterMode,

                  // Mostrar horizonte
                  showHorizon: true,
                  horizonLineColor: Colors.yellow,
                  horizonLineWidth: 2.0,
                  showHorizonDebug: false,

                  // Habilitar capas de terreno (controladas por el botón DEM en modo debug)
                  showTerrainLayers: false, // El botón en modo debug controla esto dinámicamente
                  showTerrainLabels: true,

                  // Idioma
                  language: 'es',
                );
              },
            ),

            // Slider de densidad visual
            VisualDensitySlider(
              controller: _densityController,
              showDetailedInfo: true,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 90),
            ),

            // Información de ayuda
            if (_showHelpInfo)
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '🗻 Modo Debug: Líneas de DEM',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => setState(() => _showHelpInfo = false),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Cerrar',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Toca el botón de terreno (🗻) para mostrar/ocultar líneas DEM\n'
                        '• Las líneas muestran el perfil del terreno a diferentes distancias\n'
                        '• Colores: Rojo (500m), Verde (2km), Cian (5km), Amarillo (10km)\n'
                        '• Toca el botón de debug (🐛) para ver métricas de rendimiento\n'
                        '• Ajusta el slider para cambiar la densidad visual de POIs',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
