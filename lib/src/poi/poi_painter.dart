import 'dart:math';
import 'package:flutter/material.dart';
import 'poi_icon_map.dart';

class PoiPainter extends CustomPainter {
  final List<Map<String, dynamic>> poisData;
  final bool fadeByDistance;
  final bool debugMode;
  static final Map<String, TextPainter> _textCache = {};

  PoiPainter(this.poisData, {this.fadeByDistance = true, this.debugMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    final List<Rect> occupied = [];
    for (final pData in poisData) {
      final x = pData['x'] as double;
      final y = pData['y'] as double;
      final dist = pData['distance'] as double;
      final name = pData['poiName'] as String;
      final key = pData['poiKey'] as String;

      if (x < -50 || x > size.width + 50 || y < -50 || y > size.height + 50) continue;
      final opacity = _getOpacity(dist);
      if (opacity <= 0.1) continue;

      final rect = Rect.fromCenter(center: Offset(x, y), width: max(100.0, name.length * 7.0), height: 60);
      if (occupied.any((occ) => rect.overlaps(occ))) continue;

      occupied.add(rect);
      _drawPoi(canvas, x, y, name, key, dist, opacity);
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
