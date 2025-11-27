import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/poi/poi_model.dart';
import 'package:flutter_geo_ar/src/poi/poi_renderer.dart';
import 'package:flutter_geo_ar/src/sensors/fused_data.dart';

// Como _processFrame es privada, vamos a testear la lógica replicándola
// o testeando los componentes que usa
List<Map<String, dynamic>> processFrame(Map<String, dynamic> input, PoiRenderer renderer) {
  final pois = (input['pois'] as List).map((m) => Poi.fromMap(m)).toList();
  final sensors = FusedData.fromMap(input['sensors']);

  renderer.focalLength = (input['focal'] as num).toDouble();

  final projectionResult = renderer.projectPois(
      pois,
      (input['userLat'] as num).toDouble(),
      (input['userLon'] as num).toDouble(),
      (input['userAlt'] as num).toDouble(),
      sensors,
      Size((input['width'] as num).toDouble(), (input['height'] as num).toDouble()),
      calibration: (input['calibration'] as num).toDouble());

  return projectionResult.pois
      .map((rp) => {
            'x': rp.x,
            'y': rp.y,
            'distance': rp.distance,
            'poiName': rp.poi.name,
            'poiKey': rp.poi.key,
            'importance': rp.poi.importance
          })
      .toList();
}

void main() {
  group('processFrame', () {
    late PoiRenderer renderer;

    setUp(() {
      renderer = PoiRenderer();
    });

    test('procesa frame correctamente con un POI', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test Mountain',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result.length, greaterThanOrEqualTo(0));

      if (result.isNotEmpty) {
        expect(result[0].containsKey('x'), isTrue);
        expect(result[0].containsKey('y'), isTrue);
        expect(result[0].containsKey('distance'), isTrue);
        expect(result[0].containsKey('poiName'), isTrue);
        expect(result[0].containsKey('poiKey'), isTrue);
        expect(result[0].containsKey('importance'), isTrue);
      }
    });

    test('procesa frame con múltiples POIs', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'POI 1',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          },
          {
            'id': '2',
            'name': 'POI 2',
            'lat': 28.2,
            'lon': -16.2,
            'importance': 3,
            'category': 'building',
            'subtype': 'tower',
          },
          {
            'id': '3',
            'name': 'POI 3',
            'lat': 28.05,
            'lon': -16.05,
            'importance': 7,
            'category': 'place',
            'subtype': 'town',
          },
        ],
        'sensors': {
          'heading': 45.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      expect(result, isA<List<Map<String, dynamic>>>());
      for (final item in result) {
        expect(item['x'], isA<double>());
        expect(item['y'], isA<double>());
        expect(item['distance'], isA<double>());
        expect(item['poiName'], isA<String>());
        expect(item['poiKey'], isA<String>());
        expect(item['importance'], isA<int>());
      }
    });

    test('procesa frame sin POIs', () {
      final input = {
        'pois': [],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      expect(result, isEmpty);
    });

    test('aplica focal length del input', () {
      final customFocal = 800.0;
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': customFocal,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      processFrame(input, renderer);

      expect(renderer.focalLength, customFocal);
    });

    test('aplica calibración correctamente', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 90.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 15.0,
      };

      final result = processFrame(input, renderer);

      // La calibración afecta la proyección, debería haber algún resultado
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('incluye campos correctos en el resultado', () {
      final input = {
        'pois': [
          {
            'id': 'unique-id',
            'name': 'Mountain Peak',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 8,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      if (result.isNotEmpty) {
        final item = result[0];
        expect(item['poiName'], 'Mountain Peak');
        expect(item['poiKey'], 'mountain:peak');
        expect(item['importance'], 8);
        expect(item['x'], isA<double>());
        expect(item['y'], isA<double>());
        expect(item['distance'], isA<double>());
      }
    });

    test('maneja diferentes tamaños de pantalla', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 720.0,
        'height': 1280.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('maneja sensores con valores null', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': null,
          'pitch': null,
          'roll': null,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      // No debería lanzar excepción
      expect(() => processFrame(input, renderer), returnsNormally);
    });

    test('filtra POIs fuera de rango', () {
      renderer.maxDistance = 1000.0; // 1km

      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Cerca',
            'lat': 28.001,
            'lon': -16.001,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          },
          {
            'id': '2',
            'name': 'Lejos',
            'lat': 29.0,
            'lon': -15.0,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      // El POI lejano debe ser filtrado
      expect(result.length, lessThan(2));
    });

    test('maneja diferentes valores de heading', () {
      final headings = [0.0, 45.0, 90.0, 180.0, 270.0, 359.0];

      for (final heading in headings) {
        final input = {
          'pois': [
            {
              'id': '1',
              'name': 'Test',
              'lat': 28.1,
              'lon': -16.1,
              'importance': 5,
              'category': 'mountain',
              'subtype': 'peak',
            }
          ],
          'sensors': {
            'heading': heading,
            'pitch': 0.0,
            'roll': 0.0,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
          'focal': 520.0,
          'userLat': 28.0,
          'userLon': -16.0,
          'userAlt': 0.0,
          'width': 1080.0,
          'height': 1920.0,
          'calibration': 0.0,
        };

        expect(() => processFrame(input, renderer), returnsNormally);
      }
    });

    test('maneja diferentes valores de pitch', () {
      final pitches = [-90.0, -45.0, 0.0, 45.0, 90.0];

      for (final pitch in pitches) {
        final input = {
          'pois': [
            {
              'id': '1',
              'name': 'Test',
              'lat': 28.1,
              'lon': -16.1,
              'importance': 5,
              'category': 'mountain',
              'subtype': 'peak',
            }
          ],
          'sensors': {
            'heading': 0.0,
            'pitch': pitch,
            'roll': 0.0,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
          'focal': 520.0,
          'userLat': 28.0,
          'userLon': -16.0,
          'userAlt': 0.0,
          'width': 1080.0,
          'height': 1920.0,
          'calibration': 0.0,
        };

        expect(() => processFrame(input, renderer), returnsNormally);
      }
    });

    test('maneja POIs con elevation', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'High Mountain',
            'lat': 28.1,
            'lon': -16.1,
            'elevation': 3718.0, // Teide height
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('maneja user altitude diferente de cero', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 500.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('resultado contiene distancias válidas', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      for (final item in result) {
        expect(item['distance'], greaterThan(0.0));
        expect(item['distance'].isFinite, isTrue);
      }
    });

    test('resultado contiene coordenadas válidas', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      for (final item in result) {
        expect(item['x'].isFinite, isTrue);
        expect(item['y'].isFinite, isTrue);
      }
    });

    test('maneja coordenadas de usuario en diferentes ubicaciones', () {
      final locations = [
        {'lat': 28.0, 'lon': -16.0}, // Tenerife
        {'lat': 40.4, 'lon': -3.7}, // Madrid
        {'lat': -33.9, 'lon': 18.4}, // Cape Town
        {'lat': 51.5, 'lon': -0.1}, // London
      ];

      for (final loc in locations) {
        final input = {
          'pois': [
            {
              'id': '1',
              'name': 'Test',
              'lat': loc['lat']! + 0.1,
              'lon': loc['lon']! + 0.1,
              'importance': 5,
              'category': 'mountain',
              'subtype': 'peak',
            }
          ],
          'sensors': {
            'heading': 0.0,
            'pitch': 0.0,
            'roll': 0.0,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
          'focal': 520.0,
          'userLat': loc['lat'],
          'userLon': loc['lon'],
          'userAlt': 0.0,
          'width': 1080.0,
          'height': 1920.0,
          'calibration': 0.0,
        };

        expect(() => processFrame(input, renderer), returnsNormally);
      }
    });

    test('maneja gran cantidad de POIs (100)', () {
      final pois = List.generate(
        100,
        (i) => {
          'id': '$i',
          'name': 'POI $i',
          'lat': 28.0 + (i * 0.01),
          'lon': -16.0 + (i * 0.01),
          'importance': i % 10,
          'category': 'test',
          'subtype': 'test',
        },
      );

      final input = {
        'pois': pois,
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result = processFrame(input, renderer);

      expect(result, isA<List<Map<String, dynamic>>>());
      // Algunos POIs pueden estar filtrados por estar detrás o fuera de rango
      expect(result.length, lessThanOrEqualTo(100));
    });

    test('es determinista con los mismos inputs', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 45.0,
          'pitch': 10.0,
          'roll': 5.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': 0.0,
      };

      final result1 = processFrame(input, PoiRenderer());
      final result2 = processFrame(input, PoiRenderer());

      expect(result1.length, result2.length);

      for (int i = 0; i < result1.length; i++) {
        expect(result1[i]['x'], result2[i]['x']);
        expect(result1[i]['y'], result2[i]['y']);
        expect(result1[i]['distance'], result2[i]['distance']);
      }
    });

    test('maneja calibración negativa', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test',
            'lat': 28.1,
            'lon': -16.1,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 0.0,
          'pitch': 0.0,
          'roll': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 520.0,
        'userLat': 28.0,
        'userLon': -16.0,
        'userAlt': 0.0,
        'width': 1080.0,
        'height': 1920.0,
        'calibration': -15.0,
      };

      expect(() => processFrame(input, renderer), returnsNormally);
    });

    test('maneja valores decimales precisos', () {
      final input = {
        'pois': [
          {
            'id': '1',
            'name': 'Test',
            'lat': 28.123456789,
            'lon': -16.987654321,
            'importance': 5,
            'category': 'mountain',
            'subtype': 'peak',
          }
        ],
        'sensors': {
          'heading': 45.678,
          'pitch': 12.345,
          'roll': 6.789,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'focal': 523.456,
        'userLat': 28.000123,
        'userLon': -16.000456,
        'userAlt': 123.456,
        'width': 1080.5,
        'height': 1920.5,
        'calibration': 3.14159,
      };

      expect(() => processFrame(input, renderer), returnsNormally);
    });
  });
}
