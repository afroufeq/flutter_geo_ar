import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/visual/visual_tracking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VisualTrackingMode', () {
    test('debe tener dos valores: off y lite', () {
      expect(VisualTrackingMode.values.length, 2);
      expect(VisualTrackingMode.values, contains(VisualTrackingMode.off));
      expect(VisualTrackingMode.values, contains(VisualTrackingMode.lite));
    });
  });

  group('VisualTracker - Inicialización', () {
    test('debe inicializarse con modo lite por defecto', () {
      final tracker = VisualTracker();
      expect(tracker.mode, VisualTrackingMode.lite);
      expect(tracker.pixelPerRadian, 500.0);
    });

    test('debe inicializarse con modo off cuando se especifica', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);
      expect(tracker.mode, VisualTrackingMode.off);
    });

    test('debe aceptar pixelPerRadian personalizado', () {
      final tracker = VisualTracker(pixelPerRadian: 750.0);
      expect(tracker.pixelPerRadian, 750.0);
    });

    test('debe inicializar offsets en cero', () {
      final tracker = VisualTracker();
      // Los offsets son privados, pero podemos verificar el comportamiento
      // mediante applyOffset con POIs
      final pois = [
        {'x': 100.0, 'y': 200.0, 'name': 'Test POI'}
      ];

      final result = tracker.applyOffset(pois);

      // Sin start(), en modo lite los offsets deberían ser 0
      expect(result[0]['x'], 100.0);
      expect(result[0]['y'], 200.0);
    });
  });

  group('VisualTracker - applyOffset', () {
    test('en modo OFF debe devolver POIs sin modificar', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      final pois = [
        {'x': 100.0, 'y': 200.0, 'name': 'POI 1'},
        {'x': 300.0, 'y': 400.0, 'name': 'POI 2'},
      ];

      final result = tracker.applyOffset(pois);

      expect(result.length, 2);
      expect(result[0]['x'], 100.0);
      expect(result[0]['y'], 200.0);
      expect(result[1]['x'], 300.0);
      expect(result[1]['y'], 400.0);
    });

    test('debe modificar todos los POIs de la lista', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.lite);

      final pois = [
        {'x': 100.0, 'y': 200.0, 'name': 'POI 1'},
        {'x': 300.0, 'y': 400.0, 'name': 'POI 2'},
        {'x': 500.0, 'y': 600.0, 'name': 'POI 3'},
      ];

      final result = tracker.applyOffset(pois);

      expect(result.length, 3);
      // Sin giroscopio activo, offsets son 0, así que valores no cambian
      expect(result[0]['x'], 100.0);
      expect(result[1]['x'], 300.0);
      expect(result[2]['x'], 500.0);
    });

    test('debe preservar propiedades adicionales de los POIs', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.lite);

      final pois = [
        {
          'x': 100.0,
          'y': 200.0,
          'name': 'Monte Teide',
          'elevation': 3718.0,
          'category': 'mountain',
        }
      ];

      final result = tracker.applyOffset(pois);

      expect(result[0]['name'], 'Monte Teide');
      expect(result[0]['elevation'], 3718.0);
      expect(result[0]['category'], 'mountain');
    });

    test('debe manejar lista vacía correctamente', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.lite);

      final pois = <Map<String, dynamic>>[];
      final result = tracker.applyOffset(pois);

      expect(result, isEmpty);
    });

    test('debe manejar POIs con coordenadas negativas', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      final pois = [
        {'x': -50.0, 'y': -100.0, 'name': 'Negative POI'}
      ];

      final result = tracker.applyOffset(pois);

      expect(result[0]['x'], -50.0);
      expect(result[0]['y'], -100.0);
    });
  });

  group('VisualTracker - Ciclo de vida', () {
    test('stop() debe resetear offsets a cero en modo OFF', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      tracker.start();
      tracker.stop();

      // Verificar que offsets son 0 después de stop
      final pois = [
        {'x': 100.0, 'y': 200.0, 'name': 'Test POI'}
      ];

      final result = tracker.applyOffset(pois);
      expect(result[0]['x'], 100.0);
      expect(result[0]['y'], 200.0);
    });

    test('modo OFF debe permitir start/stop sin errores', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      // En modo OFF, start() no debe intentar acceder al giroscopio
      expect(() => tracker.start(), returnsNormally);
      expect(() => tracker.stop(), returnsNormally);
    });

    test('modo OFF debe permitir múltiples start/stop', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      // Ciclos múltiples
      expect(() {
        tracker.start();
        tracker.stop();
        tracker.start();
        tracker.stop();
        tracker.start();
        tracker.stop();
      }, returnsNormally);
    });

    test('stop() sin start() previo no debe generar error', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      expect(() => tracker.stop(), returnsNormally);
    });
  });

  group('VisualTracker - Constantes', () {
    test('throttleMs debe ser 50ms (20Hz)', () {
      expect(VisualTracker.throttleMs, 50);
    });

    test('throttleMs debe corresponder a frecuencia de 20Hz', () {
      // 20Hz = 1000ms / 20 = 50ms
      const expectedFrequency = 20;
      const calculatedMs = 1000 ~/ expectedFrequency;

      expect(VisualTracker.throttleMs, calculatedMs);
    });
  });

  group('VisualTracker - Comportamiento según modo', () {
    test('modo OFF no debe aplicar offsets incluso después de start()', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      tracker.start();

      final pois = [
        {'x': 100.0, 'y': 200.0, 'name': 'Test POI'}
      ];

      final result = tracker.applyOffset(pois);

      expect(result[0]['x'], 100.0);
      expect(result[0]['y'], 200.0);

      tracker.stop();
    });

    test('modo LITE mantiene offsets en 0 sin datos del giroscopio', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.lite);

      // Sin start(), los offsets deberían ser 0
      final poisBefore = [
        {'x': 100.0, 'y': 200.0, 'name': 'Test POI'}
      ];

      final resultBefore = tracker.applyOffset(poisBefore);
      expect(resultBefore[0]['x'], 100.0);
      expect(resultBefore[0]['y'], 200.0);
    });

    test('modo LITE vs OFF - diferencia en el modo configurado', () {
      final trackerOff = VisualTracker(mode: VisualTrackingMode.off);
      final trackerLite = VisualTracker(mode: VisualTrackingMode.lite);

      // Verificar que los modos son diferentes
      expect(trackerOff.mode, VisualTrackingMode.off);
      expect(trackerLite.mode, VisualTrackingMode.lite);
      expect(trackerOff.mode, isNot(equals(trackerLite.mode)));
    });

    test('modo OFF siempre retorna POIs sin modificar', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      // Múltiples llamadas deben retornar los mismos valores
      final pois1 = [
        {'x': 100.0, 'y': 200.0, 'name': 'Test 1'}
      ];
      final pois2 = [
        {'x': 500.0, 'y': 600.0, 'name': 'Test 2'}
      ];

      final result1 = tracker.applyOffset(pois1);
      final result2 = tracker.applyOffset(pois2);

      expect(result1[0]['x'], 100.0);
      expect(result1[0]['y'], 200.0);
      expect(result2[0]['x'], 500.0);
      expect(result2[0]['y'], 600.0);
    });
  });

  group('VisualTracker - Validación de tipos', () {
    test('debe manejar correctamente doubles en coordenadas', () {
      final tracker = VisualTracker();

      final pois = [
        {'x': 100.5, 'y': 200.7, 'name': 'Float POI'}
      ];

      expect(() => tracker.applyOffset(pois), returnsNormally);
    });

    test('debe preservar el tipo double en coordenadas procesadas', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      final pois = [
        {'x': 123.456, 'y': 789.012, 'name': 'Precise POI'}
      ];

      final result = tracker.applyOffset(pois);

      expect(result[0]['x'], isA<double>());
      expect(result[0]['y'], isA<double>());
      expect(result[0]['x'], 123.456);
      expect(result[0]['y'], 789.012);
    });
  });

  group('VisualTracker - Casos extremos', () {
    test('debe manejar coordenadas en cero', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      final pois = [
        {'x': 0.0, 'y': 0.0, 'name': 'Origin POI'}
      ];

      final result = tracker.applyOffset(pois);

      expect(result[0]['x'], 0.0);
      expect(result[0]['y'], 0.0);
    });

    test('debe manejar coordenadas muy grandes', () {
      final tracker = VisualTracker(mode: VisualTrackingMode.off);

      final pois = [
        {'x': 999999.0, 'y': 999999.0, 'name': 'Far POI'}
      ];

      final result = tracker.applyOffset(pois);

      expect(result[0]['x'], 999999.0);
      expect(result[0]['y'], 999999.0);
    });

    test('debe manejar pixelPerRadian muy pequeño', () {
      final tracker = VisualTracker(pixelPerRadian: 0.1);

      expect(tracker.pixelPerRadian, 0.1);
    });

    test('debe manejar pixelPerRadian muy grande', () {
      final tracker = VisualTracker(pixelPerRadian: 10000.0);

      expect(tracker.pixelPerRadian, 10000.0);
    });
  });
}
