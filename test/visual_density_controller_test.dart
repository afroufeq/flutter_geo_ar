import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/widgets/visual_density_controller.dart';
import 'package:flutter_geo_ar/src/poi/declutter_mode.dart';

void main() {
  group('VisualDensityPreset', () {
    test('tiene todos los valores esperados', () {
      expect(VisualDensityPreset.values, hasLength(5));
      expect(VisualDensityPreset.values, contains(VisualDensityPreset.minimal));
      expect(VisualDensityPreset.values, contains(VisualDensityPreset.low));
      expect(VisualDensityPreset.values, contains(VisualDensityPreset.normal));
      expect(VisualDensityPreset.values, contains(VisualDensityPreset.high));
      expect(VisualDensityPreset.values, contains(VisualDensityPreset.maximum));
    });
  });

  group('VisualDensityController', () {
    test('se crea con densidad inicial por defecto (0.5)', () {
      final controller = VisualDensityController();
      expect(controller.density, equals(0.5));
    });

    test('se crea con densidad inicial personalizada', () {
      final controller = VisualDensityController(initialDensity: 0.75);
      expect(controller.density, equals(0.75));
    });

    test('limita densidad inicial fuera de rango (menor a 0.0)', () {
      final controller = VisualDensityController(initialDensity: -0.5);
      expect(controller.density, equals(0.0));
    });

    test('limita densidad inicial fuera de rango (mayor a 1.0)', () {
      final controller = VisualDensityController(initialDensity: 1.5);
      expect(controller.density, equals(1.0));
    });

    test('calcula maxDistance correctamente en densidad mínima (0.0)', () {
      final controller = VisualDensityController(initialDensity: 0.0);
      expect(controller.maxDistance, equals(5000.0));
    });

    test('calcula maxDistance correctamente en densidad normal (0.5)', () {
      final controller = VisualDensityController(initialDensity: 0.5);
      expect(controller.maxDistance, equals(27500.0));
    });

    test('calcula maxDistance correctamente en densidad máxima (1.0)', () {
      final controller = VisualDensityController(initialDensity: 1.0);
      expect(controller.maxDistance, equals(50000.0));
    });

    test('calcula minImportance correctamente en densidad mínima (0.0)', () {
      final controller = VisualDensityController(initialDensity: 0.0);
      expect(controller.minImportance, equals(10));
    });

    test('calcula minImportance correctamente en densidad normal (0.5)', () {
      final controller = VisualDensityController(initialDensity: 0.5);
      expect(controller.minImportance, equals(6)); // 10 - (0.5 * 9) = 5.5 -> round() = 6
    });

    test('calcula minImportance correctamente en densidad máxima (1.0)', () {
      final controller = VisualDensityController(initialDensity: 1.0);
      expect(controller.minImportance, equals(1));
    });

    test('calcula declutterMode como aggressive para densidad < 0.3', () {
      final controller1 = VisualDensityController(initialDensity: 0.0);
      expect(controller1.declutterMode, equals(DeclutterMode.aggressive));

      final controller2 = VisualDensityController(initialDensity: 0.29);
      expect(controller2.declutterMode, equals(DeclutterMode.aggressive));
    });

    test('calcula declutterMode como normal para densidad entre 0.3 y 0.7', () {
      final controller1 = VisualDensityController(initialDensity: 0.3);
      expect(controller1.declutterMode, equals(DeclutterMode.normal));

      final controller2 = VisualDensityController(initialDensity: 0.5);
      expect(controller2.declutterMode, equals(DeclutterMode.normal));

      final controller3 = VisualDensityController(initialDensity: 0.69);
      expect(controller3.declutterMode, equals(DeclutterMode.normal));
    });

    test('calcula declutterMode como light para densidad entre 0.7 y 0.9', () {
      final controller1 = VisualDensityController(initialDensity: 0.7);
      expect(controller1.declutterMode, equals(DeclutterMode.light));

      final controller2 = VisualDensityController(initialDensity: 0.8);
      expect(controller2.declutterMode, equals(DeclutterMode.light));

      final controller3 = VisualDensityController(initialDensity: 0.89);
      expect(controller3.declutterMode, equals(DeclutterMode.light));
    });

    test('calcula declutterMode como off para densidad >= 0.9', () {
      final controller1 = VisualDensityController(initialDensity: 0.9);
      expect(controller1.declutterMode, equals(DeclutterMode.off));

      final controller2 = VisualDensityController(initialDensity: 1.0);
      expect(controller2.declutterMode, equals(DeclutterMode.off));
    });

    test('setDensity actualiza el valor de densidad', () {
      final controller = VisualDensityController(initialDensity: 0.5);
      controller.setDensity(0.75);
      expect(controller.density, equals(0.75));
    });

    test('setDensity limita valores fuera de rango', () {
      final controller = VisualDensityController();

      controller.setDensity(-0.5);
      expect(controller.density, equals(0.0));

      controller.setDensity(1.5);
      expect(controller.density, equals(1.0));
    });

    test('setDensity notifica listeners cuando cambia', () {
      final controller = VisualDensityController(initialDensity: 0.5);
      var notified = false;

      controller.addListener(() {
        notified = true;
      });

      controller.setDensity(0.75);
      expect(notified, isTrue);
    });

    test('setDensity no notifica listeners cuando no cambia el valor', () {
      final controller = VisualDensityController(initialDensity: 0.5);
      var notifyCount = 0;

      controller.addListener(() {
        notifyCount++;
      });

      controller.setDensity(0.5); // Mismo valor
      expect(notifyCount, equals(0));
    });

    test('setDensity ejecuta callback cuando cambia', () {
      double? callbackDensity;
      double? callbackMaxDistance;
      int? callbackMinImportance;
      DeclutterMode? callbackDeclutterMode;

      final controller = VisualDensityController(
        initialDensity: 0.5,
        onDensityChanged: (density, maxDistance, minImportance, declutterMode) {
          callbackDensity = density;
          callbackMaxDistance = maxDistance;
          callbackMinImportance = minImportance;
          callbackDeclutterMode = declutterMode;
        },
      );

      controller.setDensity(0.75);

      expect(callbackDensity, equals(0.75));
      expect(callbackMaxDistance, equals(38750.0));
      expect(callbackMinImportance, equals(3));
      expect(callbackDeclutterMode, equals(DeclutterMode.light));
    });

    test('setDensity no ejecuta callback cuando no cambia el valor', () {
      var callbackCount = 0;

      final controller = VisualDensityController(
        initialDensity: 0.5,
        onDensityChanged: (_, __, ___, ____) {
          callbackCount++;
        },
      );

      controller.setDensity(0.5); // Mismo valor
      expect(callbackCount, equals(0));
    });

    test('setPreset establece densidad correcta para minimal', () {
      final controller = VisualDensityController();
      controller.setPreset(VisualDensityPreset.minimal);
      expect(controller.density, equals(0.0));
    });

    test('setPreset establece densidad correcta para low', () {
      final controller = VisualDensityController();
      controller.setPreset(VisualDensityPreset.low);
      expect(controller.density, equals(0.25));
    });

    test('setPreset establece densidad correcta para normal', () {
      final controller = VisualDensityController();
      controller.setPreset(VisualDensityPreset.normal);
      expect(controller.density, equals(0.5));
    });

    test('setPreset establece densidad correcta para high', () {
      final controller = VisualDensityController();
      controller.setPreset(VisualDensityPreset.high);
      expect(controller.density, equals(0.75));
    });

    test('setPreset establece densidad correcta para maximum', () {
      final controller = VisualDensityController();
      controller.setPreset(VisualDensityPreset.maximum);
      expect(controller.density, equals(1.0));
    });

    test('setPreset notifica listeners', () {
      final controller = VisualDensityController(initialDensity: 0.5);
      var notified = false;

      controller.addListener(() {
        notified = true;
      });

      controller.setPreset(VisualDensityPreset.high);
      expect(notified, isTrue);
    });

    test('setPreset ejecuta callback', () {
      double? callbackDensity;

      final controller = VisualDensityController(
        onDensityChanged: (density, _, __, ___) {
          callbackDensity = density;
        },
      );

      controller.setPreset(VisualDensityPreset.high);
      expect(callbackDensity, equals(0.75));
    });

    test('getPresetValue retorna valores correctos', () {
      expect(
        VisualDensityController.getPresetValue(VisualDensityPreset.minimal),
        equals(0.0),
      );
      expect(
        VisualDensityController.getPresetValue(VisualDensityPreset.low),
        equals(0.25),
      );
      expect(
        VisualDensityController.getPresetValue(VisualDensityPreset.normal),
        equals(0.5),
      );
      expect(
        VisualDensityController.getPresetValue(VisualDensityPreset.high),
        equals(0.75),
      );
      expect(
        VisualDensityController.getPresetValue(VisualDensityPreset.maximum),
        equals(1.0),
      );
    });

    test('mapeo de maxDistance es lineal', () {
      final controller = VisualDensityController();

      controller.setDensity(0.0);
      final dist0 = controller.maxDistance;

      controller.setDensity(0.5);
      final dist50 = controller.maxDistance;

      controller.setDensity(1.0);
      final dist100 = controller.maxDistance;

      // Verificar que el mapeo es lineal
      expect(dist50, equals((dist0 + dist100) / 2));
    });

    test('mapeo de minImportance es inverso', () {
      final controller = VisualDensityController();

      controller.setDensity(0.0);
      final imp0 = controller.minImportance;

      controller.setDensity(1.0);
      final imp100 = controller.minImportance;

      // Verificar que es inverso (mayor densidad = menor importancia mínima)
      expect(imp0, greaterThan(imp100));
    });

    test('valores calculados se actualizan al cambiar densidad', () {
      final controller = VisualDensityController(initialDensity: 0.0);

      final initialMaxDistance = controller.maxDistance;
      final initialMinImportance = controller.minImportance;
      final initialDeclutterMode = controller.declutterMode;

      controller.setDensity(1.0);

      expect(controller.maxDistance, isNot(equals(initialMaxDistance)));
      expect(controller.minImportance, isNot(equals(initialMinImportance)));
      expect(controller.declutterMode, isNot(equals(initialDeclutterMode)));
    });

    test('múltiples listeners reciben notificaciones', () {
      final controller = VisualDensityController(initialDensity: 0.5);
      var listener1Called = false;
      var listener2Called = false;

      controller.addListener(() {
        listener1Called = true;
      });

      controller.addListener(() {
        listener2Called = true;
      });

      controller.setDensity(0.75);

      expect(listener1Called, isTrue);
      expect(listener2Called, isTrue);
    });

    test('removeListener funciona correctamente', () {
      final controller = VisualDensityController(initialDensity: 0.5);
      var callCount = 0;

      void listener() {
        callCount++;
      }

      controller.addListener(listener);
      controller.setDensity(0.6);
      expect(callCount, equals(1));

      controller.removeListener(listener);
      controller.setDensity(0.7);
      expect(callCount, equals(1)); // No debe incrementar
    });

    test('preset minimal tiene valores correctos', () {
      final controller = VisualDensityController();
      controller.setPreset(VisualDensityPreset.minimal);

      expect(controller.density, equals(0.0));
      expect(controller.maxDistance, equals(5000.0));
      expect(controller.minImportance, equals(10));
      expect(controller.declutterMode, equals(DeclutterMode.aggressive));
    });

    test('preset low tiene valores correctos', () {
      final controller = VisualDensityController();
      controller.setPreset(VisualDensityPreset.low);

      expect(controller.density, equals(0.25));
      expect(controller.maxDistance, equals(16250.0));
      expect(controller.minImportance, equals(8));
      expect(controller.declutterMode, equals(DeclutterMode.aggressive));
    });

    test('preset normal tiene valores correctos', () {
      final controller = VisualDensityController();
      controller.setPreset(VisualDensityPreset.normal);

      expect(controller.density, equals(0.5));
      expect(controller.maxDistance, equals(27500.0));
      expect(controller.minImportance, equals(6)); // 10 - (0.5 * 9) = 5.5 -> round() = 6
      expect(controller.declutterMode, equals(DeclutterMode.normal));
    });

    test('preset high tiene valores correctos', () {
      final controller = VisualDensityController();
      controller.setPreset(VisualDensityPreset.high);

      expect(controller.density, equals(0.75));
      expect(controller.maxDistance, equals(38750.0));
      expect(controller.minImportance, equals(3));
      expect(controller.declutterMode, equals(DeclutterMode.light));
    });

    test('preset maximum tiene valores correctos', () {
      final controller = VisualDensityController();
      controller.setPreset(VisualDensityPreset.maximum);

      expect(controller.density, equals(1.0));
      expect(controller.maxDistance, equals(50000.0));
      expect(controller.minImportance, equals(1));
      expect(controller.declutterMode, equals(DeclutterMode.off));
    });

    test('cambios graduales de densidad producen valores consistentes', () {
      final controller = VisualDensityController(initialDensity: 0.0);
      var previousMaxDistance = controller.maxDistance;
      var previousMinImportance = controller.minImportance;

      for (var i = 1; i <= 10; i++) {
        controller.setDensity(i * 0.1);

        // maxDistance debe incrementar
        expect(controller.maxDistance, greaterThanOrEqualTo(previousMaxDistance));

        // minImportance debe decrecer o mantenerse
        expect(controller.minImportance, lessThanOrEqualTo(previousMinImportance));

        previousMaxDistance = controller.maxDistance;
        previousMinImportance = controller.minImportance;
      }
    });

    test('maneja valores extremos de densidad', () {
      final controller = VisualDensityController();

      // Valores muy pequeños
      controller.setDensity(0.0001);
      expect(controller.density, equals(0.0001));
      expect(controller.maxDistance, greaterThan(5000.0));

      // Valores muy cercanos a 1
      controller.setDensity(0.9999);
      expect(controller.density, equals(0.9999));
      expect(controller.maxDistance, lessThan(50000.0));
    });

    test('dispose limpia correctamente', () {
      final controller = VisualDensityController();

      controller.addListener(() {
        // Listener de prueba
      });

      controller.dispose();

      // Después de dispose, no debería notificar
      expect(() => controller.setDensity(0.75), throwsA(isA<AssertionError>()));
    });

    test('callback puede ser null', () {
      final controller = VisualDensityController(
        initialDensity: 0.5,
        onDensityChanged: null,
      );

      // No debe lanzar error al cambiar densidad sin callback
      expect(() => controller.setDensity(0.75), returnsNormally);
    });

    test('transición entre modos de declutter es correcta', () {
      final controller = VisualDensityController();

      // aggressive -> normal
      controller.setDensity(0.29);
      expect(controller.declutterMode, equals(DeclutterMode.aggressive));
      controller.setDensity(0.30);
      expect(controller.declutterMode, equals(DeclutterMode.normal));

      // normal -> light
      controller.setDensity(0.69);
      expect(controller.declutterMode, equals(DeclutterMode.normal));
      controller.setDensity(0.70);
      expect(controller.declutterMode, equals(DeclutterMode.light));

      // light -> off
      controller.setDensity(0.89);
      expect(controller.declutterMode, equals(DeclutterMode.light));
      controller.setDensity(0.90);
      expect(controller.declutterMode, equals(DeclutterMode.off));
    });
  });
}
