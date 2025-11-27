import 'package:flutter/material.dart';
import '../sensors/fused_data.dart';
import '../sensors/sensor_accuracy.dart';
import '../i18n/strings.g.dart';

/// Widget que muestra el estado de precisión de los sensores
class SensorAccuracyIndicator extends StatelessWidget {
  final FusedData? sensorData;
  final bool showLabel;
  final double size;
  final VoidCallback? onTap;

  const SensorAccuracyIndicator({
    super.key,
    required this.sensorData,
    this.showLabel = false,
    this.size = 24.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = SensorAccuracy.fromFusedData(sensorData);
    final t = Translations.of(context);

    final config = _getAccuracyConfig(accuracy, t);

    Widget indicator = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            color: config.color,
            size: size,
          ),
          if (showLabel) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config.label,
                  style: TextStyle(
                    color: config.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (accuracy == SensorAccuracy.low || accuracy == SensorAccuracy.unreliable)
                  Text(
                    t.sensorAccuracy.tapToCalibrate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      indicator = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: indicator,
      );
    }

    return indicator;
  }

  _AccuracyConfig _getAccuracyConfig(SensorAccuracy accuracy, Translations t) {
    switch (accuracy) {
      case SensorAccuracy.high:
        return _AccuracyConfig(
          icon: Icons.gps_fixed,
          color: Colors.green,
          label: t.sensorAccuracy.high,
        );
      case SensorAccuracy.medium:
        return _AccuracyConfig(
          icon: Icons.gps_not_fixed,
          color: Colors.orange,
          label: t.sensorAccuracy.medium,
        );
      case SensorAccuracy.low:
        return _AccuracyConfig(
          icon: Icons.gps_off,
          color: Colors.red,
          label: t.sensorAccuracy.low,
        );
      case SensorAccuracy.unreliable:
        return _AccuracyConfig(
          icon: Icons.error_outline,
          color: Colors.red[900]!,
          label: t.sensorAccuracy.unreliable,
        );
    }
  }
}

/// Versión compacta del indicador que muestra solo un punto de color
class CompactSensorAccuracyIndicator extends StatelessWidget {
  final FusedData? sensorData;
  final VoidCallback? onTap;

  const CompactSensorAccuracyIndicator({
    super.key,
    required this.sensorData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = SensorAccuracy.fromFusedData(sensorData);
    final color = _getColorForAccuracy(accuracy);

    Widget indicator = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    );

    if (onTap != null) {
      indicator = InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: indicator,
        ),
      );
    }

    return indicator;
  }

  Color _getColorForAccuracy(SensorAccuracy accuracy) {
    switch (accuracy) {
      case SensorAccuracy.high:
        return Colors.green;
      case SensorAccuracy.medium:
        return Colors.orange;
      case SensorAccuracy.low:
        return Colors.red;
      case SensorAccuracy.unreliable:
        return Colors.red[900]!;
    }
  }
}

class _AccuracyConfig {
  final IconData icon;
  final Color color;
  final String label;

  const _AccuracyConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}
