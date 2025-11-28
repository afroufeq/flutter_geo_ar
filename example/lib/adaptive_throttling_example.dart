import 'package:flutter/material.dart';
import 'package:flutter_geo_ar/flutter_geo_ar.dart';
import 'package:flutter_geo_ar/src/i18n/strings.g.dart';

/// Ejemplo de uso del Throttling Adaptativo
///
/// Este ejemplo demuestra cómo usar el throttling adaptativo para optimizar
/// el consumo de batería en aplicaciones AR que alternan entre movimiento y paradas.
///
/// El throttling adaptativo es ideal para:
/// - Senderismo y actividades al aire libre
/// - Turismo con AR
/// - Geocaching
/// - Cualquier app donde el usuario se detiene frecuentemente
class AdaptiveThrottlingExample extends StatefulWidget {
  const AdaptiveThrottlingExample({super.key});

  @override
  State<AdaptiveThrottlingExample> createState() => _AdaptiveThrottlingExampleState();
}

class _AdaptiveThrottlingExampleState extends State<AdaptiveThrottlingExample> {
  final NativeEventChannel _nativeChannel = NativeEventChannel();

  // Estado del sensor
  String _currentMode = 'Desconocido';
  int _currentThrottleMs = 100;
  double _heading = 0.0;
  double _pitch = 0.0;
  double _roll = 0.0;
  double _lat = 0.0;
  double _lon = 0.0;

  // Estadísticas
  int _eventCount = 0;
  DateTime _lastEventTime = DateTime.now();
  int _modeChanges = 0;
  Duration _timeInActive = Duration.zero;
  Duration _timeInStatic = Duration.zero;
  DateTime? _lastModeChangeTime;

  @override
  void initState() {
    super.initState();
    _startAdaptiveSensorStream();
  }

  void _startAdaptiveSensorStream() {
    // Configurar el stream con throttling adaptativo habilitado
    _nativeChannel
        .receiveBroadcastStream(
          throttleMs: 100, // 10 Hz en modo activo (movimiento)
          lowPowerMode: false, // No necesario con adaptive throttling
          adaptiveThrottling: true, // ¡ACTIVAR THROTTLING ADAPTATIVO!
          lowFrequencyMs: 1000, // 1 Hz en modo estático (sin movimiento)
          staticThreshold: 0.1, // Umbral de 0.1 m/s² para detectar movimiento
          staticDurationMs: 2000, // 2 segundos quieto antes de entrar en modo estático
        )
        .listen(
          (dynamic event) {
            if (event is Map) {
              setState(() {
                _eventCount++;
                _lastEventTime = DateTime.now();

                // Detectar cambios de modo
                if (event.containsKey('adaptiveModeChange')) {
                  final String newMode = event['adaptiveModeChange'];
                  _modeChanges++;

                  // Actualizar estadísticas de tiempo
                  if (_lastModeChangeTime != null) {
                    final duration = DateTime.now().difference(_lastModeChangeTime!);
                    if (_currentMode == 'active') {
                      _timeInActive += duration;
                    } else if (_currentMode == 'static') {
                      _timeInStatic += duration;
                    }
                  }

                  _currentMode = newMode;
                  _lastModeChangeTime = DateTime.now();
                }

                // Actualizar throttle actual
                if (event.containsKey('currentThrottleMs')) {
                  _currentThrottleMs = (event['currentThrottleMs'] as num).toInt();
                }

                // Actualizar datos de orientación
                if (event.containsKey('heading')) {
                  _heading = event['heading'];
                }
                if (event.containsKey('pitch')) {
                  _pitch = event['pitch'];
                }
                if (event.containsKey('roll')) {
                  _roll = event['roll'];
                }

                // Actualizar ubicación
                if (event.containsKey('lat')) {
                  _lat = event['lat'];
                }
                if (event.containsKey('lon')) {
                  _lon = event['lon'];
                }
              });
            }
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error en sensores: $error')));
          },
        );
  }

  Color _getModeColor() {
    switch (_currentMode) {
      case 'active':
        return Colors.green;
      case 'static':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getModeIcon() {
    switch (_currentMode) {
      case 'active':
        return Icons.directions_run;
      case 'static':
        return Icons.accessibility_new;
      default:
        return Icons.help_outline;
    }
  }

  String _getModeName() {
    switch (_currentMode) {
      case 'active':
        return 'ACTIVO';
      case 'static':
        return 'ESTÁTICO';
      default:
        return 'DESCONOCIDO';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcular frecuencia actual
    final currentHz = _currentThrottleMs > 0 ? 1000 / _currentThrottleMs : 0;

    // Calcular ahorro estimado de batería
    final totalTime = _timeInActive + _timeInStatic;
    final staticPercentage = totalTime.inMilliseconds > 0
        ? (_timeInStatic.inMilliseconds / totalTime.inMilliseconds) * 100
        : 0.0;
    final estimatedSavings = staticPercentage * 0.7; // ~70% de ahorro en modo estático

    return TranslationProvider(
      child: Scaffold(
        appBar: AppBar(title: const Text('Throttling Adaptativo'), backgroundColor: _getModeColor()),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado actual
              Card(
                color: _getModeColor().withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getModeIcon(), size: 48, color: _getModeColor()),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Modo: ${_getModeName()}', style: Theme.of(context).textTheme.headlineSmall),
                              Text(
                                'Frecuencia: ${currentHz.toStringAsFixed(1)} Hz',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentMode == 'active'
                            ? '🏃 Dispositivo en movimiento - Alta frecuencia'
                            : '🧘 Dispositivo quieto - Ahorrando batería',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Estadísticas
              _buildStatisticsCard(context, staticPercentage, estimatedSavings),
              const SizedBox(height: 16),

              // Datos de sensores
              _buildSensorDataCard(context),
              const SizedBox(height: 16),

              // Información adicional
              _buildInfoCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, double staticPercentage, double estimatedSavings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Estadísticas', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            _buildStatRow('Eventos recibidos:', _eventCount.toString()),
            _buildStatRow('Cambios de modo:', _modeChanges.toString()),
            _buildStatRow('Tiempo en activo:', '${_timeInActive.inSeconds}s'),
            _buildStatRow(
              'Tiempo en estático:',
              '${_timeInStatic.inSeconds}s (${staticPercentage.toStringAsFixed(0)}%)',
            ),
            const Divider(),
            _buildStatRow('Ahorro estimado:', '~${estimatedSavings.toStringAsFixed(0)}% 🔋', highlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Datos de Sensores', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            _buildStatRow('Heading:', '${_heading.toStringAsFixed(1)}°'),
            _buildStatRow('Pitch:', '${_pitch.toStringAsFixed(1)}°'),
            _buildStatRow('Roll:', '${_roll.toStringAsFixed(1)}°'),
            _buildStatRow('Latitud:', _lat.toStringAsFixed(6)),
            _buildStatRow('Longitud:', _lon.toStringAsFixed(6)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text('💡 Cómo funciona', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '• El sistema monitorea el acelerómetro para detectar movimiento\n'
              '• En MODO ACTIVO: Actualiza sensores a 10 Hz (100ms)\n'
              '• En MODO ESTÁTICO: Actualiza sensores a 1 Hz (1000ms)\n'
              '• Cambia a estático tras 2 segundos sin movimiento\n'
              '• Vuelve a activo instantáneamente al detectar movimiento\n'
              '• Ideal para senderismo, turismo y actividades con paradas',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.green : null,
              fontSize: highlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
