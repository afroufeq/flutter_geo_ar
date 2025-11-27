import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/utils/telemetry_service.dart';

void main() {
  group('TelemetryService', () {
    late TelemetryService service;

    setUp(() {
      service = TelemetryService();
      service.reset();
    });

    tearDown(() {
      service.reset();
    });

    test('debe ser un singleton', () {
      final service1 = TelemetryService();
      final service2 = TelemetryService();
      expect(identical(service1, service2), isTrue);
    });

    test('debe inicializar callbacks en 0', () {
      expect(service.callbacks, equals(0));
    });

    group('Frame Timing', () {
      test('debe registrar un tiempo de frame', () {
        service.recordFrameTime(16000); // 16ms en microsegundos
        expect(service.avgFrameMs(), equals(16.0));
      });

      test('debe registrar múltiples tiempos', () {
        service.recordFrameTime(10000);
        service.recordFrameTime(20000);
        service.recordFrameTime(30000);
        expect(service.avgFrameMs(), equals(20.0));
      });

      test('debe mantener máximo 60 muestras', () {
        for (int i = 0; i < 100; i++) {
          service.recordFrameTime(10000);
        }
        expect(service.avgFrameMs(), equals(10.0));
      });

      test('debe calcular FPS correctamente', () {
        service.recordFrameTime(16667); // ~60 FPS
        expect(service.fps, closeTo(60.0, 0.1));
      });

      test('debe retornar FPS 0 si no hay muestras', () {
        expect(service.fps, equals(0.0));
      });

      test('debe calcular FPS con múltiples muestras', () {
        for (int i = 0; i < 10; i++) {
          service.recordFrameTime(33333); // ~30 FPS
        }
        expect(service.fps, closeTo(30.0, 0.5));
      });
    });

    group('Performance Metrics', () {
      test('debe registrar tiempo de projection', () {
        service.recordProjectionTime(5.2);
        final metrics = service.getMetrics();
        expect(metrics.projectionMs, equals(5.2));
      });

      test('debe registrar tiempo de declutter', () {
        service.recordDeclutterTime(3.8);
        final metrics = service.getMetrics();
        expect(metrics.declutterMs, equals(3.8));
      });

      test('debe actualizar múltiples métricas de performance', () {
        service.recordProjectionTime(5.0);
        service.recordDeclutterTime(3.0);

        final metrics = service.getMetrics();
        expect(metrics.projectionMs, equals(5.0));
        expect(metrics.declutterMs, equals(3.0));
      });
    });

    group('Cache Metrics', () {
      test('debe registrar cache hit', () {
        service.recordCacheHit();
        expect(service.cacheHitRate, equals(1.0));
      });

      test('debe registrar cache miss', () {
        service.recordCacheMiss();
        expect(service.cacheHitRate, equals(0.0));
      });

      test('debe calcular hit rate correctamente', () {
        service.recordCacheHit();
        service.recordCacheHit();
        service.recordCacheHit();
        service.recordCacheMiss();
        expect(service.cacheHitRate, equals(0.75));
      });

      test('debe retornar 0.0 si no hay eventos de cache', () {
        expect(service.cacheHitRate, equals(0.0));
      });

      test('debe actualizar hit rate continuamente', () {
        service.recordCacheHit();
        expect(service.cacheHitRate, equals(1.0));

        service.recordCacheMiss();
        expect(service.cacheHitRate, equals(0.5));

        service.recordCacheHit();
        expect(service.cacheHitRate, closeTo(0.667, 0.01));
      });
    });

    group('POI Metrics', () {
      test('debe actualizar métricas de POIs', () {
        service.updatePoiMetrics(
          visible: 25,
          total: 450,
        );

        final metrics = service.getMetrics();
        expect(metrics.poisVisible, equals(25));
        expect(metrics.poisTotal, equals(450));
      });

      test('debe actualizar métricas de filtros', () {
        service.updatePoiMetrics(
          visible: 25,
          total: 450,
          horizonCulled: 12,
          importanceFiltered: 180,
          categoryFiltered: 50,
        );

        final metrics = service.getMetrics();
        expect(metrics.horizonCulledPois, equals(12));
        expect(metrics.importanceFilteredPois, equals(180));
        expect(metrics.categoryFilteredPois, equals(50));
      });

      test('debe permitir valores opcionales de filtros', () {
        service.updatePoiMetrics(
          visible: 10,
          total: 100,
        );

        final metrics = service.getMetrics();
        expect(metrics.horizonCulledPois, equals(0));
        expect(metrics.importanceFilteredPois, equals(0));
        expect(metrics.categoryFilteredPois, equals(0));
      });
    });

    group('Sensor Data', () {
      test('debe actualizar datos de GPS', () {
        service.updateSensorData(
          lat: 28.123456,
          lon: -16.543210,
          alt: 850.0,
        );

        final metrics = service.getMetrics();
        expect(metrics.lat, equals(28.123456));
        expect(metrics.lon, equals(-16.543210));
        expect(metrics.alt, equals(850.0));
      });

      test('debe actualizar datos de orientación', () {
        service.updateSensorData(
          heading: 245.3,
          pitch: -10.5,
          roll: 2.3,
        );

        final metrics = service.getMetrics();
        expect(metrics.heading, equals(245.3));
        expect(metrics.pitch, equals(-10.5));
        expect(metrics.roll, equals(2.3));
      });

      test('debe actualizar calibración', () {
        service.updateSensorData(
          calibrationOffset: -15.0,
        );

        final metrics = service.getMetrics();
        expect(metrics.calibrationOffset, equals(-15.0));
      });

      test('debe manejar sensores null', () {
        final metrics = service.getMetrics();
        expect(metrics.lat, isNull);
        expect(metrics.lon, isNull);
        expect(metrics.alt, isNull);
        expect(metrics.heading, isNull);
        expect(metrics.pitch, isNull);
        expect(metrics.roll, isNull);
      });

      test('debe actualizar todos los sensores a la vez', () {
        service.updateSensorData(
          lat: 28.123456,
          lon: -16.543210,
          alt: 850.0,
          heading: 245.3,
          pitch: -10.5,
          roll: 2.3,
          calibrationOffset: -15.0,
        );

        final metrics = service.getMetrics();
        expect(metrics.lat, equals(28.123456));
        expect(metrics.lon, equals(-16.543210));
        expect(metrics.alt, equals(850.0));
        expect(metrics.heading, equals(245.3));
        expect(metrics.pitch, equals(-10.5));
        expect(metrics.roll, equals(2.3));
        expect(metrics.calibrationOffset, equals(-15.0));
      });
    });

    group('Callbacks', () {
      test('debe incrementar contador', () {
        expect(service.callbacks, equals(0));
        service.tickCallback();
        expect(service.callbacks, equals(1));
      });

      test('debe incrementar contador múltiples veces', () {
        for (int i = 0; i < 10; i++) {
          service.tickCallback();
        }
        expect(service.callbacks, equals(10));
      });

      test('debe reflejarse en las métricas', () {
        service.tickCallback();
        service.tickCallback();
        service.tickCallback();

        final metrics = service.getMetrics();
        expect(metrics.isolateCallbacks, equals(3));
      });
    });

    group('getMetrics', () {
      test('debe retornar métricas completas', () {
        service.recordFrameTime(16667);
        service.recordProjectionTime(5.2);
        service.recordDeclutterTime(3.1);
        service.recordCacheHit();
        service.recordCacheHit();
        service.recordCacheMiss();
        service.updatePoiMetrics(
          visible: 25,
          total: 450,
          horizonCulled: 12,
          importanceFiltered: 180,
          categoryFiltered: 50,
        );
        service.updateSensorData(
          lat: 28.123456,
          lon: -16.543210,
          alt: 850.0,
          heading: 245.3,
          pitch: -10.5,
          roll: 2.3,
          calibrationOffset: -15.0,
        );
        service.tickCallback();

        final metrics = service.getMetrics();

        expect(metrics.fps, closeTo(60.0, 0.1));
        expect(metrics.projectionMs, equals(5.2));
        expect(metrics.declutterMs, equals(3.1));
        expect(metrics.cacheHitRate, closeTo(0.667, 0.01));
        expect(metrics.poisVisible, equals(25));
        expect(metrics.poisTotal, equals(450));
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
        expect(metrics.isolateCallbacks, equals(1));
        expect(metrics.cacheActive, isTrue);
      });

      test('debe retornar métricas con valores por defecto', () {
        final metrics = service.getMetrics();

        expect(metrics.fps, equals(0.0));
        expect(metrics.projectionMs, equals(0.0));
        expect(metrics.declutterMs, equals(0.0));
        expect(metrics.cacheHitRate, equals(0.0));
        expect(metrics.poisVisible, equals(0));
        expect(metrics.poisTotal, equals(0));
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

      test('cacheActive debe ser true cuando hay cache hits', () {
        service.recordCacheHit();
        final metrics = service.getMetrics();
        expect(metrics.cacheActive, isTrue);
      });

      test('cacheActive debe ser false cuando no hay cache', () {
        final metrics = service.getMetrics();
        expect(metrics.cacheActive, isFalse);
      });
    });

    group('reset', () {
      test('debe limpiar todos los datos', () {
        service.recordFrameTime(16667);
        service.recordProjectionTime(5.2);
        service.recordDeclutterTime(3.1);
        service.recordCacheHit();
        service.updatePoiMetrics(visible: 25, total: 450);
        service.updateSensorData(lat: 28.123456, lon: -16.543210);
        service.tickCallback();

        service.reset();

        expect(service.fps, equals(0.0));
        expect(service.cacheHitRate, equals(0.0));
        expect(service.callbacks, equals(0));

        final metrics = service.getMetrics();
        expect(metrics.fps, equals(0.0));
        expect(metrics.projectionMs, equals(0.0));
        expect(metrics.declutterMs, equals(0.0));
        expect(metrics.cacheHitRate, equals(0.0));
        expect(metrics.poisVisible, equals(0));
        expect(metrics.poisTotal, equals(0));
        expect(metrics.lat, isNull);
        expect(metrics.lon, isNull);
        expect(metrics.calibrationOffset, equals(0.0));
      });
    });

    group('debugLog', () {
      test('debe ejecutarse sin error', () {
        expect(() => service.debugLog(), returnsNormally);
      });

      test('debe ejecutarse con datos', () {
        service.recordFrameTime(16667);
        service.updatePoiMetrics(visible: 25, total: 450);
        service.tickCallback();
        expect(() => service.debugLog(), returnsNormally);
      });
    });

    group('singleton behavior', () {
      test('debe compartir estado entre instancias', () {
        final service1 = TelemetryService();
        final service2 = TelemetryService();

        service1.recordFrameTime(16667);
        expect(service2.fps, closeTo(60.0, 0.1));

        service2.recordCacheHit();
        expect(service1.cacheHitRate, equals(1.0));
      });
    });

    group('Escenarios Reales', () {
      test('debe simular rendimiento óptimo 60fps', () {
        for (int i = 0; i < 60; i++) {
          service.recordFrameTime(16667);
        }
        service.recordProjectionTime(3.2);
        service.recordDeclutterTime(1.8);
        service.recordCacheHit();
        service.recordCacheHit();
        service.recordCacheHit();
        service.recordCacheMiss();
        service.updatePoiMetrics(visible: 12, total: 450);

        final metrics = service.getMetrics();
        expect(metrics.fps, closeTo(60.0, 0.5));
        expect(metrics.projectionMs, lessThan(5.0));
        expect(metrics.declutterMs, lessThan(5.0));
        expect(metrics.cacheHitRate, greaterThan(0.7));
      });

      test('debe simular rendimiento bajo 30fps', () {
        for (int i = 0; i < 60; i++) {
          service.recordFrameTime(33333);
        }
        service.recordProjectionTime(18.4);
        service.recordDeclutterTime(15.2);
        service.recordCacheMiss();
        service.recordCacheMiss();
        service.recordCacheHit();
        service.updatePoiMetrics(visible: 68, total: 1200);

        final metrics = service.getMetrics();
        expect(metrics.fps, closeTo(30.0, 0.5));
        expect(metrics.projectionMs, greaterThan(10.0));
        expect(metrics.declutterMs, greaterThan(10.0));
        expect(metrics.cacheHitRate, lessThan(0.5));
      });

      test('debe simular GPS inestable', () {
        service.updateSensorData(
          lat: 28.123456,
          lon: -16.543210,
          alt: 850.0,
        );

        // Simular jitter
        service.updateSensorData(
          lat: 28.123478,
          lon: -16.543210,
          alt: 862.0,
        );

        service.updateSensorData(
          lat: 28.123442,
          lon: -16.543210,
          alt: 847.0,
        );

        final metrics = service.getMetrics();
        expect(metrics.lat, isNotNull);
        expect(metrics.lon, isNotNull);
        expect(metrics.alt, isNotNull);
      });

      test('debe simular muchos POIs filtrados', () {
        service.updatePoiMetrics(
          visible: 25,
          total: 850,
          horizonCulled: 45,
          importanceFiltered: 180,
          categoryFiltered: 350,
        );

        final metrics = service.getMetrics();
        final totalFiltered = metrics.horizonCulledPois + metrics.importanceFilteredPois + metrics.categoryFilteredPois;
        expect(totalFiltered, equals(575));
      });
    });

    group('Rendimiento', () {
      test('recordFrameTime debe ser rápido', () {
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          service.recordFrameTime(16667);
        }
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('getMetrics debe ser rápido', () {
        for (int i = 0; i < 60; i++) {
          service.recordFrameTime(16667);
        }

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          service.getMetrics();
        }
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
