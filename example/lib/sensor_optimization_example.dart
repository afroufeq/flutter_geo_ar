import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_geo_ar/flutter_geo_ar.dart';

/// Ejemplo de uso de sensores optimizados con PoseManager
///
/// Demuestra:
/// - Modo normal vs modo bajo consumo
/// - Monitoreo de frecuencia de eventos
/// - Visualización de datos en tiempo real
/// - Gestión del ciclo de vida
class SensorOptimizationExample extends StatefulWidget {
  const SensorOptimizationExample({super.key});

  @override
  State<SensorOptimizationExample> createState() => _SensorOptimizationExampleState();
}

class _SensorOptimizationExampleState extends State<SensorOptimizationExample> with WidgetsBindingObserver {
  final _poseManager = PoseManager();
  StreamSubscription<FusedData>? _subscription;

  // Datos del sensor
  double? _heading;
  double? _pitch;
  double? _roll;
  double? _lat;
  double? _lon;
  double? _alt;

  // Configuración
  bool _lowPowerMode = false;
  double _throttleHz = 10.0;
  bool _isListening = false;

  // Métricas
  int _eventCount = 0;
  DateTime? _startTime;
  double _eventsPerSecond = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSensors();
    _poseManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isListening) {
      _stopSensors();
    } else if (state == AppLifecycleState.resumed && !_isListening) {
      _startSensors();
    }
  }

  void _startSensors() {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _eventCount = 0;
      _startTime = DateTime.now();
    });

    _poseManager.start(lowPowerMode: _lowPowerMode, throttleHz: _throttleHz);

    _subscription = _poseManager.stream.listen(
      _handleSensorData,
      onError: (error) {
        _showError('Error en sensores: $error');
      },
    );

    // Timer para calcular eventos por segundo
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(_startTime!).inSeconds;
      if (elapsed > 0) {
        setState(() {
          _eventsPerSecond = _eventCount / elapsed;
        });
      }
    });
  }

  void _stopSensors() {
    if (!_isListening) return;

    _subscription?.cancel();
    _subscription = null;
    _poseManager.stop();

    setState(() {
      _isListening = false;
    });
  }

  void _handleSensorData(FusedData data) {
    setState(() {
      _heading = data.heading;
      _pitch = data.pitch;
      _roll = data.roll;
      _lat = data.lat;
      _lon = data.lon;
      _alt = data.alt;
      _eventCount++;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Optimización de Sensores'), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigSection(),
            const SizedBox(height: 20),
            _buildControlSection(),
            const SizedBox(height: 20),
            _buildMetricsSection(),
            const SizedBox(height: 20),
            _buildOrientationSection(),
            const SizedBox(height: 20),
            _buildLocationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configuración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Modo Bajo Consumo'),
              subtitle: Text(_lowPowerMode ? 'Activo: Ahorra 30-40% batería' : 'Inactivo: Máxima precisión'),
              value: _lowPowerMode,
              onChanged: _isListening
                  ? null
                  : (value) {
                      setState(() {
                        _lowPowerMode = value;
                        // En modo bajo consumo, forzar a 5Hz máximo
                        if (_lowPowerMode && _throttleHz > 5.0) {
                          _throttleHz = 5.0;
                        }
                      });
                    },
            ),
            const Divider(),
            ListTile(
              title: const Text('Frecuencia de Eventos'),
              subtitle: Text('${_throttleHz.toStringAsFixed(1)} Hz'),
              enabled: !_isListening,
            ),
            Slider(
              value: _throttleHz,
              min: 1.0,
              max: _lowPowerMode ? 5.0 : 20.0,
              divisions: _lowPowerMode ? 4 : 19,
              label: '${_throttleHz.toStringAsFixed(1)} Hz',
              onChanged: _isListening
                  ? null
                  : (value) {
                      setState(() {
                        _throttleHz = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _isListening ? null : _startSensors,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
            ElevatedButton.icon(
              onPressed: _isListening ? _stopSensors : null,
              icon: const Icon(Icons.stop),
              label: const Text('Detener'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Card(
      color: _isListening ? Colors.green.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isListening ? Icons.sensors : Icons.sensors_off,
                  color: _isListening ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _isListening ? 'Sensores Activos' : 'Sensores Inactivos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isListening ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            if (_isListening) ...[
              const SizedBox(height: 12),
              _buildMetricRow('Eventos totales', '$_eventCount'),
              _buildMetricRow('Eventos/segundo', _eventsPerSecond.toStringAsFixed(2)),
              _buildMetricRow(
                'Tiempo transcurrido',
                _startTime != null ? '${DateTime.now().difference(_startTime!).inSeconds}s' : '--',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildOrientationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Orientación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDataRow('Heading', _heading, '°', 1),
            _buildDataRow('Pitch', _pitch, '°', 1),
            _buildDataRow('Roll', _roll, '°', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ubicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDataRow('Latitud', _lat, '', 6),
            _buildDataRow('Longitud', _lon, '', 6),
            _buildDataRow('Altitud', _alt, 'm', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, double? value, String unit, int decimals) {
    final valueText = value != null ? '${value.toStringAsFixed(decimals)}$unit' : '--';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(valueText, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
        ],
      ),
    );
  }
}
