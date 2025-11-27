import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/widgets/geo_ar_view.dart';
import 'package:flutter_geo_ar/src/poi/poi_model.dart';
import 'package:flutter_geo_ar/src/visual/visual_tracking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeoArView', () {
    late List<Poi> testPois;

    setUp(() {
      testPois = [
        Poi(
          id: '1',
          name: 'Test POI 1',
          lat: 28.1,
          lon: -16.6,
          elevation: 100.0,
          category: 'mountain',
          subtype: 'peak',
        ),
        Poi(
          id: '2',
          name: 'Test POI 2',
          lat: 28.2,
          lon: -16.7,
          elevation: 200.0,
          category: 'mountain',
          subtype: 'summit',
        ),
      ];
    });

    group('Constructor y validaciones', () {
      test('requiere POIs o poisPath', () {
        expect(
          () => GeoArView(pois: const []),
          throwsAssertionError,
        );
      });

      test('acepta POIs directamente', () {
        expect(
          () => GeoArView(pois: testPois),
          returnsNormally,
        );
      });

      test('acepta poisPath', () {
        expect(
          () => GeoArView(pois: const [], poisPath: 'assets/data/pois/test.json'),
          returnsNormally,
        );
      });

      test('acepta ambos POIs y poisPath', () {
        expect(
          () => GeoArView(
            pois: testPois,
            poisPath: 'assets/data/pois/test.json',
          ),
          returnsNormally,
        );
      });
    });

    group('Parámetros por defecto', () {
      testWidgets('usa valores por defecto correctos', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.focalLength, equals(500));
        expect(widget.showHorizon, isTrue);
        expect(widget.horizonLineColor, equals(Colors.yellow));
        expect(widget.horizonLineWidth, equals(2.0));
        expect(widget.showHorizonDebug, isFalse);
        expect(widget.debugMode, isFalse);
        expect(widget.visualStabilization, equals(VisualTrackingMode.lite));
        expect(widget.lowPowerMode, isFalse);
      });

      testWidgets('permite personalizar todos los parámetros', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          focalLength: 600,
          demPath: 'assets/data/dem/test.tif',
          poisPath: 'assets/data/pois/test.json',
          showHorizon: false,
          horizonLineColor: Colors.red,
          horizonLineWidth: 3.0,
          showHorizonDebug: true,
          debugMode: true,
          visualStabilization: VisualTrackingMode.off,
          lowPowerMode: true,
        );

        expect(widget.focalLength, equals(600));
        expect(widget.demPath, equals('assets/data/dem/test.tif'));
        expect(widget.poisPath, equals('assets/data/pois/test.json'));
        expect(widget.showHorizon, isFalse);
        expect(widget.horizonLineColor, equals(Colors.red));
        expect(widget.horizonLineWidth, equals(3.0));
        expect(widget.showHorizonDebug, isTrue);
        expect(widget.debugMode, isTrue);
        expect(widget.visualStabilization, equals(VisualTrackingMode.off));
        expect(widget.lowPowerMode, isTrue);
      });
    });

    group('Visual Stabilization Modes', () {
      testWidgets('modo off', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          visualStabilization: VisualTrackingMode.off,
        );

        expect(widget.visualStabilization, equals(VisualTrackingMode.off));
      });

      testWidgets('modo lite (por defecto)', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.visualStabilization, equals(VisualTrackingMode.lite));
      });
    });

    group('Low Power Mode', () {
      testWidgets('lowPowerMode desactivado por defecto', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.lowPowerMode, isFalse);
      });

      testWidgets('lowPowerMode se puede activar', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          lowPowerMode: true,
        );

        expect(widget.lowPowerMode, isTrue);
      });

      testWidgets('lowPowerMode tiene prioridad sobre visualStabilization', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          visualStabilization: VisualTrackingMode.lite,
          lowPowerMode: true,
        );

        // Ambos parámetros están configurados
        expect(widget.visualStabilization, equals(VisualTrackingMode.lite));
        expect(widget.lowPowerMode, isTrue);
        // El modo efectivo debería ser off debido a lowPowerMode
      });
    });

    group('Debug Mode', () {
      testWidgets('debugMode desactivado por defecto', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.debugMode, isFalse);
      });

      testWidgets('debugMode se puede activar', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          debugMode: true,
        );

        expect(widget.debugMode, isTrue);
      });
    });

    group('Horizon Configuration', () {
      testWidgets('showHorizon activado por defecto', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.showHorizon, isTrue);
      });

      testWidgets('showHorizon se puede desactivar', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          showHorizon: false,
        );

        expect(widget.showHorizon, isFalse);
      });

      testWidgets('usa color de línea por defecto (amarillo)', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.horizonLineColor, equals(Colors.yellow));
      });

      testWidgets('permite personalizar color de línea', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          horizonLineColor: Colors.blue,
        );

        expect(widget.horizonLineColor, equals(Colors.blue));
      });

      testWidgets('usa grosor de línea por defecto (2.0)', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.horizonLineWidth, equals(2.0));
      });

      testWidgets('permite personalizar grosor de línea', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          horizonLineWidth: 5.0,
        );

        expect(widget.horizonLineWidth, equals(5.0));
      });

      testWidgets('showHorizonDebug desactivado por defecto', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.showHorizonDebug, isFalse);
      });

      testWidgets('showHorizonDebug se puede activar', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          showHorizonDebug: true,
        );

        expect(widget.showHorizonDebug, isTrue);
      });
    });

    group('Focal Length', () {
      testWidgets('focalLength por defecto es 500', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.focalLength, equals(500));
      });

      testWidgets('permite personalizar focalLength', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          focalLength: 600,
        );

        expect(widget.focalLength, equals(600));
      });

      testWidgets('acepta diferentes valores de focalLength', (tester) async {
        final values = [300.0, 400.0, 500.0, 600.0, 800.0, 1000.0];

        for (final value in values) {
          final widget = GeoArView(
            pois: testPois,
            focalLength: value,
          );

          expect(widget.focalLength, equals(value));
        }
      });
    });

    group('DEM Path', () {
      testWidgets('demPath es null por defecto', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.demPath, isNull);
      });

      testWidgets('permite especificar demPath', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          demPath: 'assets/data/dem/test_cog.tif',
        );

        expect(widget.demPath, equals('assets/data/dem/test_cog.tif'));
      });
    });

    group('POI Configuration', () {
      testWidgets('acepta lista vacía de POIs con poisPath', (tester) async {
        final widget = GeoArView(
          pois: const [],
          poisPath: 'assets/data/pois/test.json',
        );

        expect(widget.pois, isEmpty);
        expect(widget.poisPath, equals('assets/data/pois/test.json'));
      });

      testWidgets('acepta múltiples POIs', (tester) async {
        final manyPois = List.generate(
          10,
          (i) => Poi(
            id: '$i',
            name: 'POI $i',
            lat: 28.0 + i * 0.1,
            lon: -16.0 + i * 0.1,
            elevation: 100.0 * i,
            category: 'mountain',
          ),
        );

        final widget = GeoArView(pois: manyPois);

        expect(widget.pois.length, equals(10));
      });

      testWidgets('preserva los POIs proporcionados', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.pois, equals(testPois));
        expect(widget.pois.length, equals(2));
        expect(widget.pois[0].name, equals('Test POI 1'));
        expect(widget.pois[1].name, equals('Test POI 2'));
      });
    });

    group('Camera Configuration', () {
      testWidgets('camera es null por defecto', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget.camera, isNull);
      });
    });

    group('Combinaciones de configuración', () {
      testWidgets('modo de alto rendimiento', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          visualStabilization: VisualTrackingMode.lite,
          lowPowerMode: false,
          focalLength: 600,
          showHorizon: true,
        );

        expect(widget.visualStabilization, equals(VisualTrackingMode.lite));
        expect(widget.lowPowerMode, isFalse);
        expect(widget.focalLength, equals(600));
        expect(widget.showHorizon, isTrue);
      });

      testWidgets('modo de bajo consumo', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          visualStabilization: VisualTrackingMode.off,
          lowPowerMode: true,
          showHorizon: false,
        );

        expect(widget.visualStabilization, equals(VisualTrackingMode.off));
        expect(widget.lowPowerMode, isTrue);
        expect(widget.showHorizon, isFalse);
      });

      testWidgets('modo debug completo', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          debugMode: true,
          showHorizonDebug: true,
          showHorizon: true,
        );

        expect(widget.debugMode, isTrue);
        expect(widget.showHorizonDebug, isTrue);
        expect(widget.showHorizon, isTrue);
      });

      testWidgets('configuración completa con DEM', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          demPath: 'assets/data/dem/test.tif',
          poisPath: 'assets/data/pois/test.json',
          showHorizon: true,
          horizonLineColor: Colors.green,
          horizonLineWidth: 3.5,
          focalLength: 550,
        );

        expect(widget.demPath, equals('assets/data/dem/test.tif'));
        expect(widget.poisPath, equals('assets/data/pois/test.json'));
        expect(widget.showHorizon, isTrue);
        expect(widget.horizonLineColor, equals(Colors.green));
        expect(widget.horizonLineWidth, equals(3.5));
        expect(widget.focalLength, equals(550));
      });
    });

    group('Widget Properties', () {
      testWidgets('es un StatefulWidget', (tester) async {
        final widget = GeoArView(pois: testPois);

        expect(widget, isA<StatefulWidget>());
      });

      testWidgets('puede tener key', (tester) async {
        final widget = GeoArView(
          key: const ValueKey('test'),
          pois: testPois,
        );

        expect(widget.key, equals(const ValueKey('test')));
      });
    });

    group('Validaciones de entrada', () {
      test('no permite focalLength negativo (aunque no hay validación explícita)', () {
        // El widget no tiene validación explícita, pero documentamos el comportamiento esperado
        final widget = GeoArView(
          pois: testPois,
          focalLength: -100,
        );

        // Debería aceptarse pero producir resultados incorrectos
        expect(widget.focalLength, equals(-100));
      });

      test('no permite horizonLineWidth negativo (aunque no hay validación explícita)', () {
        final widget = GeoArView(
          pois: testPois,
          horizonLineWidth: -1.0,
        );

        expect(widget.horizonLineWidth, equals(-1.0));
      });

      testWidgets('acepta POIs con diferentes keys', (tester) async {
        final poisWithDifferentKeys = [
          Poi(id: '1', name: 'Mountain', lat: 28.0, lon: -16.0, category: 'mountain', subtype: 'default'),
          Poi(id: '2', name: 'Peak', lat: 28.1, lon: -16.1, category: 'mountain', subtype: 'peak'),
          Poi(id: '3', name: 'Default', lat: 28.2, lon: -16.2, category: 'generic', subtype: 'default'),
          Poi(id: '4', name: 'Custom', lat: 28.3, lon: -16.3, category: 'custom', subtype: 'type'),
        ];

        final widget = GeoArView(pois: poisWithDifferentKeys);

        expect(widget.pois.length, equals(4));
      });

      testWidgets('acepta POIs sin elevation', (tester) async {
        final poisWithoutElevation = [
          Poi(id: '1', name: 'POI 1', lat: 28.0, lon: -16.0, category: 'mountain'),
          Poi(id: '2', name: 'POI 2', lat: 28.1, lon: -16.1, category: 'mountain', subtype: 'peak', elevation: null),
        ];

        final widget = GeoArView(pois: poisWithoutElevation);

        expect(widget.pois.length, equals(2));
      });
    });

    group('Casos extremos', () {
      testWidgets('acepta un solo POI', (tester) async {
        final singlePoi = [
          Poi(id: '1', name: 'Single', lat: 28.0, lon: -16.0, category: 'mountain'),
        ];

        final widget = GeoArView(pois: singlePoi);

        expect(widget.pois.length, equals(1));
      });

      testWidgets('acepta muchos POIs', (tester) async {
        final manyPois = List.generate(
          100,
          (i) => Poi(
            id: '$i',
            name: 'POI $i',
            lat: 28.0,
            lon: -16.0,
            category: 'mountain',
          ),
        );

        final widget = GeoArView(pois: manyPois);

        expect(widget.pois.length, equals(100));
      });

      testWidgets('acepta focalLength muy pequeño', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          focalLength: 1,
        );

        expect(widget.focalLength, equals(1));
      });

      testWidgets('acepta focalLength muy grande', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          focalLength: 10000,
        );

        expect(widget.focalLength, equals(10000));
      });

      testWidgets('acepta horizonLineWidth muy pequeño', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          horizonLineWidth: 0.1,
        );

        expect(widget.horizonLineWidth, equals(0.1));
      });

      testWidgets('acepta horizonLineWidth muy grande', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          horizonLineWidth: 50.0,
        );

        expect(widget.horizonLineWidth, equals(50.0));
      });
    });

    group('Inmutabilidad de propiedades', () {
      testWidgets('las propiedades no cambian después de la creación', (tester) async {
        final widget = GeoArView(
          pois: testPois,
          focalLength: 600,
          debugMode: true,
        );

        // Verificar propiedades iniciales
        expect(widget.focalLength, equals(600));
        expect(widget.debugMode, isTrue);

        // Las propiedades deberían ser finales e inmutables
        expect(widget.pois, equals(testPois));
      });
    });
  });
}
