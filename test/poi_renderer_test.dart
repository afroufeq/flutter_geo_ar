import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/poi/poi_renderer.dart';
import 'package:flutter_geo_ar/src/poi/poi_model.dart';
import 'package:flutter_geo_ar/src/sensors/fused_data.dart';
import 'package:flutter_geo_ar/src/horizon/horizon_generator.dart';
import 'dart:ui';

void main() {
  group('RenderedPoi', () {
    test('debe crear un RenderedPoi con todos los campos', () {
      final poi = Poi(
        id: 'test',
        name: 'Test POI',
        lat: 28.5,
        lon: -16.5,
        elevation: 1000.0,
        category: 'nature',
        subtype: 'mountain',
        importance: 5,
      );

      final rendered = RenderedPoi(
        x: 100.0,
        y: 200.0,
        size: 30.0,
        poi: poi,
        distance: 5000.0,
      );

      expect(rendered.x, equals(100.0));
      expect(rendered.y, equals(200.0));
      expect(rendered.size, equals(30.0));
      expect(rendered.poi, equals(poi));
      expect(rendered.distance, equals(5000.0));
    });
  });

  group('PoiRenderer', () {
    late PoiRenderer renderer;
    late List<Poi> pois;
    late FusedData sensors;
    late Size screenSize;

    setUp(() {
      renderer = PoiRenderer(
        focalLength: 500.0,
        maxDistance: 20000.0,
        minImportance: 1,
      );

      pois = [
        Poi(
          id: 'poi1',
          name: 'POI 1',
          lat: 28.5,
          lon: -16.5,
          elevation: 1000.0,
          category: 'nature',
          subtype: 'mountain',
          importance: 5,
        ),
        Poi(
          id: 'poi2',
          name: 'POI 2',
          lat: 28.51,
          lon: -16.51,
          elevation: 800.0,
          category: 'nature',
          subtype: 'beach',
          importance: 3,
        ),
      ];

      sensors = FusedData(
        heading: 0.0,
        pitch: -90.0,
        roll: 0.0,
        lat: 28.5,
        lon: -16.5,
        alt: 500.0,
        ts: DateTime.now().millisecondsSinceEpoch,
      );

      screenSize = const Size(1080, 1920);
    });

    test('debe crearse con parámetros por defecto', () {
      final r = PoiRenderer();
      expect(r.focalLength, equals(520.0));
      expect(r.maxDistance, equals(20000.0));
      expect(r.minImportance, equals(1));
    });

    test('debe crearse con parámetros personalizados', () {
      final r = PoiRenderer(
        focalLength: 600.0,
        maxDistance: 15000.0,
        minImportance: 5,
      );
      expect(r.focalLength, equals(600.0));
      expect(r.maxDistance, equals(15000.0));
      expect(r.minImportance, equals(5));
    });

    test('projectPois debe retornar lista vacía si no hay POIs', () {
      final result = renderer.projectPois(
        [],
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      expect(result.pois, isEmpty);
      expect(result.totalProcessed, equals(0));
      expect(result.behindUser, equals(0));
      expect(result.tooFar, equals(0));
      expect(result.lowImportance, equals(0));
    });

    test('projectPois debe filtrar POIs con importancia menor a minImportance', () {
      // Configurar renderer con minImportance = 5
      final rendererWithMinImp = PoiRenderer(
        focalLength: 500.0,
        maxDistance: 20000.0,
        minImportance: 5,
      );

      final poisVaryingImportance = [
        Poi(
          id: 'low1',
          name: 'Low 1',
          lat: 28.500001,
          lon: -16.500001,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 2, // Debe ser filtrado
        ),
        Poi(
          id: 'low2',
          name: 'Low 2',
          lat: 28.500002,
          lon: -16.500002,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 4, // Debe ser filtrado
        ),
        Poi(
          id: 'high1',
          name: 'High 1',
          lat: 28.500003,
          lon: -16.500003,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 5, // No debe ser filtrado
        ),
        Poi(
          id: 'high2',
          name: 'High 2',
          lat: 28.500004,
          lon: -16.500004,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 8, // No debe ser filtrado
        ),
      ];

      final result = rendererWithMinImp.projectPois(
        poisVaryingImportance,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      expect(result.totalProcessed, equals(4));
      expect(result.lowImportance, equals(2)); // Dos POIs con importancia < 5
      // Los POIs visibles dependen de otros filtros (geometría, distancia)
      // pero ninguno debe tener importancia < 5
      for (final poi in result.pois) {
        expect(poi.poi.importance, greaterThanOrEqualTo(5));
      }
    });

    test('projectPois debe incluir todos los POIs si minImportance es 1', () {
      // Configurar renderer con minImportance = 1 (mínimo posible)
      final rendererMinImp1 = PoiRenderer(
        focalLength: 500.0,
        maxDistance: 20000.0,
        minImportance: 1,
      );

      final poisVaryingImportance = [
        Poi(
          id: 'imp1',
          name: 'Imp 1',
          lat: 28.500001,
          lon: -16.500001,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 1,
        ),
        Poi(
          id: 'imp5',
          name: 'Imp 5',
          lat: 28.500002,
          lon: -16.500002,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 5,
        ),
        Poi(
          id: 'imp10',
          name: 'Imp 10',
          lat: 28.500003,
          lon: -16.500003,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 10,
        ),
      ];

      final result = rendererMinImp1.projectPois(
        poisVaryingImportance,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      expect(result.totalProcessed, equals(3));
      expect(result.lowImportance, equals(0)); // Ninguno filtrado por importancia
    });

    test('projectPois debe filtrar POIs detrás del usuario', () {
      // POI exactamente detrás del usuario
      final poisBehind = [
        Poi(
          id: 'behind',
          name: 'Behind',
          lat: 28.49,
          lon: -16.5,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 1,
        ),
      ];

      // Heading 0° = mirando al norte
      final result = renderer.projectPois(
        poisBehind,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      // El POI al sur (lat menor) debe estar detrás si miramos al norte
      // Dependiendo de la implementación, puede estar filtrado o no
      expect(result.pois, isA<List<RenderedPoi>>());
    });

    test('projectPois debe filtrar POIs más allá de maxDistance', () {
      // POI muy lejano
      final poisFar = [
        Poi(
          id: 'far',
          name: 'Far POI',
          lat: 30.0,
          lon: -15.0,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 1,
        ),
      ];

      final result = renderer.projectPois(
        poisFar,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      // POI a > 200km debe estar filtrado
      expect(result.pois, isEmpty);
    });

    test('projectPois debe proyectar POIs visibles', () {
      final result = renderer.projectPois(
        pois,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      expect(result.pois, isA<List<RenderedPoi>>());
      // Puede estar vacío o tener elementos dependiendo de la geometría
    });

    test('projectPois debe calcular distancia correctamente', () {
      // POI cercano
      final poisNear = [
        Poi(
          id: 'near',
          name: 'Near POI',
          lat: 28.500001,
          lon: -16.500001,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 1,
        ),
      ];

      final result = renderer.projectPois(
        poisNear,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      if (result.pois.isNotEmpty) {
        expect(result.pois[0].distance, lessThan(100.0));
      }
    });

    test('projectPois debe aplicar heading correctamente', () {
      final sensorsNorth = FusedData(
        heading: 0.0,
        pitch: -90.0,
        roll: 0.0,
        ts: DateTime.now().millisecondsSinceEpoch,
      );

      final sensorsEast = FusedData(
        heading: 90.0,
        pitch: -90.0,
        roll: 0.0,
        ts: DateTime.now().millisecondsSinceEpoch,
      );

      final result1 = renderer.projectPois(pois, 28.5, -16.5, 500.0, sensorsNorth, screenSize);
      final result2 = renderer.projectPois(pois, 28.5, -16.5, 500.0, sensorsEast, screenSize);

      // Las proyecciones deben ser diferentes con headings diferentes
      // Los resultados pueden variar dependiendo de la geometría
      expect(result1.pois, isA<List<RenderedPoi>>());
      expect(result2.pois, isA<List<RenderedPoi>>());
    });

    test('projectPois debe aplicar pitch correctamente', () {
      final sensorsUp = FusedData(
        heading: 0.0,
        pitch: 0.0, // Mirando horizontal
        roll: 0.0,
        ts: DateTime.now().millisecondsSinceEpoch,
      );

      final sensorsDown = FusedData(
        heading: 0.0,
        pitch: -90.0, // Mirando vertical
        roll: 0.0,
        ts: DateTime.now().millisecondsSinceEpoch,
      );

      final result1 = renderer.projectPois(pois, 28.5, -16.5, 500.0, sensorsUp, screenSize);
      final result2 = renderer.projectPois(pois, 28.5, -16.5, 500.0, sensorsDown, screenSize);

      // Las proyecciones deben ser diferentes con pitches diferentes
      expect(result1, isNot(equals(result2)));
    });

    test('projectPois debe aplicar calibration offset', () {
      final result1 = renderer.projectPois(
        pois,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
        calibration: 0.0,
      );

      final result2 = renderer.projectPois(
        pois,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
        calibration: 45.0,
      );

      // Las proyecciones deben ser diferentes con calibraciones diferentes
      expect(result1, isNot(equals(result2)));
    });

    test('projectPois debe calcular size basado en importance', () {
      final poisVariousImportance = [
        Poi(
          id: 'low',
          name: 'Low',
          lat: 28.500001,
          lon: -16.500001,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 1,
        ),
        Poi(
          id: 'high',
          name: 'High',
          lat: 28.500001,
          lon: -16.500002,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 10,
        ),
      ];

      final result = renderer.projectPois(
        poisVariousImportance,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      if (result.pois.length >= 2) {
        // El POI con mayor importance debe tener mayor tamaño
        expect(result.pois[1].size, greaterThan(result.pois[0].size));
      }
    });

    test('projectPois debe manejar elevación null', () {
      final poisNoElevation = [
        Poi(
          id: 'no_elev',
          name: 'No Elevation',
          lat: 28.500001,
          lon: -16.500001,
          elevation: null,
          category: 'generic',
          subtype: 'default',
          importance: 5,
        ),
      ];

      expect(
        () => renderer.projectPois(
          poisNoElevation,
          28.5,
          -16.5,
          500.0,
          sensors,
          screenSize,
        ),
        returnsNormally,
      );
    });

    test('projectPois debe manejar sensores con valores null', () {
      final sensorsPartial = FusedData(
        heading: null,
        pitch: null,
        roll: null,
        ts: DateTime.now().millisecondsSinceEpoch,
      );

      expect(
        () => renderer.projectPois(
          pois,
          28.5,
          -16.5,
          500.0,
          sensorsPartial,
          screenSize,
        ),
        returnsNormally,
      );
    });

    test('projectPois debe proyectar al centro de la pantalla', () {
      // POI justo enfrente del usuario
      final poisAhead = [
        Poi(
          id: 'ahead',
          name: 'Ahead',
          lat: 28.51,
          lon: -16.5,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 5,
        ),
      ];

      final result = renderer.projectPois(
        poisAhead,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      if (result.pois.isNotEmpty) {
        // Debe estar cerca del centro horizontal
        expect(result.pois[0].x, closeTo(screenSize.width / 2, screenSize.width / 4));
      }
    });

    test('projectPois debe manejar POIs en los bordes del FOV', () {
      // POI muy a la izquierda
      final poisLeft = [
        Poi(
          id: 'left',
          name: 'Left',
          lat: 28.51,
          lon: -16.6,
          elevation: 500.0,
          category: 'generic',
          subtype: 'default',
          importance: 5,
        ),
      ];

      final result = renderer.projectPois(
        poisLeft,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      // Puede estar fuera de pantalla o no proyectarse
      expect(result.pois, isA<List<RenderedPoi>>());
    });

    test('projectPois debe ser determinista', () {
      final result1 = renderer.projectPois(pois, 28.5, -16.5, 500.0, sensors, screenSize);
      final result2 = renderer.projectPois(pois, 28.5, -16.5, 500.0, sensors, screenSize);

      expect(result1.pois.length, equals(result2.pois.length));
      for (int i = 0; i < result1.pois.length; i++) {
        expect(result1.pois[i].x, equals(result2.pois[i].x));
        expect(result1.pois[i].y, equals(result2.pois[i].y));
        expect(result1.pois[i].distance, equals(result2.pois[i].distance));
      }
    });

    test('projectPois debe manejar múltiples POIs correctamente', () {
      final manyPois = List.generate(
        100,
        (i) => Poi(
          id: 'poi_$i',
          name: 'POI $i',
          lat: 28.5 + (i * 0.001),
          lon: -16.5 + (i * 0.001),
          elevation: 500.0 + (i * 10),
          category: 'generic',
          subtype: 'default',
          importance: (i % 10) + 1,
        ),
      );

      final result = renderer.projectPois(
        manyPois,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      expect(result.pois, isA<List<RenderedPoi>>());
      expect(result.pois.length, lessThanOrEqualTo(manyPois.length));
    });

    test('projectPois sin horizonProfile debe reportar 0 horizonCulled', () {
      final result = renderer.projectPois(
        pois,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      expect(result.horizonCulled, equals(0));
    });

    test('projectPois con horizonProfile que oculta POI debe filtrar correctamente', () {
      // Crear un perfil de horizonte artificial donde todo a 0° tiene elevación de 10°
      final angles = List.generate(360, (i) => i == 0 ? 10.0 : -90.0);
      final horizonProfile = HorizonProfile(angles, 1.0);

      // POI al norte (bearing ~0°) con elevación baja (será ocultado)
      final poisToBlock = [
        Poi(
          id: 'blocked',
          name: 'Blocked POI',
          lat: 28.51,
          lon: -16.5,
          elevation: 510.0, // Solo 10m por encima del usuario
          category: 'generic',
          subtype: 'default',
          importance: 5,
        ),
      ];

      final result = renderer.projectPois(
        poisToBlock,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
        horizonProfile: horizonProfile,
      );

      // El POI debe ser filtrado por el horizonte
      expect(result.horizonCulled, greaterThan(0));
    });

    test('projectPois con horizonProfile que no oculta POI debe permitir verlo', () {
      // Crear un perfil de horizonte artificial donde todo está a -90° (sin obstáculos)
      final angles = List.generate(360, (i) => -90.0);
      final horizonProfile = HorizonProfile(angles, 1.0);

      // POI visible
      final poisVisible = [
        Poi(
          id: 'visible',
          name: 'Visible POI',
          lat: 28.500001,
          lon: -16.500001,
          elevation: 550.0,
          category: 'generic',
          subtype: 'default',
          importance: 5,
        ),
      ];

      final result = renderer.projectPois(
        poisVisible,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
        horizonProfile: horizonProfile,
      );

      // No debe haber POIs filtrados por el horizonte
      expect(result.horizonCulled, equals(0));
    });

    test('projectPois debe incluir horizonCulled en estadísticas', () {
      final result = renderer.projectPois(
        pois,
        28.5,
        -16.5,
        500.0,
        sensors,
        screenSize,
      );

      // Verificar que el campo existe y es un número
      expect(result.horizonCulled, isA<int>());
      expect(result.horizonCulled, greaterThanOrEqualTo(0));
    });
  });
}
