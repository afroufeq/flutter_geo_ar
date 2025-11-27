import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/poi/poi_loader.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PoiLoader', () {
    // Mapa para almacenar múltiples mocks
    final Map<String, String> assetMocks = {};

    // Helper para crear mock de asset
    void setupAssetMock(String assetPath, String content) {
      assetMocks[assetPath] = content;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets',
          (ByteData? message) async {
        final String key = utf8.decode(message!.buffer.asUint8List());
        if (assetMocks.containsKey(key)) {
          final bytes = Uint8List.fromList(utf8.encode(assetMocks[key]!));
          return bytes.buffer.asByteData();
        }
        return null;
      });
    }

    setUp(() {
      assetMocks.clear();
    });

    tearDown(() {
      assetMocks.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
    });

    test('debe cargar POIs desde array directo', () async {
      final jsonString = json.encode([
        {
          'id': 'poi1',
          'name': 'POI 1',
          'lat': 28.5,
          'lon': -16.5,
          'elevation': 1000.0,
          'category': 'natural',
          'subtype': 'peak',
          'importance': 5
        },
        {
          'id': 'poi2',
          'name': 'POI 2',
          'lat': 28.6,
          'lon': -16.6,
          'elevation': 800.0,
          'category': 'tourism',
          'subtype': 'beach',
          'importance': 3
        }
      ]);

      setupAssetMock('test.json', jsonString);

      final pois = await PoiLoader.loadFromAsset('test.json');

      expect(pois.length, equals(2));
      expect(pois[0].id, equals('poi1'));
      expect(pois[0].name, equals('POI 1'));
      expect(pois[1].id, equals('poi2'));
    });

    test('debe cargar POIs desde objeto con clave "pois"', () async {
      final jsonString = json.encode({
        'pois': [
          {
            'id': 'poi1',
            'name': 'POI 1',
            'lat': 28.5,
            'lon': -16.5,
            'elevation': 1000.0,
            'category': 'natural',
            'subtype': 'peak',
            'importance': 5
          }
        ]
      });

      setupAssetMock('test2.json', jsonString);

      final pois = await PoiLoader.loadFromAsset('test2.json');

      expect(pois.length, equals(1));
      expect(pois[0].id, equals('poi1'));
    });

    test('debe lanzar FormatException para formato inválido', () async {
      final jsonString = json.encode({'invalid_key': []});
      setupAssetMock('test3.json', jsonString);

      expect(
        () => PoiLoader.loadFromAsset('test3.json'),
        throwsA(isA<Exception>()),
      );
    });

    test('debe lanzar Exception para JSON inválido', () async {
      setupAssetMock('test4.json', 'invalid json');

      expect(
        () => PoiLoader.loadFromAsset('test4.json'),
        throwsA(isA<Exception>()),
      );
    });

    test('debe lanzar Exception si el archivo no existe', () async {
      // No configurar mock, simula asset no encontrado
      expect(
        () => PoiLoader.loadFromAsset('nonexistent.json'),
        throwsA(isA<Exception>()),
      );
    });

    test('debe manejar array vacío', () async {
      final jsonString = json.encode([]);
      setupAssetMock('empty.json', jsonString);

      final pois = await PoiLoader.loadFromAsset('empty.json');
      expect(pois, isEmpty);
    });

    test('debe manejar objeto con array vacío', () async {
      final jsonString = json.encode({'pois': []});
      setupAssetMock('empty.json', jsonString);

      final pois = await PoiLoader.loadFromAsset('empty.json');
      expect(pois, isEmpty);
    });

    test('debe cargar POIs con todos los campos', () async {
      final jsonString = json.encode([
        {
          'id': 'complete_poi',
          'name': 'Complete POI',
          'lat': 28.123456,
          'lon': -16.654321,
          'elevation': 1234.56,
          'category': 'tourism',
          'subtype': 'viewpoint',
          'importance': 10
        }
      ]);

      setupAssetMock('complete.json', jsonString);

      final pois = await PoiLoader.loadFromAsset('complete.json');

      expect(pois.length, equals(1));
      expect(pois[0].id, equals('complete_poi'));
      expect(pois[0].name, equals('Complete POI'));
      expect(pois[0].lat, closeTo(28.123456, 0.000001));
      expect(pois[0].lon, closeTo(-16.654321, 0.000001));
      expect(pois[0].elevation, closeTo(1234.56, 0.01));
      expect(pois[0].category, equals('tourism'));
      expect(pois[0].subtype, equals('viewpoint'));
      expect(pois[0].importance, equals(10));
    });

    test('debe cargar múltiples POIs correctamente', () async {
      final jsonString = json.encode([
        {
          'id': 'poi1',
          'name': 'POI 1',
          'lat': 28.1,
          'lon': -16.1,
          'elevation': 100.0,
          'category': 'natural',
          'subtype': 'peak',
          'importance': 1
        },
        {
          'id': 'poi2',
          'name': 'POI 2',
          'lat': 28.2,
          'lon': -16.2,
          'elevation': 200.0,
          'category': 'tourism',
          'subtype': 'beach',
          'importance': 2
        },
        {
          'id': 'poi3',
          'name': 'POI 3',
          'lat': 28.3,
          'lon': -16.3,
          'elevation': 300.0,
          'category': 'place',
          'subtype': 'city',
          'importance': 3
        }
      ]);

      setupAssetMock('multiple.json', jsonString);

      final pois = await PoiLoader.loadFromAsset('multiple.json');

      expect(pois.length, equals(3));
      expect(pois[0].id, equals('poi1'));
      expect(pois[1].id, equals('poi2'));
      expect(pois[2].id, equals('poi3'));
    });

    test('debe incluir path en mensaje de error', () async {
      // No setup mock para simular error
      try {
        await PoiLoader.loadFromAsset('test_path.json');
        fail('Debería haber lanzado una excepción');
      } catch (e) {
        expect(e.toString(), contains('test_path.json'));
      }
    });

    test('debe manejar POIs sin campo elevation', () async {
      final jsonString = json.encode([
        {
          'id': 'poi_no_elevation',
          'name': 'POI Sin Elevation',
          'lat': 28.5,
          'lon': -16.5,
          'category': 'amenity',
          'subtype': 'hospital',
          'importance': 5
        }
      ]);

      setupAssetMock('no_elevation.json', jsonString);

      final pois = await PoiLoader.loadFromAsset('no_elevation.json');

      expect(pois.length, equals(1));
      expect(pois[0].elevation, isNull);
    });
  });
}
