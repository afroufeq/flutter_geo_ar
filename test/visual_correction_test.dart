import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/visual/visual_correction.dart';
import 'package:flutter_geo_ar/src/poi/poi_renderer.dart';
import 'package:flutter_geo_ar/src/poi/poi_model.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  group('VisualTrackingMode', () {
    test('contiene los valores correctos', () {
      expect(VisualTrackingMode.values.length, 2);
      expect(VisualTrackingMode.values.contains(VisualTrackingMode.off), isTrue);
      expect(VisualTrackingMode.values.contains(VisualTrackingMode.lite), isTrue);
    });

    test('off es el primer valor', () {
      expect(VisualTrackingMode.values.first, VisualTrackingMode.off);
    });

    test('lite es el segundo valor', () {
      expect(VisualTrackingMode.values.last, VisualTrackingMode.lite);
    });
  });

  group('VisualTracker', () {
    group('Constructor y valores por defecto', () {
      test('inicializa con modo off por defecto', () {
        final tracker = VisualTracker();
        expect(tracker.mode, VisualTrackingMode.off);
      });

      test('inicializa con pixelPerRadian por defecto', () {
        final tracker = VisualTracker();
        expect(tracker.pixelPerRadian, 500.0);
      });

      test('permite establecer modo personalizado', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        expect(tracker.mode, VisualTrackingMode.lite);
      });

      test('permite establecer pixelPerRadian personalizado', () {
        final tracker = VisualTracker(pixelPerRadian: 300.0);
        expect(tracker.pixelPerRadian, 300.0);
      });

      test('permite establecer ambos parámetros', () {
        final tracker = VisualTracker(
          mode: VisualTrackingMode.lite,
          pixelPerRadian: 250.0,
        );
        expect(tracker.mode, VisualTrackingMode.lite);
        expect(tracker.pixelPerRadian, 250.0);
      });
    });

    group('applyOffset - Modo OFF', () {
      test('retorna la misma lista sin modificaciones en modo off', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.off);
        final poi = Poi(
          id: '1',
          name: 'Test POI',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        final result = tracker.applyOffset(input);

        expect(result.length, 1);
        expect(result[0].x, 100.0);
        expect(result[0].y, 200.0);
        expect(result[0].size, 30.0);
        expect(result[0].distance, 1000.0);
        expect(result[0].poi, poi);
      });

      test('retorna lista vacía si input es vacío en modo off', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.off);
        final result = tracker.applyOffset([]);
        expect(result, isEmpty);
      });

      test('no modifica múltiples POIs en modo off', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.off);
        final poi1 = Poi(
          id: '1',
          name: 'POI 1',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );
        final poi2 = Poi(
          id: '2',
          name: 'POI 2',
          lat: 28.1,
          lon: -16.1,
          importance: 3,
          category: 'building',
          subtype: 'tower',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi1, distance: 1000.0),
          RenderedPoi(x: 300.0, y: 400.0, size: 25.0, poi: poi2, distance: 2000.0),
        ];

        final result = tracker.applyOffset(input);

        expect(result.length, 2);
        expect(result[0].x, 100.0);
        expect(result[0].y, 200.0);
        expect(result[1].x, 300.0);
        expect(result[1].y, 400.0);
      });
    });

    group('applyOffset - Modo LITE (sin offset)', () {
      test('retorna POIs sin cambios si no hay offset', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test POI',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        final result = tracker.applyOffset(input);

        // Sin llamar a start(), los offsets deberían ser 0
        expect(result.length, 1);
        expect(result[0].x, 100.0);
        expect(result[0].y, 200.0);
        expect(result[0].size, 30.0);
        expect(result[0].distance, 1000.0);
      });

      test('retorna lista vacía si input es vacío en modo lite', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final result = tracker.applyOffset([]);
        expect(result, isEmpty);
      });
    });

    group('start y stop', () {
      test('start no lanza excepciones en modo off', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.off);
        expect(() => tracker.start(), returnsNormally);
      });

      test('start no lanza excepciones en modo lite', () {
        final controller = StreamController<GyroscopeEvent>();
        final tracker = VisualTracker(
          mode: VisualTrackingMode.lite,
          gyroStream: controller.stream,
        );
        expect(() => tracker.start(), returnsNormally);
        tracker.stop();
        controller.close();
      });

      test('stop no lanza excepciones en modo off', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.off);
        expect(() => tracker.stop(), returnsNormally);
      });

      test('stop no lanza excepciones en modo lite', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        expect(() => tracker.stop(), returnsNormally);
      });

      test('múltiples llamadas a start no causan error', () {
        final controller = StreamController<GyroscopeEvent>.broadcast();
        final tracker = VisualTracker(
          mode: VisualTrackingMode.lite,
          gyroStream: controller.stream,
        );
        expect(() {
          tracker.start();
          tracker.start();
          tracker.start();
        }, returnsNormally);
        tracker.stop();
        controller.close();
      });

      test('múltiples llamadas a stop no causan error', () {
        final controller = StreamController<GyroscopeEvent>();
        final tracker = VisualTracker(
          mode: VisualTrackingMode.lite,
          gyroStream: controller.stream,
        );
        tracker.start();
        expect(() {
          tracker.stop();
          tracker.stop();
          tracker.stop();
        }, returnsNormally);
        controller.close();
      });

      test('secuencia start-stop-start funciona correctamente', () {
        final controller = StreamController<GyroscopeEvent>.broadcast();
        final tracker = VisualTracker(
          mode: VisualTrackingMode.lite,
          gyroStream: controller.stream,
        );
        expect(() {
          tracker.start();
          tracker.stop();
          tracker.start();
          tracker.stop();
        }, returnsNormally);
        controller.close();
      });

      test('stop resetea offsets a cero', () async {
        final controller = StreamController<GyroscopeEvent>();
        final tracker = VisualTracker(
          mode: VisualTrackingMode.lite,
          gyroStream: controller.stream,
        );
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        tracker.start();

        // Simular algunos eventos de giroscopio
        controller.add(GyroscopeEvent(0.5, 0.5, 0.0));
        await Future.delayed(Duration(milliseconds: 50));

        tracker.stop();

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];
        final result = tracker.applyOffset(input);

        // Después de stop, los offsets deben ser 0
        expect(result[0].x, 100.0);
        expect(result[0].y, 200.0);

        controller.close();
      });
    });

    group('Preservación de propiedades de POI', () {
      test('preserva size del POI', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 42.5, poi: poi, distance: 1000.0),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].size, 42.5);
      });

      test('preserva distance del POI', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 12345.67),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].distance, 12345.67);
      });

      test('preserva referencia al POI original', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: 'unique-id',
          name: 'Unique Name',
          lat: 28.123,
          lon: -16.456,
          importance: 7,
          category: 'building',
          subtype: 'tower',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].poi.id, 'unique-id');
        expect(result[0].poi.name, 'Unique Name');
        expect(result[0].poi.lat, 28.123);
        expect(result[0].poi.lon, -16.456);
        expect(result[0].poi.importance, 7);
        expect(result[0].poi.category, 'building');
        expect(result[0].poi.subtype, 'tower');
      });

      test('preserva POI con elevation null', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );
        poi.elevation = null;

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].poi.elevation, isNull);
      });

      test('preserva POI con elevation definida', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );
        poi.elevation = 3718.0; // Teide

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].poi.elevation, 3718.0);
      });
    });

    group('Manejo de múltiples POIs', () {
      test('aplica offset a todos los POIs correctamente', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);

        final pois = List.generate(
          10,
          (i) => Poi(
            id: '$i',
            name: 'POI $i',
            lat: 28.0 + i * 0.1,
            lon: -16.0 + i * 0.1,
            importance: i % 10,
            category: 'test',
            subtype: 'test',
          ),
        );

        final input = pois
            .asMap()
            .entries
            .map((e) => RenderedPoi(
                  x: 100.0 + e.key * 10.0,
                  y: 200.0 + e.key * 10.0,
                  size: 25.0 + e.key.toDouble(),
                  poi: e.value,
                  distance: 1000.0 + e.key * 100.0,
                ))
            .toList();

        final result = tracker.applyOffset(input);

        expect(result.length, 10);
        for (int i = 0; i < 10; i++) {
          expect(result[i].poi.id, '$i');
          expect(result[i].size, 25.0 + i);
          expect(result[i].distance, 1000.0 + i * 100.0);
        }
      });

      test('maneja lista grande de POIs (100 elementos)', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);

        final pois = List.generate(
          100,
          (i) => Poi(
            id: '$i',
            name: 'POI $i',
            lat: 28.0,
            lon: -16.0,
            importance: 5,
            category: 'test',
            subtype: 'test',
          ),
        );

        final input = pois
            .asMap()
            .entries
            .map((e) => RenderedPoi(
                  x: e.key.toDouble(),
                  y: e.key.toDouble(),
                  size: 25.0,
                  poi: e.value,
                  distance: 1000.0,
                ))
            .toList();

        final result = tracker.applyOffset(input);

        expect(result.length, 100);
      });
    });

    group('Valores extremos y edge cases', () {
      test('maneja coordenadas x,y muy grandes', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(
            x: 999999.99,
            y: 888888.88,
            size: 30.0,
            poi: poi,
            distance: 1000.0,
          ),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].x.isFinite, isTrue);
        expect(result[0].y.isFinite, isTrue);
      });

      test('maneja coordenadas x,y negativas', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(
            x: -100.0,
            y: -200.0,
            size: 30.0,
            poi: poi,
            distance: 1000.0,
          ),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].x.isFinite, isTrue);
        expect(result[0].y.isFinite, isTrue);
      });

      test('maneja coordenadas x,y en cero', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 0.0, y: 0.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].x.isFinite, isTrue);
        expect(result[0].y.isFinite, isTrue);
      });

      test('maneja distancias muy grandes', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(
            x: 100.0,
            y: 200.0,
            size: 30.0,
            poi: poi,
            distance: 999999999.9,
          ),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].distance, 999999999.9);
      });

      test('maneja size muy pequeño', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(
            x: 100.0,
            y: 200.0,
            size: 0.001,
            poi: poi,
            distance: 1000.0,
          ),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].size, 0.001);
      });

      test('maneja size muy grande', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(
            x: 100.0,
            y: 200.0,
            size: 9999.99,
            poi: poi,
            distance: 1000.0,
          ),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].size, 9999.99);
      });
    });

    group('Diferentes valores de pixelPerRadian', () {
      test('funciona con pixelPerRadian bajo (100.0)', () async {
        final controller = StreamController<GyroscopeEvent>();
        final tracker = VisualTracker(
          mode: VisualTrackingMode.lite,
          pixelPerRadian: 100.0,
          gyroStream: controller.stream,
        );
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        tracker.start();

        // Simular eventos de giroscopio
        controller.add(GyroscopeEvent(0.1, 0.1, 0.0));
        await Future.delayed(Duration(milliseconds: 50));

        final result = tracker.applyOffset(input);
        tracker.stop();

        expect(result.length, 1);
        expect(result[0].x.isFinite, isTrue);
        expect(result[0].y.isFinite, isTrue);

        controller.close();
      });

      test('funciona con pixelPerRadian alto (1000.0)', () async {
        final controller = StreamController<GyroscopeEvent>();
        final tracker = VisualTracker(
          mode: VisualTrackingMode.lite,
          pixelPerRadian: 1000.0,
          gyroStream: controller.stream,
        );
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        tracker.start();

        // Simular eventos de giroscopio
        controller.add(GyroscopeEvent(0.2, 0.2, 0.0));
        await Future.delayed(Duration(milliseconds: 50));

        final result = tracker.applyOffset(input);
        tracker.stop();

        expect(result.length, 1);
        expect(result[0].x.isFinite, isTrue);
        expect(result[0].y.isFinite, isTrue);

        controller.close();
      });

      test('funciona con pixelPerRadian muy bajo (1.0)', () {
        final tracker = VisualTracker(
          mode: VisualTrackingMode.lite,
          pixelPerRadian: 1.0,
        );
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        final result = tracker.applyOffset(input);
        expect(result[0].x.isFinite, isTrue);
        expect(result[0].y.isFinite, isTrue);
      });
    });

    group('Inmutabilidad y estado', () {
      test('no modifica la lista de entrada', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        final originalX = input[0].x;
        final originalY = input[0].y;

        tracker.applyOffset(input);

        // La lista original no debe modificarse
        expect(input[0].x, originalX);
        expect(input[0].y, originalY);
      });

      test('múltiples llamadas producen resultados consistentes sin start', () {
        final tracker = VisualTracker(mode: VisualTrackingMode.lite);
        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        final result1 = tracker.applyOffset(input);
        final result2 = tracker.applyOffset(input);
        final result3 = tracker.applyOffset(input);

        expect(result1[0].x, result2[0].x);
        expect(result1[0].y, result2[0].y);
        expect(result2[0].x, result3[0].x);
        expect(result2[0].y, result3[0].y);
      });

      test('instancias independientes no interfieren entre sí', () {
        final tracker1 = VisualTracker(mode: VisualTrackingMode.lite);
        final tracker2 = VisualTracker(mode: VisualTrackingMode.off);

        final poi = Poi(
          id: '1',
          name: 'Test',
          lat: 28.0,
          lon: -16.0,
          importance: 5,
          category: 'mountain',
          subtype: 'peak',
        );

        final input = [
          RenderedPoi(x: 100.0, y: 200.0, size: 30.0, poi: poi, distance: 1000.0),
        ];

        tracker1.applyOffset(input);
        final result2 = tracker2.applyOffset(input);

        // tracker2 en modo off debe retornar valores originales
        expect(result2[0].x, 100.0);
        expect(result2[0].y, 200.0);
      });
    });
  });
}
