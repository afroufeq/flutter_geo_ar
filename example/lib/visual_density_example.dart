import 'package:flutter/material.dart';
import 'package:flutter_geo_ar/flutter_geo_ar.dart';
import 'package:camera/camera.dart';
import 'package:flutter_geo_ar/src/i18n/strings.g.dart';

/// Ejemplo completo del sistema de Control de Densidad Visual
///
/// Demuestra:
/// - Uso del VisualDensityController
/// - Integración del VisualDensitySlider con GeoArView
/// - Ajuste dinámico de parámetros en tiempo real
/// - Uso de presets predefinidos
class VisualDensityExample extends StatefulWidget {
  const VisualDensityExample({super.key});

  @override
  State<VisualDensityExample> createState() => _VisualDensityExampleState();
}

class _VisualDensityExampleState extends State<VisualDensityExample> {
  // Controlador de densidad visual
  late final VisualDensityController _densityController;

  // Cámara para AR
  CameraDescription? _camera;

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador con densidad normal y callback opcional
    _densityController = VisualDensityController(
      initialDensity: 0.5, // Vista normal por defecto
      onDensityChanged: (density, maxDistance, minImportance, declutterMode) {
        debugPrint('📊 Densidad cambiada a: $density');
        debugPrint('   - Distancia máxima: ${maxDistance.toStringAsFixed(0)}m');
        debugPrint('   - Importancia mínima: $minImportance');
        debugPrint('   - Modo declutter: $declutterMode');
      },
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        setState(() {
          _camera = cameras.first;
        });
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
    }
  }

  @override
  void dispose() {
    _densityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_camera == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return TranslationProvider(
      child: Scaffold(
        body: Stack(
          children: [
            // Vista AR con parámetros controlados por densidad
            ListenableBuilder(
              listenable: _densityController,
              builder: (context, _) {
                return GeoArView(
                  camera: _camera,
                  // Rutas a los archivos de datos
                  demPath: 'assets/data/dem/tenerife_cog.tif',
                  poisPath: 'assets/data/pois/tenerife_pois.json',
                  // Parámetros controlados por el controlador de densidad
                  maxDistance: _densityController.maxDistance,
                  minImportance: _densityController.minImportance,
                  declutterMode: _densityController.declutterMode,
                  // Otras configuraciones
                  showHorizon: true,
                  showDebugOverlay: true,
                  showPerformanceMetrics: true,
                  language: 'es',
                );
              },
            ),

            // Slider de densidad visual superpuesto
            VisualDensitySlider(
              controller: _densityController,
              showDetailedInfo: true, // Mostrar parámetros detallados
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ejemplo alternativo: Configuración previa con preview
///
/// Permite al usuario configurar la densidad antes de abrir la vista AR
class VisualDensityConfigExample extends StatefulWidget {
  const VisualDensityConfigExample({super.key});

  @override
  State<VisualDensityConfigExample> createState() => _VisualDensityConfigExampleState();
}

class _VisualDensityConfigExampleState extends State<VisualDensityConfigExample> {
  final _controller = VisualDensityController(initialDensity: 0.5);
  CameraDescription? _camera;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        setState(() {
          _camera = cameras.first;
        });
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
    }
  }

  void _openArView() {
    if (_camera == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: GeoArView(
            camera: _camera,
            demPath: 'assets/data/dem/tenerife_cog.tif',
            poisPath: 'assets/data/pois/tenerife_pois.json',
            maxDistance: _controller.maxDistance,
            minImportance: _controller.minImportance,
            declutterMode: _controller.declutterMode,
            showHorizon: true,
            language: 'es',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Densidad Visual')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ajusta la densidad visual antes de abrir la vista AR',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Preview de la configuración
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            const Text('Densidad:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('${(_controller.density * 100).round()}%', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                        Slider(value: _controller.density, onChanged: (v) => setState(() => _controller.setDensity(v))),
                        const Divider(),
                        _ConfigRow(
                          label: 'Distancia máxima:',
                          value: '${(_controller.maxDistance / 1000).toStringAsFixed(1)} km',
                        ),
                        _ConfigRow(label: 'Importancia mínima:', value: '≥ ${_controller.minImportance}'),
                        _ConfigRow(label: 'Modo declutter:', value: _controller.declutterMode.name),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botones de presets
            const Text('Presets rápidos:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PresetChip(
                  label: 'Mínima',
                  preset: VisualDensityPreset.minimal,
                  controller: _controller,
                  onTap: () => setState(() {}),
                ),
                _PresetChip(
                  label: 'Baja',
                  preset: VisualDensityPreset.low,
                  controller: _controller,
                  onTap: () => setState(() {}),
                ),
                _PresetChip(
                  label: 'Normal',
                  preset: VisualDensityPreset.normal,
                  controller: _controller,
                  onTap: () => setState(() {}),
                ),
                _PresetChip(
                  label: 'Alta',
                  preset: VisualDensityPreset.high,
                  controller: _controller,
                  onTap: () => setState(() {}),
                ),
                _PresetChip(
                  label: 'Máxima',
                  preset: VisualDensityPreset.maximum,
                  controller: _controller,
                  onTap: () => setState(() {}),
                ),
              ],
            ),

            const Spacer(),

            // Botón para abrir AR
            ElevatedButton.icon(
              onPressed: _camera != null ? _openArView : null,
              icon: const Icon(Icons.camera),
              label: const Text('Abrir Vista AR'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VisualDensityPreset preset;
  final VisualDensityController controller;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.preset, required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = (controller.density - VisualDensityController.getPresetValue(preset)).abs() < 0.01;

    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) {
        controller.setPreset(preset);
        onTap();
      },
    );
  }
}
