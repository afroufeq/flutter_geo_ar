import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/utils/debug_metrics.dart';

void main() {
  group('DebugMetrics', () {
    test('debe crear instancia con valores por defecto', () {
      const metrics = DebugMetrics();

      expect(metrics.fps, equals(0.0));
      expect(metrics.poisVisible, equals(0));
      expect(metrics.poisTotal, equals(0));
      expect(metrics.cacheHitRate, equals(0.0));
      expect(metrics.projectionMs, equals(0.0));
      expect(metrics.declutterMs, equals(0.0));
      expect(metrics.horizonCulledPois, equals(0));
      expect(metrics.importanceFilteredPois, equals(0));
      expect(metrics.categoryFilteredPois, equals(0));
      expect(metrics.lat, isNull);
      expect(metrics.lon, isNull);
      expect(metrics.alt, isNull);
      expect(metrics.heading, isNull);
      expect(metrics.pitch, isNull);
      expect(metrics.roll, isNull);
      expect(metrics.calibrationOffset, equals(0.0));
      expect(metrics.isolateCallbacks, equals(0));
      expect(metrics.cacheActive, isFalse);
    });

    test('debe crear instancia con valores personalizados', () {
      const metrics = DebugMetrics(
        fps: 60.0,
        poisVisible: 25,
        poisTotal: 450,
        cacheHitRate: 0.85,
        projectionMs: 3.2,
        declutterMs: 1.8,
        horizonCulledPois: 12,
        importanceFilteredPois: 180,
        categoryFilteredPois: 50,
        lat: 28.123456,
        lon: -16.543210,
        alt: 850.0,
        heading: 245.3,
        pitch: -10.5,
        roll: 2.3,
        calibrationOffset: -15.0,
        isolateCallbacks: 100,
        cacheActive: true,
      );

      expect(metrics.fps, equals(60.0));
      expect(metrics.poisVisible, equals(25));
      expect(metrics.poisTotal, equals(450));
      expect(metrics.cacheHitRate, equals(0.85));
      expect(metrics.projectionMs, equals(3.2));
      expect(metrics.declutterMs, equals(1.8));
      expect(metrics.horizonCulledPois, equals(12));
      expect(metrics.importanceFilteredPois, equals(180));
      expect(metrics.categoryFilteredPois, equals(50));
      expect(metrics.lat, equals(28.123456));
      expect(metrics.lon, equals(-16.543210));
      expect(metrics.alt, equals(850.0));
      expect(metrics.heading, equals(245.3));
      expect(metrics.pitch, equals(-10.5));
      expect(metrics.roll, equals(2.3));
      expect(metrics.calibrationOffset, equals(-15.0));
      expect(metrics.isolateCallbacks, equals(100));
      expect(metrics.cacheActive, isTrue);
    });

    group('copyWith', () {
      test('debe copiar con un valor modificado', () {
        const original = DebugMetrics(
          fps: 60.0,
          poisVisible: 25,
        );

        final copied = original.copyWith(fps: 30.0);

        expect(copied.fps, equals(30.0));
        expect(copied.poisVisible, equals(25));
      });

      test('debe copiar sin modificaciones', () {
        const original = DebugMetrics(
          fps: 60.0,
          poisVisible: 25,
          poisTotal: 450,
        );

        final copied = original.copyWith();

        expect(copied.fps, equals(60.0));
        expect(copied.poisVisible, equals(25));
        expect(copied.poisTotal, equals(450));
      });

      test('debe copiar múltiples valores', () {
        const original = DebugMetrics(
          fps: 60.0,
          poisVisible: 25,
          poisTotal: 450,
        );

        final copied = original.copyWith(
          fps: 30.0,
          poisVisible: 50,
          cacheHitRate: 0.8,
        );

        expect(copied.fps, equals(30.0));
        expect(copied.poisVisible, equals(50));
        expect(copied.poisTotal, equals(450));
        expect(copied.cacheHitRate, equals(0.8));
      });

      test('debe copiar todos los valores de rendimiento', () {
        const original = DebugMetrics();

        final copied = original.copyWith(
          fps: 60.0,
          poisVisible: 25,
          poisTotal: 450,
          cacheHitRate: 0.85,
          projectionMs: 3.2,
          declutterMs: 1.8,
        );

        expect(copied.fps, equals(60.0));
        expect(copied.poisVisible, equals(25));
        expect(copied.poisTotal, equals(450));
        expect(copied.cacheHitRate, equals(0.85));
        expect(copied.projectionMs, equals(3.2));
        expect(copied.declutterMs, equals(1.8));
      });

      test('debe copiar todos los valores de filtros', () {
        const original = DebugMetrics();

        final copied = original.copyWith(
          horizonCulledPois: 12,
          importanceFilteredPois: 180,
          categoryFilteredPois: 50,
        );

        expect(copied.horizonCulledPois, equals(12));
        expect(copied.importanceFilteredPois, equals(180));
        expect(copied.categoryFilteredPois, equals(50));
      });

      test('debe copiar todos los valores de sensores', () {
        const original = DebugMetrics();

        final copied = original.copyWith(
          lat: 28.123456,
          lon: -16.543210,
          alt: 850.0,
          heading: 245.3,
          pitch: -10.5,
          roll: 2.3,
          calibrationOffset: -15.0,
        );

        expect(copied.lat, equals(28.123456));
        expect(copied.lon, equals(-16.543210));
        expect(copied.alt, equals(850.0));
        expect(copied.heading, equals(245.3));
        expect(copied.pitch, equals(-10.5));
        expect(copied.roll, equals(2.3));
        expect(copied.calibrationOffset, equals(-15.0));
      });

      test('debe copiar valores de sistema', () {
        const original = DebugMetrics();

        final copied = original.copyWith(
          isolateCallbacks: 100,
          cacheActive: true,
        );

        expect(copied.isolateCallbacks, equals(100));
        expect(copied.cacheActive, isTrue);
      });

      test('debe mantener valores null de sensores', () {
        const original = DebugMetrics();

        final copied = original.copyWith(fps: 60.0);

        expect(copied.fps, equals(60.0));
        expect(copied.lat, isNull);
        expect(copied.lon, isNull);
        expect(copied.alt, isNull);
        expect(copied.heading, isNull);
        expect(copied.pitch, isNull);
        expect(copied.roll, isNull);
      });

      test('debe poder actualizar sensores de null a valores', () {
        const original = DebugMetrics();

        final copied = original.copyWith(
          lat: 28.123456,
          lon: -16.543210,
        );

        expect(copied.lat, equals(28.123456));
        expect(copied.lon, equals(-16.543210));
        expect(copied.alt, isNull);
      });
    });

    group('Inmutabilidad', () {
      test('debe ser const', () {
        const metrics1 = DebugMetrics(fps: 60.0);
        const metrics2 = DebugMetrics(fps: 60.0);

        expect(identical(metrics1, metrics2), isTrue);
      });

      test('copyWith debe crear nueva instancia', () {
        const original = DebugMetrics(fps: 60.0);
        final copied = original.copyWith(fps: 60.0);

        expect(identical(original, copied), isFalse);
      });

      test('no debe permitir modificación después de creación', () {
        const metrics = DebugMetrics(fps: 60.0);

        // Verificar que todos los campos son final
        expect(metrics.fps, equals(60.0));

        // Intentar "modificar" debe crear nueva instancia
        final modified = metrics.copyWith(fps: 30.0);
        expect(metrics.fps, equals(60.0));
        expect(modified.fps, equals(30.0));
      });
    });

    group('Casos de Uso Reales', () {
      test('debe representar escenario de rendimiento óptimo', () {
        const metrics = DebugMetrics(
          fps: 58.3,
          poisVisible: 12,
          poisTotal: 450,
          cacheHitRate: 0.92,
          projectionMs: 3.2,
          declutterMs: 1.8,
          lat: 28.123456,
          lon: -16.543210,
          alt: 850.0,
          heading: 245.3,
          pitch: -10.5,
          cacheActive: true,
        );

        // Verificar que el escenario es óptimo
        expect(metrics.fps, greaterThan(55.0));
        expect(metrics.cacheHitRate, greaterThan(0.8));
        expect(metrics.projectionMs, lessThan(5.0));
        expect(metrics.declutterMs, lessThan(5.0));
      });

      test('debe representar escenario de FPS bajos', () {
        const metrics = DebugMetrics(
          fps: 24.1,
          poisVisible: 68,
          poisTotal: 1200,
          cacheHitRate: 0.35,
          projectionMs: 18.4,
          declutterMs: 15.2,
        );

        // Verificar que el escenario es problemático
        expect(metrics.fps, lessThan(30.0));
        expect(metrics.cacheHitRate, lessThan(0.5));
        expect(metrics.projectionMs, greaterThan(10.0));
        expect(metrics.declutterMs, greaterThan(10.0));
      });

      test('debe representar muchos POIs filtrados', () {
        const metrics = DebugMetrics(
          poisVisible: 25,
          poisTotal: 850,
          horizonCulledPois: 45,
          importanceFilteredPois: 180,
          categoryFilteredPois: 350,
        );

        final totalFiltered = metrics.horizonCulledPois + metrics.importanceFilteredPois + metrics.categoryFilteredPois;

        expect(totalFiltered, equals(575));
        expect(totalFiltered, greaterThan(metrics.poisVisible));
      });

      test('debe representar GPS sin señal', () {
        const metrics = DebugMetrics(
          fps: 60.0,
          poisVisible: 0,
          poisTotal: 450,
        );

        expect(metrics.lat, isNull);
        expect(metrics.lon, isNull);
        expect(metrics.alt, isNull);
        expect(metrics.heading, isNull);
      });

      test('debe representar calibración activa', () {
        const metrics = DebugMetrics(
          heading: 125.3,
          calibrationOffset: -42.0,
        );

        expect(metrics.calibrationOffset, isNot(equals(0.0)));
        expect(metrics.calibrationOffset.abs(), greaterThan(30.0));
      });
    });

    group('Valores Extremos', () {
      test('debe manejar FPS muy bajo', () {
        const metrics = DebugMetrics(fps: 5.0);
        expect(metrics.fps, equals(5.0));
      });

      test('debe manejar FPS muy alto', () {
        const metrics = DebugMetrics(fps: 120.0);
        expect(metrics.fps, equals(120.0));
      });

      test('debe manejar cache hit rate en límites', () {
        const metrics1 = DebugMetrics(cacheHitRate: 0.0);
        const metrics2 = DebugMetrics(cacheHitRate: 1.0);

        expect(metrics1.cacheHitRate, equals(0.0));
        expect(metrics2.cacheHitRate, equals(1.0));
      });

      test('debe manejar muchos POIs', () {
        const metrics = DebugMetrics(
          poisVisible: 500,
          poisTotal: 10000,
        );

        expect(metrics.poisVisible, equals(500));
        expect(metrics.poisTotal, equals(10000));
      });

      test('debe manejar tiempos de procesamiento altos', () {
        const metrics = DebugMetrics(
          projectionMs: 100.0,
          declutterMs: 100.0,
        );

        expect(metrics.projectionMs, equals(100.0));
        expect(metrics.declutterMs, equals(100.0));
      });

      test('debe manejar coordenadas en límites', () {
        const metrics = DebugMetrics(
          lat: 90.0,
          lon: 180.0,
          alt: 8848.0, // Monte Everest
        );

        expect(metrics.lat, equals(90.0));
        expect(metrics.lon, equals(180.0));
        expect(metrics.alt, equals(8848.0));
      });

      test('debe manejar ángulos en límites', () {
        const metrics = DebugMetrics(
          heading: 359.9,
          pitch: 90.0,
          roll: 180.0,
          calibrationOffset: 45.0,
        );

        expect(metrics.heading, equals(359.9));
        expect(metrics.pitch, equals(90.0));
        expect(metrics.roll, equals(180.0));
        expect(metrics.calibrationOffset, equals(45.0));
      });
    });

    group('Evolución de Métricas', () {
      test('debe simular mejora de rendimiento', () {
        const before = DebugMetrics(
          fps: 24.0,
          projectionMs: 18.4,
          declutterMs: 15.2,
        );

        final after = before.copyWith(
          fps: 58.0,
          projectionMs: 3.2,
          declutterMs: 1.8,
        );

        expect(after.fps, greaterThan(before.fps));
        expect(after.projectionMs, lessThan(before.projectionMs));
        expect(after.declutterMs, lessThan(before.declutterMs));
      });

      test('debe simular activación de filtros', () {
        const before = DebugMetrics(
          poisVisible: 250,
          poisTotal: 850,
        );

        final after = before.copyWith(
          poisVisible: 25,
          importanceFilteredPois: 180,
          categoryFilteredPois: 350,
        );

        expect(after.poisVisible, lessThan(before.poisVisible));
        expect(after.importanceFilteredPois, greaterThan(0));
        expect(after.categoryFilteredPois, greaterThan(0));
      });

      test('debe simular adquisición de GPS', () {
        const before = DebugMetrics(
          lat: null,
          lon: null,
        );

        final after = before.copyWith(
          lat: 28.123456,
          lon: -16.543210,
          alt: 850.0,
        );

        expect(after.lat, isNotNull);
        expect(after.lon, isNotNull);
        expect(after.alt, isNotNull);
      });

      test('debe simular aplicación de calibración', () {
        const before = DebugMetrics(
          heading: 125.3,
          calibrationOffset: 0.0,
        );

        final after = before.copyWith(
          calibrationOffset: -42.0,
        );

        expect(after.calibrationOffset, isNot(equals(before.calibrationOffset)));
        expect(after.heading, equals(before.heading));
      });
    });
  });
}
