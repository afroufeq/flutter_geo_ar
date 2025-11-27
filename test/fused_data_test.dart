import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/flutter_geo_ar.dart';

void main() {
  group('FusedData Tests', () {
    test('should create FusedData with all parameters', () {
      final fusedData = FusedData(
        heading: 45.5,
        pitch: 10.2,
        roll: -5.3,
        lat: 28.1235,
        lon: -16.8567,
        alt: 1500.0,
        ts: 1234567890,
      );

      expect(fusedData.heading, 45.5);
      expect(fusedData.pitch, 10.2);
      expect(fusedData.roll, -5.3);
      expect(fusedData.lat, 28.1235);
      expect(fusedData.lon, -16.8567);
      expect(fusedData.alt, 1500.0);
      expect(fusedData.ts, 1234567890);
    });

    test('should create FusedData with only timestamp', () {
      final fusedData = FusedData(ts: 1234567890);

      expect(fusedData.heading, isNull);
      expect(fusedData.pitch, isNull);
      expect(fusedData.roll, isNull);
      expect(fusedData.lat, isNull);
      expect(fusedData.lon, isNull);
      expect(fusedData.alt, isNull);
      expect(fusedData.ts, 1234567890);
    });

    test('should convert FusedData to Map correctly', () {
      final fusedData = FusedData(
        heading: 90.0,
        pitch: 15.5,
        roll: -10.0,
        lat: 28.5,
        lon: -16.3,
        alt: 2000.0,
        ts: 9876543210,
      );

      final map = fusedData.toMap();

      expect(map['heading'], 90.0);
      expect(map['pitch'], 15.5);
      expect(map['roll'], -10.0);
      expect(map['lat'], 28.5);
      expect(map['lon'], -16.3);
      expect(map['alt'], 2000.0);
      expect(map['ts'], 9876543210);
    });

    test('should create FusedData from Map correctly', () {
      final map = {
        'heading': 180.0,
        'pitch': 20.0,
        'roll': 5.5,
        'lat': 27.8,
        'lon': -15.5,
        'alt': 500.0,
        'ts': 1111111111,
      };

      final fusedData = FusedData.fromMap(map);

      expect(fusedData.heading, 180.0);
      expect(fusedData.pitch, 20.0);
      expect(fusedData.roll, 5.5);
      expect(fusedData.lat, 27.8);
      expect(fusedData.lon, -15.5);
      expect(fusedData.alt, 500.0);
      expect(fusedData.ts, 1111111111);
    });

    test('should handle null values in Map', () {
      final map = {
        'heading': null,
        'pitch': null,
        'roll': null,
        'lat': null,
        'lon': null,
        'alt': null,
        'ts': 2222222222,
      };

      final fusedData = FusedData.fromMap(map);

      expect(fusedData.heading, isNull);
      expect(fusedData.pitch, isNull);
      expect(fusedData.roll, isNull);
      expect(fusedData.lat, isNull);
      expect(fusedData.lon, isNull);
      expect(fusedData.alt, isNull);
      expect(fusedData.ts, 2222222222);
    });

    test('should default timestamp to 0 if not provided in Map', () {
      final map = {
        'heading': 45.0,
        'pitch': 10.0,
        'roll': -5.0,
      };

      final fusedData = FusedData.fromMap(map);

      expect(fusedData.ts, 0);
    });

    test('should preserve data through serialization cycle', () {
      final originalData = FusedData(
        heading: 270.5,
        pitch: 12.3,
        roll: -8.7,
        lat: 28.9876,
        lon: -16.5432,
        alt: 3000.5,
        ts: 5555555555,
      );

      final map = originalData.toMap();
      final reconstructedData = FusedData.fromMap(map);

      expect(reconstructedData.heading, originalData.heading);
      expect(reconstructedData.pitch, originalData.pitch);
      expect(reconstructedData.roll, originalData.roll);
      expect(reconstructedData.lat, originalData.lat);
      expect(reconstructedData.lon, originalData.lon);
      expect(reconstructedData.alt, originalData.alt);
      expect(reconstructedData.ts, originalData.ts);
    });

    test('should handle partial sensor data', () {
      final fusedData = FusedData(
        heading: 45.0,
        lat: 28.1235,
        lon: -16.8567,
        ts: 9999999999,
      );

      expect(fusedData.heading, 45.0);
      expect(fusedData.pitch, isNull);
      expect(fusedData.roll, isNull);
      expect(fusedData.lat, 28.1235);
      expect(fusedData.lon, -16.8567);
      expect(fusedData.alt, isNull);
      expect(fusedData.ts, 9999999999);
    });

    test('should handle GPS data only', () {
      final fusedData = FusedData(
        lat: 28.1235,
        lon: -16.8567,
        alt: 1500.0,
        ts: 7777777777,
      );

      expect(fusedData.heading, isNull);
      expect(fusedData.pitch, isNull);
      expect(fusedData.roll, isNull);
      expect(fusedData.lat, 28.1235);
      expect(fusedData.lon, -16.8567);
      expect(fusedData.alt, 1500.0);
      expect(fusedData.ts, 7777777777);
    });

    test('should handle orientation data only', () {
      final fusedData = FusedData(
        heading: 90.0,
        pitch: 15.0,
        roll: -10.0,
        ts: 8888888888,
      );

      expect(fusedData.heading, 90.0);
      expect(fusedData.pitch, 15.0);
      expect(fusedData.roll, -10.0);
      expect(fusedData.lat, isNull);
      expect(fusedData.lon, isNull);
      expect(fusedData.alt, isNull);
      expect(fusedData.ts, 8888888888);
    });
  });
}
