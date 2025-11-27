import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/horizon/horizon_generator.dart';
import 'package:flutter_geo_ar/src/poi/dem_service.dart';

class MockDemService extends DemService {
  @override
  Future<void> init([String? assetPath]) async {
    // Mock: no hacer nada
  }

  @override
  double? getElevation(double lat, double lon) {
    // Retornar elevaciones simuladas
    if (lat >= 28.0 && lat <= 29.0 && lon >= -17.0 && lon <= -16.0) {
      return 1000.0 + (lat - 28.0) * 500; // Simulación simple
    }
    return null;
  }
}

void main() {
  group('HorizonProfile', () {
    test('debe crear un perfil con ángulos y step', () {
      final angles = List.filled(360, 0.0);
      final profile = HorizonProfile(angles, 1.0);

      expect(profile.angles.length, equals(360));
      expect(profile.step, equals(1.0));
    });

    test('isOccluded debe retornar true si el ángulo es menor al horizonte', () {
      final angles = List.generate(360, (i) => 5.0); // Horizonte a 5 grados
      final profile = HorizonProfile(angles, 1.0);

      expect(profile.isOccluded(0, 3.0), isTrue); // 3° < 5° - ocluido
      expect(profile.isOccluded(0, 7.0), isFalse); // 7° > 5° - visible
    });

    test('isOccluded debe manejar bearing negativo', () {
      final angles = List.generate(360, (i) => 5.0);
      final profile = HorizonProfile(angles, 1.0);

      expect(profile.isOccluded(-10, 3.0), isTrue);
      expect(profile.isOccluded(-10, 7.0), isFalse);
    });

    test('isOccluded debe manejar bearing mayor a 360', () {
      final angles = List.generate(360, (i) => 5.0);
      final profile = HorizonProfile(angles, 1.0);

      expect(profile.isOccluded(370, 3.0), isTrue); // 370 % 360 = 10
      expect(profile.isOccluded(370, 7.0), isFalse);
    });

    test('isOccluded debe usar tolerancia correctamente', () {
      final angles = List.generate(360, (i) => 5.0);
      final profile = HorizonProfile(angles, 1.0);

      // Con tolerancia de 0.5°, el horizonte efectivo es 4.5°
      expect(profile.isOccluded(0, 4.6, toleranceDeg: 0.5), isFalse);
      expect(profile.isOccluded(0, 4.4, toleranceDeg: 0.5), isTrue);
    });

    test('isOccluded debe manejar índices fuera de rango', () {
      final angles = List.filled(180, 5.0); // Solo 180 puntos
      final profile = HorizonProfile(angles, 2.0); // Step de 2 grados

      expect(() => profile.isOccluded(359, 3.0), returnsNormally);
    });
  });

  group('HorizonGenerator', () {
    late MockDemService mockDem;
    late HorizonGenerator generator;

    setUp(() {
      mockDem = MockDemService();
      generator = HorizonGenerator(mockDem, raySteps: 50, stepMeters: 100.0);
    });

    test('debe crearse con parámetros por defecto', () {
      final gen = HorizonGenerator(mockDem);
      expect(gen.dem, equals(mockDem));
      expect(gen.raySteps, equals(100));
      expect(gen.stepMeters, equals(100.0));
    });

    test('debe crearse con parámetros personalizados', () {
      final gen = HorizonGenerator(mockDem, raySteps: 200, stepMeters: 50.0);
      expect(gen.raySteps, equals(200));
      expect(gen.stepMeters, equals(50.0));
    });

    test('compute debe generar perfil con resolución angular especificada', () async {
      final profile = await generator.compute(28.5, -16.5, 100.0, angularRes: 5.0);

      expect(profile.angles.length, equals(72)); // 360 / 5 = 72
      expect(profile.step, equals(5.0));
    });

    test('compute debe generar perfil con resolución angular de 1 grado', () async {
      final profile = await generator.compute(28.5, -16.5, 100.0, angularRes: 1.0);

      expect(profile.angles.length, equals(360));
      expect(profile.step, equals(1.0));
    });

    test('compute debe calcular ángulos de elevación', () async {
      final profile = await generator.compute(28.5, -16.5, 100.0, angularRes: 10.0);

      // Verificar que los ángulos no son todos -90 (valor por defecto)
      final hasValidAngles = profile.angles.any((angle) => angle > -90.0);
      expect(hasValidAngles, isTrue);
    });

    test('compute debe manejar altitudes diferentes', () async {
      final profile1 = await generator.compute(28.5, -16.5, 0.0, angularRes: 10.0);
      final profile2 = await generator.compute(28.5, -16.5, 500.0, angularRes: 10.0);

      expect(profile1.angles.length, equals(profile2.angles.length));
    });

    test('compute debe generar perfiles diferentes para ubicaciones diferentes', () async {
      final profile1 = await generator.compute(28.3, -16.5, 100.0, angularRes: 10.0);
      final profile2 = await generator.compute(28.7, -16.5, 100.0, angularRes: 10.0);

      // Los perfiles deben ser diferentes (al menos en algunos ángulos)
      expect(profile1.angles, isNot(equals(profile2.angles)));
    });

    test('_destination debe calcular coordenadas correctamente', () async {
      // Este es un test indirecto a través de compute
      final profile = await generator.compute(28.5, -16.5, 100.0);
      expect(profile, isNotNull);
      expect(profile.angles, isNotEmpty);
    });

    test('compute debe manejar raySteps bajo', () async {
      final genLowSteps = HorizonGenerator(mockDem, raySteps: 5, stepMeters: 100.0);
      final profile = await genLowSteps.compute(28.5, -16.5, 100.0, angularRes: 45.0);

      expect(profile.angles.length, equals(8)); // 360 / 45 = 8
    });

    test('compute debe manejar raySteps alto', () async {
      final genHighSteps = HorizonGenerator(mockDem, raySteps: 200, stepMeters: 50.0);
      final profile = await genHighSteps.compute(28.5, -16.5, 100.0, angularRes: 90.0);

      expect(profile.angles.length, equals(4)); // 360 / 90 = 4
    });

    test('compute debe completarse en tiempo razonable', () async {
      final stopwatch = Stopwatch()..start();
      await generator.compute(28.5, -16.5, 100.0, angularRes: 2.0);
      stopwatch.stop();

      // Debe completarse en menos de 5 segundos
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
