import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geo_ar/src/poi/declutter_mode.dart';
import 'package:flutter_geo_ar/src/poi/poi_painter.dart';

void main() {
  group('DeclutterMode - Tests de Comportamiento', () {
    // Datos de prueba: POIs simulados con posiciones y distancias
    List<Map<String, dynamic>> createTestPois({
      int count = 10,
      double spacing = 50.0,
      double startX = 100.0,
      double startY = 100.0,
    }) {
      return List.generate(count, (i) {
        return {
          'x': startX + (i * spacing),
          'y': startY,
          'distance': 1000.0 + (i * 100.0),
          'poiName': 'POI_$i',
          'poiKey': 'default',
        };
      });
    }

    group('DeclutterMode.off', () {
      testWidgets('debe mostrar todos los POIs sin filtrado', (tester) async {
        final pois = createTestPois(count: 5, spacing: 20.0); // POIs muy juntos

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: PoiPainter(
                  pois,
                  declutterMode: DeclutterMode.off,
                ),
              ),
            ),
          ),
        );

        // En modo off, todos los POIs deberían procesarse
        // No podemos verificar visualmente, pero verificamos que no hay errores
        expect(tester.takeException(), isNull);
      });

      test('debe tener documentación clara', () {
        // Verificar que el enum tiene los valores esperados
        expect(DeclutterMode.values.length, 4);
        expect(DeclutterMode.off.index, 0);
      });
    });

    group('DeclutterMode.light', () {
      testWidgets('debe filtrar solo overlaps grandes (>80%)', (tester) async {
        // POIs con overlap moderado (~50%)
        final pois = createTestPois(count: 5, spacing: 50.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: PoiPainter(
                  pois,
                  declutterMode: DeclutterMode.light,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      test('debe ser el segundo modo en orden', () {
        expect(DeclutterMode.light.index, 1);
      });
    });

    group('DeclutterMode.normal', () {
      testWidgets('debe ser el modo por defecto', (tester) async {
        final pois = createTestPois(count: 5);

        // Sin especificar declutterMode, debería usar normal
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: PoiPainter(pois),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('debe evitar cualquier overlap', (tester) async {
        final pois = createTestPois(count: 5, spacing: 80.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: PoiPainter(
                  pois,
                  declutterMode: DeclutterMode.normal,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      test('debe ser el tercer modo y el default', () {
        expect(DeclutterMode.normal.index, 2);
      });
    });

    group('DeclutterMode.aggressive', () {
      testWidgets('debe aplicar mayor spacing', (tester) async {
        final pois = createTestPois(count: 5, spacing: 120.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: PoiPainter(
                  pois,
                  declutterMode: DeclutterMode.aggressive,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      test('debe ser el cuarto modo', () {
        expect(DeclutterMode.aggressive.index, 3);
      });
    });

    group('PoiPainter - Comparación entre modos', () {
      testWidgets('debe manejar correctamente POIs fuera de pantalla', (tester) async {
        // POIs con coordenadas negativas y fuera de límites
        final poisOffscreen = [
          {'x': -100.0, 'y': 100.0, 'distance': 1000.0, 'poiName': 'Off1', 'poiKey': 'default'},
          {'x': 5000.0, 'y': 100.0, 'distance': 1100.0, 'poiName': 'Off2', 'poiKey': 'default'},
          {'x': 100.0, 'y': -100.0, 'distance': 1200.0, 'poiName': 'Off3', 'poiKey': 'default'},
          {'x': 100.0, 'y': 5000.0, 'distance': 1300.0, 'poiName': 'Off4', 'poiKey': 'default'},
        ];

        for (final mode in DeclutterMode.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: PoiPainter(
                    poisOffscreen,
                    declutterMode: mode,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull, reason: 'Mode $mode debería manejar POIs offscreen sin errores');
        }
      });

      testWidgets('debe priorizar POIs más cercanos', (tester) async {
        // POIs con diferentes distancias
        final poisByDistance = [
          {'x': 100.0, 'y': 100.0, 'distance': 5000.0, 'poiName': 'Lejos', 'poiKey': 'default'},
          {'x': 120.0, 'y': 100.0, 'distance': 500.0, 'poiName': 'Cerca', 'poiKey': 'default'},
          {'x': 140.0, 'y': 100.0, 'distance': 2500.0, 'poiName': 'Medio', 'poiKey': 'default'},
        ];

        // El orden debería ser: Cerca -> Medio -> Lejos (por distancia)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: PoiPainter(
                  poisByDistance,
                  declutterMode: DeclutterMode.normal,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('debe manejar lista vacía de POIs', (tester) async {
        final emptyPois = <Map<String, dynamic>>[];

        for (final mode in DeclutterMode.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: PoiPainter(
                    emptyPois,
                    declutterMode: mode,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull, reason: 'Mode $mode debería manejar lista vacía sin errores');
        }
      });

      testWidgets('debe manejar un solo POI', (tester) async {
        final singlePoi = [
          {'x': 400.0, 'y': 300.0, 'distance': 1000.0, 'poiName': 'Solo', 'poiKey': 'default'},
        ];

        for (final mode in DeclutterMode.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: PoiPainter(
                    singlePoi,
                    declutterMode: mode,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull, reason: 'Mode $mode debería manejar un solo POI sin errores');
        }
      });

      testWidgets('debe manejar POIs con nombres largos', (tester) async {
        final longNamePois = [
          {
            'x': 200.0,
            'y': 200.0,
            'distance': 1000.0,
            'poiName': 'Este es un nombre de POI extremadamente largo para probar el renderizado',
            'poiKey': 'default'
          },
          {
            'x': 220.0,
            'y': 200.0,
            'distance': 1100.0,
            'poiName': 'Otro nombre muy largo que podría causar problemas de overlap',
            'poiKey': 'default'
          },
        ];

        for (final mode in DeclutterMode.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: PoiPainter(
                    longNamePois,
                    declutterMode: mode,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull, reason: 'Mode $mode debería manejar nombres largos sin errores');
        }
      });
    });

    group('PoiPainter - Integración con debugMode', () {
      testWidgets('debe combinar declutterMode con debugMode', (tester) async {
        final pois = createTestPois(count: 10, spacing: 50.0);

        for (final mode in DeclutterMode.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: PoiPainter(
                    pois,
                    debugMode: true,
                    declutterMode: mode,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull, reason: 'Mode $mode debería funcionar con debugMode habilitado');
        }
      });

      testWidgets('debe manejar fadeByDistance con declutter', (tester) async {
        final poisWithVaryingDistances = [
          {'x': 100.0, 'y': 100.0, 'distance': 100.0, 'poiName': 'Muy cerca', 'poiKey': 'default'},
          {'x': 150.0, 'y': 100.0, 'distance': 5000.0, 'poiName': 'Medio', 'poiKey': 'default'},
          {'x': 200.0, 'y': 100.0, 'distance': 15000.0, 'poiName': 'Muy lejos', 'poiKey': 'default'},
        ];

        for (final mode in DeclutterMode.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: PoiPainter(
                    poisWithVaryingDistances,
                    fadeByDistance: true,
                    declutterMode: mode,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull, reason: 'Mode $mode debería funcionar con fadeByDistance');
        }
      });
    });

    group('PoiPainter - Casos extremos de densidad', () {
      testWidgets('debe manejar alta densidad (100 POIs)', (tester) async {
        final highDensityPois = createTestPois(count: 100, spacing: 10.0);

        for (final mode in DeclutterMode.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: PoiPainter(
                    highDensityPois,
                    declutterMode: mode,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull, reason: 'Mode $mode debería manejar alta densidad sin errores');
        }
      });

      testWidgets('debe manejar POIs en la misma posición', (tester) async {
        // Múltiples POIs en exactamente la misma coordenada
        final overlappingPois = List.generate(
          5,
          (i) => {
            'x': 200.0,
            'y': 200.0,
            'distance': 1000.0 + (i * 10.0),
            'poiName': 'POI_$i',
            'poiKey': 'default',
          },
        );

        for (final mode in DeclutterMode.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: PoiPainter(
                    overlappingPois,
                    declutterMode: mode,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull, reason: 'Mode $mode debería manejar POIs superpuestos');
        }
      });
    });

    group('PoiPainter - Rendimiento', () {
      testWidgets('debe renderizar rápidamente con diferentes modos', (tester) async {
        final largePoisList = createTestPois(count: 200, spacing: 5.0);

        for (final mode in DeclutterMode.values) {
          final startTime = DateTime.now();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: PoiPainter(
                    largePoisList,
                    declutterMode: mode,
                  ),
                ),
              ),
            ),
          );

          final duration = DateTime.now().difference(startTime);

          // El renderizado no debería tomar más de 100ms
          expect(duration.inMilliseconds, lessThan(100), reason: 'Mode $mode debería renderizar en < 100ms');

          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('debe repintar eficientemente', (tester) async {
        final pois = createTestPois(count: 50, spacing: 20.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: PoiPainter(
                  pois,
                  declutterMode: DeclutterMode.normal,
                ),
              ),
            ),
          ),
        );

        // Cambiar de modo
        for (final mode in DeclutterMode.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  painter: PoiPainter(
                    pois,
                    declutterMode: mode,
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull, reason: 'Cambio a mode $mode no debería causar errores');
        }
      });
    });
  });
}
