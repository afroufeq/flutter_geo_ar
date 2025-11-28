import 'package:flutter/material.dart';
import 'package:flutter_geo_ar/flutter_geo_ar.dart';
import 'package:flutter_geo_ar/src/i18n/strings.g.dart';

/// Ejemplo de uso del indicador de precisión de sensores
///
/// Este ejemplo demuestra cómo integrar el SensorAccuracyIndicator
/// en una aplicación de AR para informar al usuario sobre la calidad
/// de la calibración de la brújula.
class SensorAccuracyExample extends StatefulWidget {
  const SensorAccuracyExample({super.key});

  @override
  State<SensorAccuracyExample> createState() => _SensorAccuracyExampleState();
}

class _SensorAccuracyExampleState extends State<SensorAccuracyExample> {
  final PoseManager _poseManager = PoseManager();
  FusedData? _currentSensorData;

  @override
  void initState() {
    super.initState();
    _initializeSensors();
  }

  void _initializeSensors() {
    // Iniciar sensores en modo normal
    _poseManager.start(lowPowerMode: false, throttleHz: 10.0);

    // Escuchar eventos de sensores
    _poseManager.stream.listen((data) {
      setState(() {
        _currentSensorData = data;
      });

      // Verificar si necesitamos calibración
      _checkAccuracyAndNotify(data);
    });
  }

  void _checkAccuracyAndNotify(FusedData data) {
    final accuracy = SensorAccuracy.fromFusedData(data);

    // Mostrar diálogo si la precisión es muy baja
    if (accuracy == SensorAccuracy.unreliable) {
      _showCalibrationDialog();
    }
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibración necesaria'),
        content: const Text(
          'La brújula necesita calibración. Mueve el dispositivo en forma de "8" o aléjate de objetos metálicos.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
      ),
    );
  }

  @override
  void dispose() {
    _poseManager.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: Scaffold(
        appBar: AppBar(title: const Text('Sensor Accuracy Example')),
        body: Stack(
          children: [
            // Vista AR (simulada para el ejemplo)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.explore, size: 100, color: Colors.white54),
                    const SizedBox(height: 20),
                    Text(
                      'Vista AR',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),

            // Indicador de precisión completo (esquina superior derecha)
            Positioned(
              top: 16,
              right: 16,
              child: SensorAccuracyIndicator(
                sensorData: _currentSensorData,
                showLabel: true,
                onTap: () {
                  final accuracy = SensorAccuracy.fromFusedData(_currentSensorData);
                  if (accuracy == SensorAccuracy.low || accuracy == SensorAccuracy.unreliable) {
                    _showCalibrationDialog();
                  }
                },
              ),
            ),

            // Indicador compacto (esquina superior izquierda)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Brújula: ', style: TextStyle(color: Colors.white, fontSize: 12)),
                    CompactSensorAccuracyIndicator(sensorData: _currentSensorData, onTap: _showCalibrationDialog),
                  ],
                ),
              ),
            ),

            // Información de debug
            Positioned(bottom: 16, left: 16, right: 16, child: _buildDebugInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    if (_currentSensorData == null) {
      return const Card(
        color: Colors.black87,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Esperando datos de sensores...', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final accuracy = SensorAccuracy.fromFusedData(_currentSensorData);

    return Card(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Datos del Sensor',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Heading', '${_currentSensorData!.heading?.toStringAsFixed(1)}°'),
            _buildInfoRow('Pitch', '${_currentSensorData!.pitch?.toStringAsFixed(1)}°'),
            _buildInfoRow('Roll', '${_currentSensorData!.roll?.toStringAsFixed(1)}°'),
            const Divider(color: Colors.white24),
            if (_currentSensorData!.magnetometerAccuracy != null)
              _buildInfoRow('Magnetometer Accuracy (Android)', '${_currentSensorData!.magnetometerAccuracy} (0-3)'),
            if (_currentSensorData!.headingAccuracy != null)
              _buildInfoRow('Heading Accuracy (iOS)', '${_currentSensorData!.headingAccuracy?.toStringAsFixed(1)}°'),
            _buildInfoRow('Nivel de Precisión', accuracy.name.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
