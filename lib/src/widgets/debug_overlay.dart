import 'package:flutter/material.dart';
import '../utils/debug_metrics.dart';
import '../utils/telemetry_service.dart';
import '../i18n/strings.g.dart';
import 'dart:async';

/// Widget de Debug Overlay que muestra métricas de rendimiento y sensores en tiempo real
class DebugOverlay extends StatefulWidget {
  /// Muestra la sección de métricas de rendimiento
  final bool showPerformanceMetrics;

  const DebugOverlay({
    super.key,
    this.showPerformanceMetrics = true,
  });

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  final TelemetryService _telemetry = TelemetryService();
  Timer? _updateTimer;
  DebugMetrics _metrics = const DebugMetrics();

  @override
  void initState() {
    super.initState();
    // Actualizar métricas cada 500ms
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _metrics = _telemetry.getMetrics();
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = t;
    return Stack(
      children: [
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showPerformanceMetrics) ...[
                  _buildSectionHeader(translations.debug.sections.debug),
                  const SizedBox(height: 8),
                  _buildPerformanceSection(),
                  const SizedBox(height: 12),
                ],
                if (_hasActiveFilters()) ...[
                  _buildSectionHeader(translations.debug.sections.filters),
                  const SizedBox(height: 8),
                  _buildFiltersSection(),
                  const SizedBox(height: 12),
                ],
                _buildSectionHeader(translations.debug.sections.sensors),
                const SizedBox(height: 8),
                _buildSensorsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection() {
    final translations = t;
    return Column(
      children: [
        _buildMetricRow(translations.debug.metrics.fps, _formatFps(_metrics.fps), _getFpsColor(_metrics.fps)),
        _buildMetricRow(translations.debug.metrics.poisVisibleTotal, '${_metrics.poisVisible}/${_metrics.poisTotal}',
            Colors.white70),
        _buildMetricRow(translations.debug.metrics.cacheHitRate, _formatPercentage(_metrics.cacheHitRate),
            _getCacheColor(_metrics.cacheHitRate)),
        _buildMetricRow(translations.debug.metrics.projectionTime, _formatMs(_metrics.projectionMs),
            _getTimeColor(_metrics.projectionMs)),
        _buildMetricRow(translations.debug.metrics.declutterTime, _formatMs(_metrics.declutterMs),
            _getTimeColor(_metrics.declutterMs)),
      ],
    );
  }

  Widget _buildFiltersSection() {
    final translations = t;
    final filters = <Widget>[];

    if (_metrics.importanceFilteredPois > 0) {
      filters
          .add(_buildMetricRow(translations.debug.metrics.behind, '${_metrics.importanceFilteredPois}', Colors.orange));
    }

    if (_metrics.categoryFilteredPois > 0) {
      filters
          .add(_buildMetricRow(translations.debug.metrics.tooFar, '${_metrics.categoryFilteredPois}', Colors.orange));
    }

    if (_metrics.horizonCulledPois > 0) {
      filters.add(_buildMetricRow(translations.debug.metrics.horizon, '${_metrics.horizonCulledPois}', Colors.orange));
    }

    return Column(children: filters);
  }

  Widget _buildSensorsSection() {
    final translations = t;
    return Column(
      children: [
        _buildMetricRow(translations.debug.metrics.latitude, _formatCoordinate(_metrics.lat), Colors.white70),
        _buildMetricRow(translations.debug.metrics.longitude, _formatCoordinate(_metrics.lon), Colors.white70),
        _buildMetricRow(translations.debug.metrics.altitude, _formatAltitude(_metrics.alt), Colors.white70),
        _buildMetricRow(translations.debug.metrics.heading, _formatAngle(_metrics.heading), Colors.white70),
        _buildMetricRow(translations.debug.metrics.pitch, _formatAngle(_metrics.pitch), Colors.white70),
        if (_metrics.calibrationOffset != 0.0)
          _buildMetricRow(
              translations.debug.metrics.calibration, _formatCalibration(_metrics.calibrationOffset), Colors.cyan),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _metrics.horizonCulledPois > 0 || _metrics.importanceFilteredPois > 0 || _metrics.categoryFilteredPois > 0;
  }

  // Formatters
  String _formatFps(double fps) {
    if (fps == 0.0) return '—';
    return fps.toStringAsFixed(1);
  }

  String _formatPercentage(double rate) {
    if (rate == 0.0) return '—';
    return '${(rate * 100).toStringAsFixed(0)}%';
  }

  String _formatMs(double ms) {
    if (ms == 0.0) return '—';
    return '${ms.toStringAsFixed(1)}ms';
  }

  String _formatCoordinate(double? coord) {
    if (coord == null) return '—';
    return '${coord.toStringAsFixed(6)}°';
  }

  String _formatAltitude(double? alt) {
    if (alt == null) return '—';
    return '${alt.toStringAsFixed(0)}m';
  }

  String _formatAngle(double? angle) {
    if (angle == null) return '—';
    return '${angle.toStringAsFixed(1)}°';
  }

  String _formatCalibration(double offset) {
    final sign = offset >= 0 ? '+' : '';
    return '$sign${offset.toStringAsFixed(1)}°';
  }

  // Color getters
  Color _getFpsColor(double fps) {
    if (fps == 0.0) return Colors.white70;
    if (fps > 55) return Colors.green;
    if (fps > 30) return Colors.yellow;
    return Colors.red;
  }

  Color _getCacheColor(double rate) {
    if (rate == 0.0) return Colors.white70;
    if (rate > 0.8) return Colors.green;
    if (rate >= 0.5) return Colors.cyan;
    return Colors.orange;
  }

  Color _getTimeColor(double ms) {
    if (ms == 0.0) return Colors.white70;
    if (ms < 5) return Colors.green;
    if (ms < 16) return Colors.yellow;
    return Colors.red;
  }
}
