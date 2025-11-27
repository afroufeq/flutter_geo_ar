import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/storage/calibration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalibrationService', () {
    late CalibrationService service;

    setUp(() {
      service = CalibrationService();
      SharedPreferences.setMockInitialValues({});
    });

    test('debe crearse correctamente', () {
      expect(service, isNotNull);
    });

    test('debe tener calibrationKey correcto', () {
      expect(CalibrationService.calibrationKey, equals('heading_offset'));
    });

    group('init', () {
      test('debe inicializar SharedPreferences', () async {
        await service.init();
        // No debe lanzar excepción
      });

      test('debe poder llamarse múltiples veces', () async {
        await service.init();
        await service.init();
        // No debe lanzar excepción
      });
    });

    group('loadCalibration', () {
      test('debe retornar 0.0 si no hay valor guardado', () async {
        final value = await service.loadCalibration();
        expect(value, equals(0.0));
      });

      test('debe inicializar automáticamente si no está inicializado', () async {
        final value = await service.loadCalibration();
        expect(value, isA<double>());
      });

      test('debe retornar el valor guardado', () async {
        await service.init();
        await service.saveCalibration(45.5);

        final value = await service.loadCalibration();
        expect(value, equals(45.5));
      });

      test('debe retornar valores negativos correctamente', () async {
        await service.init();
        await service.saveCalibration(-30.0);

        final value = await service.loadCalibration();
        expect(value, equals(-30.0));
      });

      test('debe retornar valores decimales correctamente', () async {
        await service.init();
        await service.saveCalibration(123.456);

        final value = await service.loadCalibration();
        expect(value, closeTo(123.456, 0.001));
      });
    });

    group('saveCalibration', () {
      test('debe guardar valor correctamente', () async {
        await service.saveCalibration(90.0);
        final value = await service.loadCalibration();
        expect(value, equals(90.0));
      });

      test('debe inicializar automáticamente si no está inicializado', () async {
        await service.saveCalibration(180.0);
        // No debe lanzar excepción
      });

      test('debe sobrescribir valor anterior', () async {
        await service.saveCalibration(10.0);
        await service.saveCalibration(20.0);

        final value = await service.loadCalibration();
        expect(value, equals(20.0));
      });

      test('debe guardar cero correctamente', () async {
        await service.saveCalibration(45.0);
        await service.saveCalibration(0.0);

        final value = await service.loadCalibration();
        expect(value, equals(0.0));
      });

      test('debe guardar valores muy grandes', () async {
        await service.saveCalibration(360.0);
        final value = await service.loadCalibration();
        expect(value, equals(360.0));
      });

      test('debe guardar valores muy pequeños', () async {
        await service.saveCalibration(-360.0);
        final value = await service.loadCalibration();
        expect(value, equals(-360.0));
      });

      test('debe guardar valores decimales precisos', () async {
        const testValue = 12.3456789;
        await service.saveCalibration(testValue);
        final value = await service.loadCalibration();
        expect(value, closeTo(testValue, 0.0000001));
      });
    });

    group('close', () {
      test('debe ejecutarse sin error', () async {
        await service.close();
        // No debe lanzar excepción
      });

      test('debe ejecutarse sin inicializar', () async {
        final newService = CalibrationService();
        await newService.close();
        // No debe lanzar excepción
      });

      test('debe poder llamarse múltiples veces', () async {
        await service.close();
        await service.close();
        // No debe lanzar excepción
      });
    });

    group('flujo completo', () {
      test('debe mantener valor entre init y close', () async {
        await service.init();
        await service.saveCalibration(75.5);
        await service.close();

        final value = await service.loadCalibration();
        expect(value, equals(75.5));
      });

      test('debe funcionar sin llamar a init explícitamente', () async {
        await service.saveCalibration(50.0);
        final value = await service.loadCalibration();
        expect(value, equals(50.0));
      });

      test('debe persistir valor entre múltiples operaciones', () async {
        await service.saveCalibration(10.0);
        await service.loadCalibration();
        await service.saveCalibration(20.0);
        await service.loadCalibration();
        await service.saveCalibration(30.0);

        final value = await service.loadCalibration();
        expect(value, equals(30.0));
      });
    });

    group('valores límite', () {
      test('debe manejar NaN', () async {
        await service.saveCalibration(double.nan);
        final value = await service.loadCalibration();
        expect(value.isNaN, isTrue);
      });

      test('debe manejar infinito positivo', () async {
        await service.saveCalibration(double.infinity);
        final value = await service.loadCalibration();
        expect(value, equals(double.infinity));
      });

      test('debe manejar infinito negativo', () async {
        await service.saveCalibration(double.negativeInfinity);
        final value = await service.loadCalibration();
        expect(value, equals(double.negativeInfinity));
      });

      test('debe manejar el máximo double', () async {
        await service.saveCalibration(double.maxFinite);
        final value = await service.loadCalibration();
        expect(value, equals(double.maxFinite));
      });

      test('debe manejar el mínimo double', () async {
        await service.saveCalibration(-double.maxFinite);
        final value = await service.loadCalibration();
        expect(value, equals(-double.maxFinite));
      });
    });

    group('concurrencia', () {
      test('debe manejar múltiples saves concurrentes', () async {
        await Future.wait([
          service.saveCalibration(1.0),
          service.saveCalibration(2.0),
          service.saveCalibration(3.0),
        ]);

        final value = await service.loadCalibration();
        expect(value, isA<double>());
      });

      test('debe manejar save y load concurrentes', () async {
        await Future.wait([
          service.saveCalibration(10.0),
          service.loadCalibration(),
          service.loadCalibration(),
        ]);

        // No debe lanzar excepción
        expect(true, isTrue);
      });
    });

    group('rendimiento', () {
      test('loadCalibration debe ser rápido', () async {
        final stopwatch = Stopwatch()..start();
        await service.loadCalibration();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('saveCalibration debe ser rápido', () async {
        final stopwatch = Stopwatch()..start();
        await service.saveCalibration(45.0);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('debe manejar múltiples operaciones rápidamente', () async {
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 10; i++) {
          await service.saveCalibration(i.toDouble());
          await service.loadCalibration();
        }
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
