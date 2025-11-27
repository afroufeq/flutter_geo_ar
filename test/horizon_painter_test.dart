import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/horizon/horizon_painter.dart';
import 'package:flutter_geo_ar/src/horizon/horizon_generator.dart';
import 'package:flutter_geo_ar/src/sensors/fused_data.dart';

void main() {
  group('HorizonPainter', () {
    late HorizonProfile testProfile;
    late FusedData testSensorData;

    setUp(() {
      // Crear un perfil de horizonte de prueba
      // Simulando un horizonte con elevaciones que varían
      final angles = List.generate(180, (i) => (i % 30) * 0.5); // 0° a 360° cada 2°
      testProfile = HorizonProfile(angles, 2.0);

      // Crear datos de sensor de prueba
      testSensorData = FusedData(
        heading: 90.0, // Mirando al este
        pitch: -45.0, // Dispositivo inclinado 45°
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        ts: DateTime.now().millisecondsSinceEpoch,
      );
    });

    group('Constructor', () {
      test('crea instancia con parámetros mínimos', () {
        final painter = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
        );

        expect(painter, isNotNull);
        expect(painter.profile, equals(testProfile));
        expect(painter.sensors, equals(testSensorData));
      });

      test('crea instancia con parámetros opcionales', () {
        final painter = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          focalLength: 600.0,
          calibration: 10.0,
          lineColor: Colors.red,
          lineWidth: 3.0,
          showDebugInfo: true,
        );

        expect(painter.focalLength, equals(600.0));
        expect(painter.calibration, equals(10.0));
        expect(painter.lineColor, equals(Colors.red));
        expect(painter.lineWidth, equals(3.0));
        expect(painter.showDebugInfo, isTrue);
      });

      test('usa valores por defecto correctos', () {
        final painter = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
        );

        expect(painter.focalLength, equals(500.0));
        expect(painter.calibration, equals(0.0));
        expect(painter.lineColor, equals(Colors.yellow));
        expect(painter.lineWidth, equals(2.0));
        expect(painter.showDebugInfo, isFalse);
      });

      test('acepta profile null', () {
        final painter = HorizonPainter(
          profile: null,
          sensors: testSensorData,
        );

        expect(painter.profile, isNull);
      });

      test('acepta sensors null', () {
        final painter = HorizonPainter(
          profile: testProfile,
          sensors: null,
        );

        expect(painter.sensors, isNull);
      });
    });

    group('shouldRepaint', () {
      test('retorna true cuando cambia el profile', () {
        final painter1 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
        );

        final newProfile = HorizonProfile(
          List.generate(90, (i) => i * 1.0),
          4.0,
        );

        final painter2 = HorizonPainter(
          profile: newProfile,
          sensors: testSensorData,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('retorna true cuando cambian los sensors', () {
        final painter1 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
        );

        final newSensorData = FusedData(
          heading: 180.0,
          pitch: -30.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 150.0,
          ts: DateTime.now().millisecondsSinceEpoch,
        );

        final painter2 = HorizonPainter(
          profile: testProfile,
          sensors: newSensorData,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('retorna true cuando cambia calibration', () {
        final painter1 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          calibration: 0.0,
        );

        final painter2 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          calibration: 10.0,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('retorna true cuando cambia focalLength', () {
        final painter1 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          focalLength: 500.0,
        );

        final painter2 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          focalLength: 600.0,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('retorna true cuando cambia lineColor', () {
        final painter1 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          lineColor: Colors.yellow,
        );

        final painter2 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          lineColor: Colors.red,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('retorna true cuando cambia lineWidth', () {
        final painter1 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          lineWidth: 2.0,
        );

        final painter2 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          lineWidth: 3.0,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('retorna true cuando cambia showDebugInfo', () {
        final painter1 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          showDebugInfo: false,
        );

        final painter2 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          showDebugInfo: true,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('retorna false cuando no hay cambios', () {
        final painter1 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          focalLength: 500.0,
          calibration: 5.0,
          lineColor: Colors.yellow,
          lineWidth: 2.0,
          showDebugInfo: false,
        );

        final painter2 = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          focalLength: 500.0,
          calibration: 5.0,
          lineColor: Colors.yellow,
          lineWidth: 2.0,
          showDebugInfo: false,
        );

        expect(painter1.shouldRepaint(painter2), isFalse);
      });
    });

    group('paint', () {
      testWidgets('no dibuja cuando profile es null', (tester) async {
        final painter = HorizonPainter(
          profile: null,
          sensors: testSensorData,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                child: Container(),
              ),
            ),
          ),
        );

        // No debería producir errores
        expect(tester.takeException(), isNull);
      });

      testWidgets('no dibuja cuando sensors es null', (tester) async {
        final painter = HorizonPainter(
          profile: testProfile,
          sensors: null,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('no dibuja cuando heading es null', (tester) async {
        final invalidSensorData = FusedData(
          heading: null,
          pitch: -45.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          ts: DateTime.now().millisecondsSinceEpoch,
        );

        final painter = HorizonPainter(
          profile: testProfile,
          sensors: invalidSensorData,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('no dibuja cuando pitch es null', (tester) async {
        final invalidSensorData = FusedData(
          heading: 90.0,
          pitch: null,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          ts: DateTime.now().millisecondsSinceEpoch,
        );

        final painter = HorizonPainter(
          profile: testProfile,
          sensors: invalidSensorData,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                child: Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('dibuja correctamente con datos válidos', (tester) async {
        final painter = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
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

      testWidgets('dibuja con showDebugInfo activado', (tester) async {
        final painter = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          showDebugInfo: true,
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

      testWidgets('dibuja con diferentes calibraciones', (tester) async {
        final painter = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          calibration: 45.0,
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

      testWidgets('dibuja con diferentes colores y grosores', (tester) async {
        final painter = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          lineColor: Colors.blue,
          lineWidth: 5.0,
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

      testWidgets('maneja diferentes focalLengths', (tester) async {
        final painter = HorizonPainter(
          profile: testProfile,
          sensors: testSensorData,
          focalLength: 1000.0,
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

    group('Diferentes orientaciones de sensor', () {
      testWidgets('maneja heading en 0° (Norte)', (tester) async {
        final sensorData = FusedData(
          heading: 0.0,
          pitch: -45.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          ts: DateTime.now().millisecondsSinceEpoch,
        );

        final painter = HorizonPainter(
          profile: testProfile,
          sensors: sensorData,
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

      testWidgets('maneja heading en 180° (Sur)', (tester) async {
        final sensorData = FusedData(
          heading: 180.0,
          pitch: -45.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          ts: DateTime.now().millisecondsSinceEpoch,
        );

        final painter = HorizonPainter(
          profile: testProfile,
          sensors: sensorData,
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

      testWidgets('maneja pitch cercano a vertical (-90°)', (tester) async {
        final sensorData = FusedData(
          heading: 90.0,
          pitch: -85.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          ts: DateTime.now().millisecondsSinceEpoch,
        );

        final painter = HorizonPainter(
          profile: testProfile,
          sensors: sensorData,
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

      testWidgets('maneja pitch cercano a horizontal (0°)', (tester) async {
        final sensorData = FusedData(
          heading: 90.0,
          pitch: -5.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          ts: DateTime.now().millisecondsSinceEpoch,
        );

        final painter = HorizonPainter(
          profile: testProfile,
          sensors: sensorData,
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
