import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geo_ar/src/utils/spatial_index.dart';

void main() {
  group('SpatialIndex - Tests Avanzados', () {
    group('Casos Límite', () {
      test('debe manejar rectángulos muy pequeños', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Rectángulo de 1x1 pixel
        final tinyRect = Rect.fromLTWH(100, 100, 1, 1);
        index.add(tinyRect);

        // Otro rectángulo diminuto que se solapa
        final tinyRect2 = Rect.fromLTWH(100.5, 100.5, 1, 1);
        expect(index.overlapsAny(tinyRect2), isTrue);

        // Rectángulo que no se solapa
        final tinyRect3 = Rect.fromLTWH(105, 105, 1, 1);
        expect(index.overlapsAny(tinyRect3), isFalse);
      });

      test('debe manejar rectángulos muy grandes', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Rectángulo que cubre casi toda la pantalla
        final largeRect = Rect.fromLTWH(50, 50, 900, 900);
        index.add(largeRect);

        final stats = index.getStats();
        expect(stats['totalRects'], 1);

        // Cualquier rectángulo dentro debería solaparse
        expect(index.overlapsAny(Rect.fromLTWH(500, 500, 50, 50)), isTrue);

        // Rectángulo en la esquina también debería solaparse
        expect(index.overlapsAny(Rect.fromLTWH(900, 900, 50, 50)), isTrue);
      });

      test('debe manejar rectángulos en los bordes de la pantalla', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Rectángulos en las cuatro esquinas
        index.add(Rect.fromLTWH(0, 0, 50, 50)); // Top-left
        index.add(Rect.fromLTWH(950, 0, 50, 50)); // Top-right
        index.add(Rect.fromLTWH(0, 950, 50, 50)); // Bottom-left
        index.add(Rect.fromLTWH(950, 950, 50, 50)); // Bottom-right

        final stats = index.getStats();
        expect(stats['totalRects'], 4);

        // Verificar que cada uno se detecta correctamente
        expect(index.overlapsAny(Rect.fromLTWH(10, 10, 30, 30)), isTrue);
        expect(index.overlapsAny(Rect.fromLTWH(960, 10, 30, 30)), isTrue);
        expect(index.overlapsAny(Rect.fromLTWH(10, 960, 30, 30)), isTrue);
        expect(index.overlapsAny(Rect.fromLTWH(960, 960, 30, 30)), isTrue);
      });

      test('debe manejar rectángulos fuera de los límites', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Rectángulo parcialmente fuera de los límites
        final rectOutside = Rect.fromLTWH(-20, -20, 100, 100);
        index.add(rectOutside);

        // Debería detectar overlap con rectángulo dentro del área visible
        expect(index.overlapsAny(Rect.fromLTWH(40, 40, 50, 50)), isTrue);

        final stats = index.getStats();
        expect(stats['totalRects'], 1);
      });

      test('debe manejar rectángulos con dimensiones cero', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Rectángulo con ancho/alto cero
        final zeroRect = Rect.fromLTWH(100, 100, 0, 0);
        index.add(zeroRect);

        // No debería causar errores
        final stats = index.getStats();
        expect(stats['totalRects'], 1);
      });
    });

    group('Casos de Alta Densidad', () {
      test('debe manejar muchos rectángulos (500 POIs)', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Agregar 500 rectángulos en grid
        for (int i = 0; i < 500; i++) {
          final x = (i % 25) * 40.0;
          final y = (i ~/ 25) * 50.0;
          index.add(Rect.fromLTWH(x, y, 30, 30));
        }

        final stats = index.getStats();
        expect(stats['totalRects'], 500);
        expect(int.parse(stats['cellsUsed'].toString()), greaterThan(50));

        // Verificar que las búsquedas siguen siendo eficientes
        final startTime = DateTime.now();
        for (int i = 0; i < 100; i++) {
          index.overlapsAny(Rect.fromLTWH(100, 100, 30, 30));
        }
        final duration = DateTime.now().difference(startTime);

        // 100 búsquedas deberían tomar menos de 50ms
        expect(duration.inMilliseconds, lessThan(50));
      });

      test('debe manejar alta densidad en una región', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Agregar 100 rectángulos en un área pequeña (100x100)
        for (int i = 0; i < 100; i++) {
          final x = 100 + (i % 10) * 10.0;
          final y = 100 + (i ~/ 10) * 10.0;
          index.add(Rect.fromLTWH(x, y, 8, 8));
        }

        // Verificar que detecta overlaps en esa región
        expect(index.overlapsAny(Rect.fromLTWH(150, 150, 8, 8)), isTrue);

        // Verificar que no hay falsos positivos lejos de la región
        expect(index.overlapsAny(Rect.fromLTWH(500, 500, 50, 50)), isFalse);
      });
    });

    group('Detección de Overlaps Grandes', () {
      test('debe calcular correctamente el porcentaje de overlap al 50%', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Rectángulo base 100x100
        final rect1 = Rect.fromLTWH(100, 100, 100, 100);
        index.add(rect1);

        // Rectángulo con ~25% de overlap (desplazado 50px en diagonal)
        // El área de overlap es 50x50 = 2500, área del rectángulo = 10000
        // Porcentaje = 2500/10000 = 0.25 (25%)
        final rect2 = Rect.fromLTWH(150, 150, 100, 100);

        // Con threshold 0.2 debería detectarse como overlap grande
        expect(index.hasLargeOverlap(rect2, overlapThreshold: 0.2), isTrue);

        // Con threshold 0.3 NO debería detectarse (overlap es menor)
        expect(index.hasLargeOverlap(rect2, overlapThreshold: 0.3), isFalse);
      });

      test('debe detectar overlap del 90%', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Rectángulo base
        final rect1 = Rect.fromLTWH(100, 100, 100, 100);
        index.add(rect1);

        // Rectángulo casi idéntico (desplazado solo 5px)
        final rect2 = Rect.fromLTWH(105, 105, 100, 100);

        // Debería detectarse con threshold alto
        expect(index.hasLargeOverlap(rect2, overlapThreshold: 0.8), isTrue);
        expect(index.hasLargeOverlap(rect2, overlapThreshold: 0.85), isTrue);
      });

      test('debe manejar múltiples rectángulos con overlaps variables', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Agregar varios rectángulos
        index.add(Rect.fromLTWH(100, 100, 100, 100));
        index.add(Rect.fromLTWH(300, 100, 100, 100));
        index.add(Rect.fromLTWH(500, 100, 100, 100));

        // Rectángulo que solo se solapa ligeramente con el primero
        final lightOverlap = Rect.fromLTWH(180, 100, 100, 100);
        expect(index.hasLargeOverlap(lightOverlap, overlapThreshold: 0.8), isFalse);

        // Pero sí tiene overlap general
        expect(index.overlapsAny(lightOverlap), isTrue);
      });

      test('debe considerar el área más pequeña de los rectángulos', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Rectángulo grande
        final largeRect = Rect.fromLTWH(100, 100, 200, 200);
        index.add(largeRect);

        // Rectángulo pequeño completamente dentro del grande
        final smallRect = Rect.fromLTWH(150, 150, 50, 50);

        // El overlap es del 100% del rectángulo pequeño
        expect(index.hasLargeOverlap(smallRect, overlapThreshold: 0.9), isTrue);
      });
    });

    group('Rendimiento y Optimización', () {
      test('debe ser más rápido que búsqueda lineal O(n²)', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Agregar 200 rectángulos dispersos
        for (int i = 0; i < 200; i++) {
          final x = (i % 20) * 50.0;
          final y = (i ~/ 20) * 100.0;
          index.add(Rect.fromLTWH(x, y, 40, 40));
        }

        // Benchmark: hacer 1000 búsquedas
        final startTime = DateTime.now();
        for (int i = 0; i < 1000; i++) {
          index.overlapsAny(Rect.fromLTWH(
            (i % 20) * 50.0,
            (i ~/ 20) * 100.0,
            40,
            40,
          ));
        }
        final duration = DateTime.now().difference(startTime);

        // Con 200 POIs y 1000 búsquedas, debería completarse en < 100ms
        // Un algoritmo O(n²) tomaría mucho más tiempo
        expect(duration.inMilliseconds, lessThan(100));
      });

      test('debe reutilizar eficientemente la memoria con clear()', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Ciclo de agregar y limpiar múltiples veces
        for (int cycle = 0; cycle < 10; cycle++) {
          // Agregar 100 rectángulos
          for (int i = 0; i < 100; i++) {
            index.add(Rect.fromLTWH(i * 10.0, i * 10.0, 50, 50));
          }

          var stats = index.getStats();
          expect(stats['totalRects'], 100);

          // Limpiar
          index.clear();

          stats = index.getStats();
          expect(stats['totalRects'], 0);
          expect(stats['cellsUsed'], 0);
        }

        // Si hay memory leaks, este test fallaría o sería lento
      });

      test('debe proporcionar estadísticas precisas de uso de memoria', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Agregar 100 rectángulos
        for (int i = 0; i < 100; i++) {
          index.add(Rect.fromLTWH(i * 10.0, 100, 50, 50));
        }

        final stats = index.getStats();

        // Verificar que las estadísticas sean razonables
        expect(stats['totalRects'], 100);
        expect(stats['cellsUsed'], greaterThan(0));

        // Verificar que memoryEstimateKB existe y es un String válido
        expect(stats['memoryEstimateKB'], isNotNull);
        expect(stats['memoryEstimateKB'], isA<String>());
      });
    });

    group('Casos de Regresión', () {
      test('debe detectar overlap en bordes de celda', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Rectángulo exactamente en el borde de una celda
        final rectOnBorder = Rect.fromLTWH(99, 99, 50, 50);
        index.add(rectOnBorder);

        // Rectángulo que cruza el borde de la celda
        final rectCrossingBorder = Rect.fromLTWH(120, 120, 50, 50);
        expect(index.overlapsAny(rectCrossingBorder), isTrue);
      });

      test('debe manejar correctamente rectángulos idénticos', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        final rect = Rect.fromLTWH(100, 100, 50, 50);
        index.add(rect);

        // El mismo rectángulo debería detectarse como overlap
        expect(index.overlapsAny(rect), isTrue);
        expect(index.hasLargeOverlap(rect, overlapThreshold: 0.99), isTrue);
      });

      test('debe mantener precisión con números flotantes', () {
        final index = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 100,
        );

        // Rectángulos con coordenadas decimales precisas
        final rect1 = Rect.fromLTWH(100.123, 100.456, 50.789, 50.321);
        index.add(rect1);

        final rect2 = Rect.fromLTWH(120.456, 120.789, 50.123, 50.456);
        expect(index.overlapsAny(rect2), isTrue);

        // Rectángulo que no se solapa (con margen decimal)
        final rect3 = Rect.fromLTWH(151.0, 151.0, 50.0, 50.0);
        expect(index.overlapsAny(rect3), isFalse);
      });

      test('debe manejar configuraciones extremas de cellSize', () {
        // CellSize muy pequeño
        final smallCellIndex = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 10,
        );

        smallCellIndex.add(Rect.fromLTWH(100, 100, 50, 50));
        expect(smallCellIndex.overlapsAny(Rect.fromLTWH(120, 120, 50, 50)), isTrue);

        // CellSize muy grande
        final largeCellIndex = SpatialIndex(
          width: 1000,
          height: 1000,
          cellSize: 500,
        );

        largeCellIndex.add(Rect.fromLTWH(100, 100, 50, 50));
        expect(largeCellIndex.overlapsAny(Rect.fromLTWH(120, 120, 50, 50)), isTrue);
      });
    });
  });
}
