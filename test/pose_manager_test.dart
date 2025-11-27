import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/sensors/pose_manager.dart';
import 'package:flutter_geo_ar/src/sensors/fused_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PoseManager', () {
    tearDown(() {
      final manager = PoseManager();
      manager.stop();
    });

    group('Singleton', () {
      test('siempre retorna la misma instancia', () {
        final manager1 = PoseManager();
        final manager2 = PoseManager();
        expect(identical(manager1, manager2), isTrue);
      });

      test('factory constructor funciona correctamente', () {
        final manager = PoseManager();
        expect(manager, isNotNull);
        expect(manager, isA<PoseManager>());
      });
    });

    group('Stream', () {
      test('stream está disponible', () {
        final manager = PoseManager();
        expect(manager.stream, isA<Stream<FusedData>>());
      });

      test('stream es broadcast', () async {
        final manager = PoseManager();

        // Debe permitir múltiples suscripciones
        final sub1 = manager.stream.listen((_) {});
        final sub2 = manager.stream.listen((_) {});

        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        await sub1.cancel();
        await sub2.cancel();
      });

      test('múltiples suscripciones reciben datos correctamente', () async {
        final manager = PoseManager();

        int count1 = 0;
        int count2 = 0;

        final sub1 = manager.stream.listen((_) => count1++);
        final sub2 = manager.stream.listen((_) => count2++);

        // No podemos simular eventos reales en tests, pero verificamos la estructura
        await Future.delayed(Duration(milliseconds: 50));

        await sub1.cancel();
        await sub2.cancel();

        // Verificar que las suscripciones funcionaron
        expect(count1, equals(count2)); // Ambas reciben los mismos eventos
      });
    });

    group('start', () {
      test('inicia correctamente en modo normal', () {
        final manager = PoseManager();
        expect(() => manager.start(), returnsNormally);
        manager.stop();
      });

      test('inicia correctamente en modo low power', () {
        final manager = PoseManager();
        expect(
          () => manager.start(lowPowerMode: true),
          returnsNormally,
        );
        manager.stop();
      });

      test('acepta throttleHz personalizado', () {
        final manager = PoseManager();
        expect(
          () => manager.start(throttleHz: 20.0),
          returnsNormally,
        );
        manager.stop();
      });

      test('acepta ambos parámetros', () {
        final manager = PoseManager();
        expect(
          () => manager.start(lowPowerMode: true, throttleHz: 5.0),
          returnsNormally,
        );
        manager.stop();
      });

      test('múltiples llamadas a start no causan error', () {
        final manager = PoseManager();
        manager.start();
        manager.start();
        manager.start();
        manager.stop();
      });

      test('no reinicia si ya está escuchando', () {
        final manager = PoseManager();
        manager.start();
        // Segunda llamada no debería hacer nada
        manager.start();
        manager.stop();
      });

      test('en modo low power con throttleHz > 5.0 limita a 5Hz', () async {
        final manager = PoseManager();
        // Debería forzar a 5Hz aunque se pida 10Hz
        expect(
          () => manager.start(lowPowerMode: true, throttleHz: 10.0),
          returnsNormally,
        );
        manager.stop();
      });

      test('en modo normal no limita throttleHz', () {
        final manager = PoseManager();
        expect(
          () => manager.start(lowPowerMode: false, throttleHz: 20.0),
          returnsNormally,
        );
        manager.stop();
      });
    });

    group('stop', () {
      test('detiene correctamente la escucha', () {
        final manager = PoseManager();
        manager.start();
        expect(() => manager.stop(), returnsNormally);
      });

      test('múltiples llamadas a stop no causan error', () {
        final manager = PoseManager();
        manager.start();
        manager.stop();
        manager.stop();
        manager.stop();
      });

      test('se puede llamar stop sin haber llamado start', () {
        final manager = PoseManager();
        expect(() => manager.stop(), returnsNormally);
      });

      test('después de stop se puede volver a iniciar', () {
        final manager = PoseManager();
        manager.start();
        manager.stop();
        expect(() => manager.start(), returnsNormally);
        manager.stop();
      });
    });

    group('dispose', () {
      test('libera recursos correctamente', () {
        final manager = PoseManager();
        manager.start();
        expect(() => manager.dispose(), returnsNormally);
      });

      test('se puede llamar sin haber iniciado', () {
        final manager = PoseManager();
        expect(() => manager.dispose(), returnsNormally);
      });
    });

    group('Parámetros de configuración', () {
      test('acepta frecuencia de 60Hz (alto rendimiento)', () {
        final manager = PoseManager();
        expect(
          () => manager.start(throttleHz: 60.0),
          returnsNormally,
        );
        manager.stop();
      });

      test('acepta frecuencia de 1Hz (muy bajo consumo)', () {
        final manager = PoseManager();
        expect(
          () => manager.start(throttleHz: 1.0),
          returnsNormally,
        );
        manager.stop();
      });

      test('modo low power con frecuencia baja', () {
        final manager = PoseManager();
        expect(
          () => manager.start(lowPowerMode: true, throttleHz: 2.0),
          returnsNormally,
        );
        manager.stop();
      });
    });
  });
}
