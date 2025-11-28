import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/sensors/sensor_accuracy.dart';
import 'package:flutter_geo_ar/src/sensors/fused_data.dart';

void main() {
  group('SensorAccuracy', () {
    group('fromFusedData con magnetometerAccuracy (Android)', () {
      test('devuelve high cuando magnetometerAccuracy es 3', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          magnetometerAccuracy: 3,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.high);
      });

      test('devuelve medium cuando magnetometerAccuracy es 2', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          magnetometerAccuracy: 2,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.medium);
      });

      test('devuelve low cuando magnetometerAccuracy es 1', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          magnetometerAccuracy: 1,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.low);
      });

      test('devuelve unreliable cuando magnetometerAccuracy es 0', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          magnetometerAccuracy: 0,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.unreliable);
      });

      test('devuelve unreliable cuando magnetometerAccuracy es negativo', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          magnetometerAccuracy: -1,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.unreliable);
      });
    });

    group('fromFusedData con headingAccuracy (iOS)', () {
      test('devuelve high cuando headingAccuracy es menor que 10', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          headingAccuracy: 5.0,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.high);
      });

      test('devuelve high cuando headingAccuracy es 0', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          headingAccuracy: 0.0,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.high);
      });

      test('devuelve medium cuando headingAccuracy está entre 10 y 30', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          headingAccuracy: 20.0,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.medium);
      });

      test('devuelve low cuando headingAccuracy está entre 30 y 90', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          headingAccuracy: 45.0,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.low);
      });

      test('devuelve unreliable cuando headingAccuracy es 90 o mayor', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          headingAccuracy: 90.0,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.unreliable);
      });

      test('devuelve unreliable cuando headingAccuracy es negativo', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          headingAccuracy: -1.0,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.unreliable);
      });
    });

    group('fromFusedData sin datos de precisión', () {
      test('devuelve unreliable cuando FusedData es null', () {
        final accuracy = SensorAccuracy.fromFusedData(null);
        expect(accuracy, SensorAccuracy.unreliable);
      });

      test('devuelve unreliable cuando no hay magnetometerAccuracy ni headingAccuracy', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        expect(accuracy, SensorAccuracy.unreliable);
      });
    });

    group('Prioridad magnetometerAccuracy sobre headingAccuracy', () {
      test('usa magnetometerAccuracy cuando ambos están presentes', () {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 45.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
          magnetometerAccuracy: 3, // high
          headingAccuracy: 50.0, // low
        );

        final accuracy = SensorAccuracy.fromFusedData(data);
        // Debe usar magnetometerAccuracy (high) en lugar de headingAccuracy (low)
        expect(accuracy, SensorAccuracy.high);
      });
    });

    group('Valores enum', () {
      test('todos los valores del enum existen', () {
        expect(SensorAccuracy.values.length, 4);
        expect(SensorAccuracy.values, contains(SensorAccuracy.high));
        expect(SensorAccuracy.values, contains(SensorAccuracy.medium));
        expect(SensorAccuracy.values, contains(SensorAccuracy.low));
        expect(SensorAccuracy.values, contains(SensorAccuracy.unreliable));
      });

      test('valores enum se pueden comparar', () {
        expect(SensorAccuracy.high, isNot(SensorAccuracy.low));
        expect(SensorAccuracy.medium, equals(SensorAccuracy.medium));
      });
    });
  });
}
