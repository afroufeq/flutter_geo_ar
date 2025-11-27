import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/flutter_geo_ar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  group('PoiIconMap Tests', () {
    test('should contain default icon', () {
      expect(poiIcons.containsKey('default'), isTrue);
      expect(poiIcons['default'], isNotNull);
    });

    test('should return correct icon for natural:peak', () {
      final icon = poiIcons['natural:peak'];
      expect(icon, equals(FontAwesomeIcons.mountain));
    });

    test('should return correct icon for natural:volcano', () {
      final icon = poiIcons['natural:volcano'];
      expect(icon, equals(FontAwesomeIcons.volcano));
    });

    test('should return correct icon for tourism:viewpoint', () {
      final icon = poiIcons['tourism:viewpoint'];
      expect(icon, equals(FontAwesomeIcons.binoculars));
    });

    test('should return correct icon for place:city', () {
      final icon = poiIcons['place:city'];
      expect(icon, equals(FontAwesomeIcons.city));
    });

    test('should return correct icon for place:village', () {
      final icon = poiIcons['place:village'];
      expect(icon, equals(FontAwesomeIcons.house));
    });

    test('should return correct icon for historic:monument', () {
      final icon = poiIcons['historic:monument'];
      expect(icon, equals(FontAwesomeIcons.monument));
    });

    test('should return correct icon for amenity:hospital', () {
      final icon = poiIcons['amenity:hospital'];
      expect(icon, equals(FontAwesomeIcons.hospital));
    });

    test('should return correct icon for man_made:lighthouse', () {
      final icon = poiIcons['man_made:lighthouse'];
      expect(icon, equals(FontAwesomeIcons.towerObservation));
    });

    test('should have all natural category icons', () {
      expect(poiIcons['natural:peak'], isNotNull);
      expect(poiIcons['natural:volcano'], isNotNull);
      expect(poiIcons['natural:spring'], isNotNull);
      expect(poiIcons['natural:arch'], isNotNull);
    });

    test('should have all tourism category icons', () {
      expect(poiIcons['tourism:viewpoint'], isNotNull);
      expect(poiIcons['tourism:museum'], isNotNull);
      expect(poiIcons['tourism:attraction'], isNotNull);
    });

    test('should have all amenity category icons', () {
      expect(poiIcons['amenity:hospital'], isNotNull);
      expect(poiIcons['amenity:clinic'], isNotNull);
      expect(poiIcons['amenity:police'], isNotNull);
      expect(poiIcons['amenity:shelter'], isNotNull);
    });

    test('should have all historic category icons', () {
      expect(poiIcons['historic:monument'], isNotNull);
      expect(poiIcons['historic:ruins'], isNotNull);
      expect(poiIcons['historic:castle'], isNotNull);
      expect(poiIcons['historic:church'], isNotNull);
    });

    test('should have all man_made category icons', () {
      expect(poiIcons['man_made:lighthouse'], isNotNull);
      expect(poiIcons['man_made:bridge'], isNotNull);
    });

    test('should have all place category icons', () {
      expect(poiIcons['place:city'], isNotNull);
      expect(poiIcons['place:town'], isNotNull);
      expect(poiIcons['place:village'], isNotNull);
      expect(poiIcons['place:suburb'], isNotNull);
      expect(poiIcons['place:neighbourhood'], isNotNull);
      expect(poiIcons['place:hamlet'], isNotNull);
      expect(poiIcons['place:isolated_dwelling'], isNotNull);
      expect(poiIcons['place:farm'], isNotNull);
      expect(poiIcons['place:island'], isNotNull);
      expect(poiIcons['place:islet'], isNotNull);
      expect(poiIcons['place:locality'], isNotNull);
      expect(poiIcons['place:square'], isNotNull);
      expect(poiIcons['place:quarter'], isNotNull);
    });

    test('should return null for non-existent key', () {
      final icon = poiIcons['nonexistent:category'];
      expect(icon, isNull);
    });

    test('should work with Poi model key property', () {
      final poi = Poi(
        id: 'test_1',
        name: 'Test Peak',
        lat: 28.1235,
        lon: -16.8567,
        category: 'natural',
        subtype: 'peak',
      );

      final icon = poiIcons[poi.key];
      expect(icon, equals(FontAwesomeIcons.mountain));
    });

    test('should fallback to default icon for unmapped POI', () {
      final poi = Poi(
        id: 'test_2',
        name: 'Unknown Type',
        lat: 28.1235,
        lon: -16.8567,
        category: 'unknown',
        subtype: 'type',
      );

      final icon = poiIcons[poi.key] ?? poiIcons['default'];
      expect(icon, equals(FontAwesomeIcons.locationDot));
    });

    test('should have distinct icons for different categories', () {
      final peakIcon = poiIcons['natural:peak'];
      final cityIcon = poiIcons['place:city'];
      final viewpointIcon = poiIcons['tourism:viewpoint'];

      expect(peakIcon, isNot(equals(cityIcon)));
      expect(peakIcon, isNot(equals(viewpointIcon)));
      expect(cityIcon, isNot(equals(viewpointIcon)));
    });

    test('should contain at least 30 icon mappings', () {
      // Verificar que tengamos una buena cobertura de iconos
      expect(poiIcons.length, greaterThanOrEqualTo(30));
    });

    test('all icons should be IconData instances', () {
      for (final icon in poiIcons.values) {
        expect(icon, isA<IconData>());
      }
    });
  });
}
