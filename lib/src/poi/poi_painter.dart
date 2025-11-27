import 'dart:math';
import 'package:flutter/material.dart';
import 'poi_icon_map.dart';
import 'declutter_mode.dart';
import '../utils/spatial_index.dart';

class PoiPainter extends CustomPainter {
  final List<Map<String, dynamic>> poisData;
  final bool fadeByDistance;
  final bool debugMode;
  final DeclutterMode declutterMode;
  static final Map<String, TextPainter> _textCache = {};

  /// Spatial index reutilizable para reducir presión sobre el GC
  /// Se crea una vez y se limpia entre frames en lugar de crear nuevos objetos
  static SpatialIndex? _spatialIndex;

  PoiPainter(
    this.poisData, {
    this.fadeByDistance = true,
    this.debugMode = false,
    this.declutterMode = DeclutterMode.normal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Reutilizar o crear el Spatial Index (optimización de GC)
    // Esto evita crear ~60 objetos por segundo (a 60 FPS), reduciendo
    // significativamente la presión sobre el Garbage Collector
    _spatialIndex ??= SpatialIndex(
      width: size.width,
      height: size.height,
      cellSize: 100.0, // Tamaño de celda optimizado para etiquetas típicas
    );

    // Limpiar datos del frame anterior (muy eficiente, reutiliza memoria)
    _spatialIndex!.clear();
    final spatialIndex = _spatialIndex!;

    // Ordenar POIs por distancia para dar prioridad a los más cercanos
    // Esto asegura que en caso de solapamiento, los POIs cercanos se muestren
    // antes que los lejanos, mejorando la experiencia del usuario
    final sortedPois = List<Map<String, dynamic>>.from(poisData);
    sortedPois.sort((a, b) {
      final distA = a['distance'] as double;
      final distB = b['distance'] as double;
      return distA.compareTo(distB);
    });

    for (final pData in sortedPois) {
      final x = pData['x'] as double;
      final y = pData['y'] as double;
      final dist = pData['distance'] as double;
      final name = pData['poiName'] as String;
      final key = pData['poiKey'] as String;

      // Filtrar POIs fuera de la pantalla (con margen de 50px)
      if (x < -50 || x > size.width + 50 || y < -50 || y > size.height + 50) continue;

      final opacity = _getOpacity(dist);
      if (opacity <= 0.1) continue;

      // Calcular el rectángulo que ocupará esta etiqueta
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: max(100.0, name.length * 7.0),
        height: 60,
      );

      // Aplicar lógica de declutter según el modo
      if (_shouldSkipPoi(rect, spatialIndex)) continue;

      // Si no hay overlap o el modo permite este POI, agregarlo al índice y dibujarlo
      spatialIndex.add(rect);
      _drawPoi(canvas, x, y, name, key, dist, opacity);
    }
  }

  /// Determina si un POI debe ser omitido según el modo de declutter
  bool _shouldSkipPoi(Rect rect, SpatialIndex spatialIndex) {
    switch (declutterMode) {
      case DeclutterMode.off:
        // Sin filtrado, nunca omitir
        return false;

      case DeclutterMode.light:
        // Solo evita overlaps grandes (>80% del área)
        return spatialIndex.hasLargeOverlap(rect, overlapThreshold: 0.8);

      case DeclutterMode.normal:
        // Evita cualquier overlap
        return spatialIndex.overlapsAny(rect);

      case DeclutterMode.aggressive:
        // Expande el rectángulo un 20% y luego verifica overlap
        final expandedRect = rect.inflate(rect.width * 0.1);
        return spatialIndex.overlapsAny(expandedRect);
    }
  }

  double _getOpacity(double dist) {
    // En modo debug, siempre mostrar POIs con opacidad completa
    if (debugMode) return 1.0;

    return (!fadeByDistance || dist < 500) ? 1.0 : (dist > 10000 ? 0.3 : 1.0 - ((dist - 500) / 9500) * 0.7);
  }

  void _drawPoi(Canvas canvas, double x, double y, String name, String key, double dist, double alpha) {
    final icon = poiIcons[key] ?? poiIcons['default'];
    final color = Colors.white.withValues(alpha: alpha);

    final iconTp = _getTextPainter(
        String.fromCharCode(icon!.codePoint),
        TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: 24,
            color: Colors.orangeAccent.withValues(alpha: alpha)));
    iconTp.paint(canvas, Offset(x - iconTp.width / 2, y - 24));

    final nameTp = _getTextPainter(
        name, TextStyle(fontFamily: 'Urbanist', fontWeight: FontWeight.w100, fontSize: 14, color: color));
    nameTp.paint(canvas, Offset(x - nameTp.width / 2, y + 2));

    final distStr = dist < 1000 ? "${dist.toInt()} m" : "${(dist / 1000).toStringAsFixed(1)} km";
    final distTp = _getTextPainter(
        distStr,
        TextStyle(
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.w100,
            fontSize: 12,
            color: color.withValues(alpha: alpha * 0.7)));
    distTp.paint(canvas, Offset(x - distTp.width / 2, y + 2 + nameTp.height));
  }

  TextPainter _getTextPainter(String text, TextStyle style) {
    final cacheKey = "$text|${style.fontSize}|${style.color?.toARGB32()}";
    if (_textCache.containsKey(cacheKey)) return _textCache[cacheKey]!;
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    if (_textCache.length > 100) _textCache.clear();
    _textCache[cacheKey] = tp;
    return tp;
  }

  @override
  bool shouldRepaint(covariant PoiPainter oldDelegate) => true;
}
