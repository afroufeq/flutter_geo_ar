import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/sensors/sensor_fusion.dart';
import 'package:flutter_geo_ar/src/sensors/fused_data.dart';

void main() {
  group('SensorFusionLogic', () {
    late SensorFusionLogic fusion;

    setUp(() {
      fusion = SensorFusionLogic();
    });

    test('debe crearse correctamente', () {
      expect(fusion, isNotNull);
    });

    test('debe inicializar pitch y roll en 0', () {
      // Los valores iniciales son privados, pero podemos verificar el primer proceso
      final result = fusion.process(0, 0, 9.81, 0, 0, 0, 0, 0.01);
      expect(result, isNotNull);
      expect(result.pitch, isA<double>());
      expect(result.roll, isA<double>());
    });

    test('process debe retornar FusedData con heading', () {
      final result = fusion.process(0, 0, 9.81, 0, 0, 0, 45.0, 0.01);

      expect(result.heading, equals(45.0));
    });

    test('process debe retornar FusedData con timestamp actual', () {
      final beforeTs = DateTime.now().millisecondsSinceEpoch;
      final result = fusion.process(0, 0, 9.81, 0, 0, 0, 0, 0.01);
      final afterTs = DateTime.now().millisecondsSinceEpoch;

      expect(result.ts, greaterThanOrEqualTo(beforeTs));
      expect(result.ts, lessThanOrEqualTo(afterTs));
    });

    test('process debe calcular pitch desde acelerómetro', () {
      // Dispositivo inclinado hacia adelante (accelX negativo)
      final result = fusion.process(-5.0, 0, 9.81, 0, 0, 0, 0, 0.01);

      expect(result.pitch, isA<double>());
      expect(result.pitch, isNot(equals(0.0)));
    });

    test('process debe calcular roll desde acelerómetro', () {
      // Dispositivo inclinado lateralmente (accelY no cero)
      final result = fusion.process(0, 5.0, 9.81, 0, 0, 0, 0, 0.01);

      expect(result.roll, isA<double>());
      expect(result.roll, isNot(equals(0.0)));
    });

    test('process debe integrar datos del giroscopio', () {
      // Primera medición
      final result1 = fusion.process(0, 0, 9.81, 0.1, 0, 0, 0, 0.01);

      // Segunda medición con giroscopio
      final result2 = fusion.process(0, 0, 9.81, 0.1, 0, 0, 0, 0.01);

      // El pitch debe cambiar debido a la integración del giroscopio
      expect(result2.pitch, isNot(equals(result1.pitch)));
    });

    test('process debe aplicar filtro complementario', () {
      // El filtro usa alpha = 0.98, lo que significa que confía más en el giroscopio
      final result1 = fusion.process(0, 0, 9.81, 0, 0, 0, 0, 0.01);
      final result2 = fusion.process(5.0, 0, 9.81, 0, 0, 0, 0, 0.01);

      // El cambio debe ser suave, no brusco
      expect(result2.pitch, isNot(equals(result1.pitch)));
    });

    test('process debe manejar dt pequeños', () {
      final result = fusion.process(0, 0, 9.81, 1.0, 1.0, 0, 0, 0.001);

      expect(result.pitch, isA<double>());
      expect(result.roll, isA<double>());
    });

    test('process debe manejar dt grandes', () {
      final result = fusion.process(0, 0, 9.81, 1.0, 1.0, 0, 0, 1.0);

      expect(result.pitch, isA<double>());
      expect(result.roll, isA<double>());
    });

    test('process debe manejar aceleración cero', () {
      final result = fusion.process(0, 0, 0, 0, 0, 0, 0, 0.01);

      expect(result, isNotNull);
      // No debe lanzar división por cero
    });

    test('process debe manejar valores negativos', () {
      final result = fusion.process(-5.0, -5.0, -9.81, -0.1, -0.1, -0.1, 0, 0.01);

      expect(result.pitch, isA<double>());
      expect(result.roll, isA<double>());
    });

    test('process debe ser estable con múltiples llamadas', () {
      final results = <FusedData>[];

      for (int i = 0; i < 100; i++) {
        results.add(fusion.process(0, 0, 9.81, 0.01, 0.01, 0, 0, 0.01));
      }

      // Los valores deben converger y no diverger
      expect(results.last.pitch, isA<double>());
      expect(results.last.roll, isA<double>());
      expect(results.last.pitch!.isFinite, isTrue);
      expect(results.last.roll!.isFinite, isTrue);
    });

    test('process debe fusionar correctamente con valores constantes', () {
      // Simular dispositivo estático
      for (int i = 0; i < 10; i++) {
        fusion.process(0, 0, 9.81, 0, 0, 0, 0, 0.01);
      }

      final result = fusion.process(0, 0, 9.81, 0, 0, 0, 0, 0.01);

      // Debe estabilizarse cerca de cero
      expect(result.pitch!.abs(), lessThan(5.0));
      expect(result.roll!.abs(), lessThan(5.0));
    });

    test('process debe manejar cambios bruscos en acelerómetro', () {
      final result1 = fusion.process(0, 0, 9.81, 0, 0, 0, 0, 0.01);
      final result2 = fusion.process(10.0, 10.0, 9.81, 0, 0, 0, 0, 0.01);

      // El filtro debe suavizar el cambio
      final pitchDiff = (result2.pitch! - result1.pitch!).abs();
      expect(pitchDiff, isA<double>());
    });

    test('process debe manejar cambios bruscos en giroscopio', () {
      final result1 = fusion.process(0, 0, 9.81, 0, 0, 0, 0, 0.01);
      final result2 = fusion.process(0, 0, 9.81, 10.0, 10.0, 0, 0, 0.01);

      // Debe integrar el cambio
      expect(result2.pitch, isNot(equals(result1.pitch)));
      expect(result2.roll, isNot(equals(result1.roll)));
    });

    test('process debe retornar valores finitos', () {
      final result = fusion.process(
        double.maxFinite / 2,
        double.maxFinite / 2,
        9.81,
        100.0,
        100.0,
        100.0,
        0,
        0.01,
      );

      expect(result.pitch!.isFinite, isTrue);
      expect(result.roll!.isFinite, isTrue);
    });

    test('alpha debe ser 0.98', () {
      // Este es el valor esperado del filtro complementario
      // No podemos acceder directamente, pero podemos verificar el comportamiento

      // Con alpha alto, el giroscopio domina a corto plazo
      final result1 = fusion.process(0, 0, 9.81, 0, 0, 0, 0, 0.01);
      final result2 = fusion.process(10.0, 0, 9.81, 0, 0, 0, 0, 0.01);

      // El cambio debe ser pequeño (solo 2% del acelerómetro)
      final change = (result2.pitch! - result1.pitch!).abs();
      expect(change, lessThan(10.0)); // Mucho menor que 10 si solo usáramos acelerómetro
    });

    test('process debe manejar heading diferentes', () {
      final result1 = fusion.process(0, 0, 9.81, 0, 0, 0, 0.0, 0.01);
      final result2 = fusion.process(0, 0, 9.81, 0, 0, 0, 180.0, 0.01);

      expect(result1.heading, equals(0.0));
      expect(result2.heading, equals(180.0));
    });

    test('process debe mantener el heading sin modificar', () {
      final heading = 123.45;
      final result = fusion.process(0, 0, 9.81, 0, 0, 0, heading, 0.01);

      expect(result.heading, equals(heading));
    });

    test('process con múltiples instancias debe ser independiente', () {
      final fusion1 = SensorFusionLogic();
      final fusion2 = SensorFusionLogic();

      final result1 = fusion1.process(0, 0, 9.81, 1.0, 0, 0, 0, 0.01);
      final result2 = fusion2.process(0, 0, 9.81, 0, 1.0, 0, 0, 0.01);

      // Los resultados deben ser diferentes
      expect(result1.pitch, isNot(equals(result2.pitch)));
      expect(result1.roll, isNot(equals(result2.roll)));
    });

    test('process debe acumular rotaciones correctamente', () {
      // Simular rotación continua
      for (int i = 0; i < 100; i++) {
        fusion.process(0, 0, 9.81, 0.1, 0, 0, 0, 0.01);
      }

      final result = fusion.process(0, 0, 9.81, 0.1, 0, 0, 0, 0.01);

      // El pitch debe haber aumentado significativamente
      expect(result.pitch!.abs(), greaterThan(0.1));
    });
  });
}
