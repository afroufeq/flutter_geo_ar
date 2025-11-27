import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/flutter_geo_ar.dart';

void main() {
  group('Poi Model Tests', () {
    test('should create a Poi instance with required parameters', () {
      final poi = Poi(
        id: 'test_1',
        name: 'Test POI',
        lat: 28.1235,
        lon: -16.8567,
      );

      expect(poi.id, 'test_1');
      expect(poi.name, 'Test POI');
      expect(poi.lat, 28.1235);
      expect(poi.lon, -16.8567);
      expect(poi.importance, 1);
      expect(poi.category, 'generic');
      expect(poi.subtype, 'default');
    });

    test('should create a Poi with all parameters including elevation', () {
      final poi = Poi(
        id: 'peak_1',
        name: 'Teide',
        lat: 28.2723,
        lon: -16.6425,
        elevation: 3718.0,
        importance: 5,
        category: 'mountain',
        subtype: 'peak',
      );

      expect(poi.id, 'peak_1');
      expect(poi.name, 'Teide');
      expect(poi.elevation, 3718.0);
      expect(poi.importance, 5);
      expect(poi.category, 'mountain');
      expect(poi.subtype, 'peak');
    });

    test('should generate correct key from category and subtype', () {
      final poi = Poi(
        id: 'test_1',
        name: 'Test',
        lat: 0.0,
        lon: 0.0,
        category: 'mountain',
        subtype: 'peak',
      );

      expect(poi.key, 'mountain:peak');
    });

    test('should convert Poi to Map correctly', () {
      final poi = Poi(
        id: 'test_1',
        name: 'Test POI',
        lat: 28.1235,
        lon: -16.8567,
        elevation: 1500.0,
        importance: 3,
        category: 'village',
        subtype: 'town',
      );

      final map = poi.toMap();

      expect(map['id'], 'test_1');
      expect(map['name'], 'Test POI');
      expect(map['lat'], 28.1235);
      expect(map['lon'], -16.8567);
      expect(map['elevation'], 1500.0);
      expect(map['importance'], 3);
      expect(map['category'], 'village');
      expect(map['subtype'], 'town');
    });

    test('should create Poi from Map correctly', () {
      final map = {
        'id': 'test_2',
        'name': 'Mapped POI',
        'lat': 28.5,
        'lon': -16.3,
        'elevation': 2000.0,
        'importance': 4,
        'category': 'landmark',
        'subtype': 'viewpoint',
      };

      final poi = Poi.fromMap(map);

      expect(poi.id, 'test_2');
      expect(poi.name, 'Mapped POI');
      expect(poi.lat, 28.5);
      expect(poi.lon, -16.3);
      expect(poi.elevation, 2000.0);
      expect(poi.importance, 4);
      expect(poi.category, 'landmark');
      expect(poi.subtype, 'viewpoint');
    });

    test('should handle Poi without elevation', () {
      final map = {
        'id': 'test_3',
        'name': 'No Elevation POI',
        'lat': 28.0,
        'lon': -16.0,
        'elevation': null,
        'importance': 2,
        'category': 'place',
        'subtype': 'city',
      };

      final poi = Poi.fromMap(map);

      expect(poi.elevation, isNull);
    });

    test('should handle numeric types for lat/lon conversion', () {
      final mapWithInt = {
        'id': 'test_4',
        'name': 'Integer Coords',
        'lat': 28,
        'lon': -16,
        'importance': 1,
        'category': 'generic',
        'subtype': 'default',
      };

      final poi = Poi.fromMap(mapWithInt);

      expect(poi.lat, 28.0);
      expect(poi.lon, -16.0);
      expect(poi.lat, isA<double>());
      expect(poi.lon, isA<double>());
    });

    test('should preserve data through serialization cycle', () {
      final originalPoi = Poi(
        id: 'cycle_test',
        name: 'Serialization Test',
        lat: 28.4567,
        lon: -16.7890,
        elevation: 1234.5,
        importance: 3,
        category: 'test',
        subtype: 'serialization',
      );

      final map = originalPoi.toMap();
      final reconstructedPoi = Poi.fromMap(map);

      expect(reconstructedPoi.id, originalPoi.id);
      expect(reconstructedPoi.name, originalPoi.name);
      expect(reconstructedPoi.lat, originalPoi.lat);
      expect(reconstructedPoi.lon, originalPoi.lon);
      expect(reconstructedPoi.elevation, originalPoi.elevation);
      expect(reconstructedPoi.importance, originalPoi.importance);
      expect(reconstructedPoi.category, originalPoi.category);
      expect(reconstructedPoi.subtype, originalPoi.subtype);
    });
  });
}
