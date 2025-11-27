import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geo_ar/src/utils/spatial_index.dart';

void main() {
  group('SpatialIndex', () {
    test('debe inicializarse correctamente', () {
      final index = SpatialIndex(
        width: 1000,
        height: 1000,
        cellSize: 100,
      );

      final stats = index.getStats();
      expect(stats['totalRects'], 0);
      expect(stats['cellsUsed'], 0);
    });

    test('debe agregar rectángulos correctamente', () {
      final index = SpatialIndex(
        width: 1000,
        height: 1000,
        cellSize: 100,
      );

      final rect1 = Rect.fromLTWH(100, 100, 50, 50);
      index.add(rect1);

      final stats = index.getStats();
      expect(stats['totalRects'], 1);
      expect(int.parse(stats['cellsUsed'].toString()), greaterThan(0));
    });

    test('debe detectar overlaps correctamente', () {
      final index = SpatialIndex(
        width: 1000,
        height: 1000,
        cellSize: 100,
      );

      // Agregar primer rectángulo
      final rect1 = Rect.fromLTWH(100, 100, 50, 50);
      index.add(rect1);

      // Rectángulo que se solapa con rect1
      final rect2 = Rect.fromLTWH(120, 120, 50, 50);
      expect(index.overlapsAny(rect2), isTrue);

      // Rectángulo que NO se solapa con rect1
      final rect3 = Rect.fromLTWH(300, 300, 50, 50);
      expect(index.overlapsAny(rect3), isFalse);
    });

    test('debe detectar overlaps grandes correctamente', () {
      final index = SpatialIndex(
        width: 1000,
        height: 1000,
        cellSize: 100,
      );

      // Agregar primer rectángulo
      final rect1 = Rect.fromLTWH(100, 100, 50, 50);
      index.add(rect1);

      // Overlap grande (>80%)
      final rect2 = Rect.fromLTWH(105, 105, 50, 50);
      expect(index.hasLargeOverlap(rect2, overlapThreshold: 0.8), isTrue);

      // Overlap pequeño (<80%)
      final rect3 = Rect.fromLTWH(130, 130, 50, 50);
      expect(index.hasLargeOverlap(rect3, overlapThreshold: 0.8), isFalse);

      // Sin overlap
      final rect4 = Rect.fromLTWH(300, 300, 50, 50);
      expect(index.hasLargeOverlap(rect4, overlapThreshold: 0.8), isFalse);
    });

    test('debe manejar múltiples rectángulos', () {
      final index = SpatialIndex(
        width: 1000,
        height: 1000,
        cellSize: 100,
      );

      // Agregar varios rectángulos sin overlap
      index.add(Rect.fromLTWH(100, 100, 50, 50));
      index.add(Rect.fromLTWH(300, 100, 50, 50));
      index.add(Rect.fromLTWH(500, 100, 50, 50));

      final stats = index.getStats();
      expect(stats['totalRects'], 3);

      // Verificar que un rectángulo en medio se detecta como overlap con el primero
      expect(index.overlapsAny(Rect.fromLTWH(120, 120, 50, 50)), isTrue);
    });

    test('debe limpiar correctamente', () {
      final index = SpatialIndex(
        width: 1000,
        height: 1000,
        cellSize: 100,
      );

      index.add(Rect.fromLTWH(100, 100, 50, 50));
      index.add(Rect.fromLTWH(300, 100, 50, 50));

      var stats = index.getStats();
      expect(stats['totalRects'], 2);

      index.clear();

      stats = index.getStats();
      expect(stats['totalRects'], 0);
      expect(stats['cellsUsed'], 0);
    });

    test('debe optimizar búsquedas usando celdas', () {
      final index = SpatialIndex(
        width: 1000,
        height: 1000,
        cellSize: 100,
      );

      // Agregar rectángulos en diferentes regiones
      index.add(Rect.fromLTWH(50, 50, 30, 30)); // Región top-left
      index.add(Rect.fromLTWH(800, 800, 30, 30)); // Región bottom-right

      // Un rectángulo en top-left solo debería verificar con el primer rectángulo
      final rectTopLeft = Rect.fromLTWH(60, 60, 30, 30);
      expect(index.overlapsAny(rectTopLeft), isTrue);

      // Un rectángulo en bottom-right solo debería verificar con el segundo rectángulo
      final rectBottomRight = Rect.fromLTWH(810, 810, 30, 30);
      expect(index.overlapsAny(rectBottomRight), isTrue);

      // Un rectángulo en el medio no debería solaparse con ninguno
      final rectMiddle = Rect.fromLTWH(400, 400, 30, 30);
      expect(index.overlapsAny(rectMiddle), isFalse);
    });

    test('debe proporcionar estadísticas útiles', () {
      final index = SpatialIndex(
        width: 1000,
        height: 1000,
        cellSize: 100,
      );

      // Agregar varios rectángulos
      for (int i = 0; i < 10; i++) {
        index.add(Rect.fromLTWH(i * 100.0, i * 100.0, 50, 50));
      }

      final stats = index.getStats();
      expect(stats['totalRects'], 10);
      expect(int.parse(stats['cellsUsed'].toString()), greaterThan(0));
      expect(stats['cellUsagePercent'], isNotNull);
      expect(stats['avgRectsPerCell'], isNotNull);
      expect(stats['maxRectsInCell'], isNotNull);
      expect(stats['memoryEstimateKB'], isNotNull);
    });
  });
}
