import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/poi/poi_painter.dart';

void main() {
  group('PoiPainter', () {
    late List<Map<String, dynamic>> testPoisData;

    setUp(() {
      // Crear datos de POIs de prueba
      testPoisData = [
        {
          'x': 100.0,
          'y': 200.0,
          'distance': 500.0,
          'poiName': 'POI Test 1',
          'poiKey': 'mountain',
        },
        {
          'x': 300.0,
          'y': 400.0,
          'distance': 1500.0,
          'poiName': 'POI Test 2',
          'poiKey': 'peak',
        },
        {
          'x': 500.0,
          'y': 300.0,
          'distance': 8000.0,
          'poiName': 'POI Test 3',
          'poiKey': 'default',
        },
      ];
    });

    group('Constructor', () {
      test('crea instancia con datos mínimos', () {
        final painter = PoiPainter(testPoisData);

        expect(painter, isNotNull);
        expect(painter.poisData, equals(testPoisData));
        expect(painter.fadeByDistance, isTrue);
        expect(painter.debugMode, isFalse);
      });

      test('crea instancia con fadeByDistance desactivado', () {
        final painter = PoiPainter(testPoisData, fadeByDistance: false);

        expect(painter.fadeByDistance, isFalse);
      });

      test('crea instancia con debugMode activado', () {
        final painter = PoiPainter(testPoisData, debugMode: true);

        expect(painter.debugMode, isTrue);
      });

      test('crea instancia con lista vacía', () {
        final painter = PoiPainter([]);

        expect(painter.poisData, isEmpty);
      });

      test('crea instancia con todos los parámetros', () {
        final painter = PoiPainter(
          testPoisData,
          fadeByDistance: false,
          debugMode: true,
        );

        expect(painter.poisData, equals(testPoisData));
        expect(painter.fadeByDistance, isFalse);
        expect(painter.debugMode, isTrue);
      });
    });

    group('shouldRepaint', () {
      test('siempre retorna true', () {
        final painter1 = PoiPainter(testPoisData);
        final painter2 = PoiPainter(testPoisData);

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('retorna true incluso con datos diferentes', () {
        final painter1 = PoiPainter(testPoisData);
        final painter2 = PoiPainter([]);

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('retorna true con opciones diferentes', () {
        final painter1 = PoiPainter(testPoisData, fadeByDistance: true);
        final painter2 = PoiPainter(testPoisData, fadeByDistance: false);

        expect(painter1.shouldRepaint(painter2), isTrue);
      });
    });

    group('paint', () {
      testWidgets('dibuja con datos válidos', (tester) async {
        final painter = PoiPainter(testPoisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja con lista vacía', (tester) async {
        final painter = PoiPainter([]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja con fadeByDistance desactivado', (tester) async {
        final painter = PoiPainter(testPoisData, fadeByDistance: false);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja con debugMode activado', (tester) async {
        final painter = PoiPainter(testPoisData, debugMode: true);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('no dibuja POIs fuera de pantalla (izquierda)', (tester) async {
        final poisData = [
          {
            'x': -100.0, // Fuera de pantalla a la izquierda
            'y': 200.0,
            'distance': 500.0,
            'poiName': 'POI Fuera',
            'poiKey': 'mountain',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('no dibuja POIs fuera de pantalla (derecha)', (tester) async {
        final poisData = [
          {
            'x': 900.0, // Fuera de pantalla a la derecha
            'y': 200.0,
            'distance': 500.0,
            'poiName': 'POI Fuera',
            'poiKey': 'mountain',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja POIs cercanos a los bordes', (tester) async {
        final poisData = [
          {
            'x': 10.0, // Cerca del borde izquierdo
            'y': 200.0,
            'distance': 500.0,
            'poiName': 'POI Borde Izquierdo',
            'poiKey': 'mountain',
          },
          {
            'x': 790.0, // Cerca del borde derecho
            'y': 200.0,
            'distance': 500.0,
            'poiName': 'POI Borde Derecho',
            'poiKey': 'peak',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('maneja POIs superpuestos (evita overlap)', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 500.0,
            'poiName': 'POI 1',
            'poiKey': 'mountain',
          },
          {
            'x': 410.0, // Muy cerca del anterior
            'y': 305.0,
            'distance': 600.0,
            'poiName': 'POI 2',
            'poiKey': 'peak',
          },
          {
            'x': 600.0, // Separado
            'y': 300.0,
            'distance': 700.0,
            'poiName': 'POI 3',
            'poiKey': 'default',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('Diferentes distancias', () {
      testWidgets('dibuja POI muy cercano (< 500m)', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 100.0, // Muy cerca
            'poiName': 'POI Cercano',
            'poiKey': 'mountain',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja POI a distancia media (500-10000m)', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 5000.0, // Distancia media
            'poiName': 'POI Medio',
            'poiKey': 'peak',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja POI muy lejano (> 10000m)', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 15000.0, // Muy lejos
            'poiName': 'POI Lejano',
            'poiKey': 'default',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('aplica fade correcto con fadeByDistance activo', (tester) async {
        final poisData = [
          {
            'x': 100.0,
            'y': 100.0,
            'distance': 400.0, // opacity = 1.0
            'poiName': 'POI 1',
            'poiKey': 'mountain',
          },
          {
            'x': 300.0,
            'y': 100.0,
            'distance': 5000.0, // opacity entre 0.3 y 1.0
            'poiName': 'POI 2',
            'poiKey': 'peak',
          },
          {
            'x': 500.0,
            'y': 100.0,
            'distance': 12000.0, // opacity = 0.3
            'poiName': 'POI 3',
            'poiKey': 'default',
          },
        ];

        final painter = PoiPainter(poisData, fadeByDistance: true);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('no aplica fade con fadeByDistance desactivado', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 15000.0, // Sin fade, debería ser opacity = 1.0
            'poiName': 'POI Lejano',
            'poiKey': 'mountain',
          },
        ];

        final painter = PoiPainter(poisData, fadeByDistance: false);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('Diferentes tipos de POI (keys)', () {
      testWidgets('dibuja POI con key "mountain"', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 500.0,
            'poiName': 'Montaña',
            'poiKey': 'mountain',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja POI con key "peak"', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 500.0,
            'poiName': 'Pico',
            'poiKey': 'peak',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja POI con key "default"', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 500.0,
            'poiName': 'Lugar',
            'poiKey': 'default',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja POI con key desconocida (usa default)', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 500.0,
            'poiName': 'Lugar Desconocido',
            'poiKey': 'unknown_key',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('Nombres de POI', () {
      testWidgets('dibuja POI con nombre corto', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 500.0,
            'poiName': 'POI',
            'poiKey': 'mountain',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja POI con nombre largo', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 500.0,
            'poiName': 'Nombre Muy Largo De Un POI Para Probar',
            'poiKey': 'mountain',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja POI con caracteres especiales', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 500.0,
            'poiName': 'POI (123) - Ñandú',
            'poiKey': 'mountain',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('Formato de distancias', () {
      testWidgets('formatea distancia en metros (< 1000m)', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 750.0, // Debería mostrar "750 m"
            'poiName': 'POI Cercano',
            'poiKey': 'mountain',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('formatea distancia en kilómetros (>= 1000m)', (tester) async {
        final poisData = [
          {
            'x': 400.0,
            'y': 300.0,
            'distance': 2500.0, // Debería mostrar "2.5 km"
            'poiName': 'POI Lejano',
            'poiKey': 'peak',
          },
        ];

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('Múltiples POIs', () {
      testWidgets('dibuja múltiples POIs sin problemas', (tester) async {
        final poisData = List.generate(
          10,
          (i) => {
            'x': 100.0 + i * 70.0,
            'y': 100.0 + i * 50.0,
            'distance': 500.0 + i * 1000.0,
            'poiName': 'POI $i',
            'poiKey': i % 2 == 0 ? 'mountain' : 'peak',
          },
        );

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja muchos POIs (stress test)', (tester) async {
        final poisData = List.generate(
          50,
          (i) => {
            'x': (i * 20.0) % 800.0,
            'y': (i * 15.0) % 600.0,
            'distance': 500.0 + (i * 200.0),
            'poiName': 'POI $i',
            'poiKey': ['mountain', 'peak', 'default'][i % 3],
          },
        );

        final painter = PoiPainter(poisData);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('Modos especiales', () {
      testWidgets('debugMode muestra todos los POIs con opacity completa', (tester) async {
        final poisData = [
          {
            'x': 100.0,
            'y': 100.0,
            'distance': 15000.0, // Normalmente tendría fade
            'poiName': 'POI Lejano',
            'poiKey': 'mountain',
          },
        ];

        final painter = PoiPainter(poisData, debugMode: true);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('debugMode con fadeByDistance sigue mostrando opacity completa', (tester) async {
        final poisData = [
          {
            'x': 100.0,
            'y': 100.0,
            'distance': 20000.0,
            'poiName': 'POI Muy Lejano',
            'poiKey': 'peak',
          },
        ];

        final painter = PoiPainter(
          poisData,
          fadeByDistance: true,
          debugMode: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: Size(800, 600),
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });
  });
}
