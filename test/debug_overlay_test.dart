import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/widgets/debug_overlay.dart';
import 'package:flutter_geo_ar/src/utils/telemetry_service.dart';

void main() {
  group('DebugOverlay Widget', () {
    late TelemetryService telemetry;

    setUp(() {
      telemetry = TelemetryService();
      telemetry.reset();
    });

    tearDown(() {
      telemetry.reset();
    });

    testWidgets('debe renderizar el widget correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [DebugOverlay()],
            ),
          ),
        ),
      );

      expect(find.byType(DebugOverlay), findsOneWidget);
      expect(find.text('DEPURACIÓN'), findsOneWidget);
      expect(find.text('SENSORES'), findsOneWidget);
    });

    testWidgets('debe posicionarse en la esquina inferior derecha', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [DebugOverlay()],
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.bottom, equals(10.0));
      expect(positioned.right, equals(10.0));
    });

    testWidgets('debe mostrar sección de DEPURACIÓN por defecto', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(),
          ),
        ),
      );

      expect(find.text('DEPURACIÓN'), findsOneWidget);
      expect(find.text('FPS'), findsOneWidget);
      expect(find.text('POIs visible/total'), findsOneWidget);
      expect(find.text('Cache hit rate'), findsOneWidget);
      expect(find.text('Projection time'), findsOneWidget);
      expect(find.text('Declutter time'), findsOneWidget);
    });

    testWidgets('debe ocultar sección de DEPURACIÓN cuando showPerformanceMetrics es false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(showPerformanceMetrics: false),
          ),
        ),
      );

      expect(find.text('DEPURACIÓN'), findsNothing);
      expect(find.text('FPS'), findsNothing);
      expect(find.text('SENSORES'), findsOneWidget);
    });

    testWidgets('debe mostrar sección de SENSORES siempre', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(),
          ),
        ),
      );

      expect(find.text('SENSORES'), findsOneWidget);
      expect(find.text('Latitud'), findsOneWidget);
      expect(find.text('Longitud'), findsOneWidget);
      expect(find.text('Altitud'), findsOneWidget);
      expect(find.text('Rumbo'), findsOneWidget);
      expect(find.text('Inclinación'), findsOneWidget);
    });

    testWidgets('debe mostrar sección FILTROS solo cuando hay filtros activos', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(),
          ),
        ),
      );

      // Sin filtros activos
      expect(find.text('FILTROS'), findsNothing);

      // Activar filtros
      telemetry.updatePoiMetrics(
        visible: 25,
        total: 450,
        horizonCulled: 12,
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('FILTROS'), findsOneWidget);
      expect(find.text('Horizonte'), findsOneWidget);
    });

    testWidgets('debe mostrar filtro de importancia cuando está activo', (WidgetTester tester) async {
      telemetry.updatePoiMetrics(
        visible: 25,
        total: 450,
        importanceFiltered: 180,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('FILTROS'), findsOneWidget);
      expect(find.text('Detrás'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);
    });

    testWidgets('debe mostrar filtro de categoría cuando está activo', (WidgetTester tester) async {
      telemetry.updatePoiMetrics(
        visible: 25,
        total: 450,
        categoryFiltered: 350,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('FILTROS'), findsOneWidget);
      expect(find.text('Muy lejos'), findsOneWidget);
      expect(find.text('350'), findsOneWidget);
    });

    testWidgets('debe mostrar filtro de horizonte cuando está activo', (WidgetTester tester) async {
      telemetry.updatePoiMetrics(
        visible: 25,
        total: 450,
        horizonCulled: 45,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('FILTROS'), findsOneWidget);
      expect(find.text('Horizonte'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('debe mostrar todos los filtros cuando están activos', (WidgetTester tester) async {
      telemetry.updatePoiMetrics(
        visible: 25,
        total: 850,
        horizonCulled: 45,
        importanceFiltered: 180,
        categoryFiltered: 350,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('FILTROS'), findsOneWidget);
      expect(find.text('Detrás'), findsOneWidget);
      expect(find.text('Muy lejos'), findsOneWidget);
      expect(find.text('Horizonte'), findsOneWidget);
    });

    testWidgets('debe actualizar métricas cada 500ms', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(),
          ),
        ),
      );

      // Valores iniciales
      expect(find.text('—'), findsWidgets);

      // Actualizar métricas
      telemetry.recordFrameTime(16667); // 60 FPS
      telemetry.updatePoiMetrics(visible: 25, total: 450);

      // Avanzar 500ms
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que se actualizaron
      expect(find.text('60.0'), findsOneWidget);
      expect(find.text('25/450'), findsOneWidget);
    });

    testWidgets('debe cancelar timer al dispose', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(),
          ),
        ),
      );

      // Remover el widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // No debe haber errores
      expect(tester.takeException(), isNull);
    });

    testWidgets('debe mostrar calibración solo cuando es diferente de 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebugOverlay(),
          ),
        ),
      );

      // Sin calibración
      expect(find.text('Calibración'), findsNothing);

      // Con calibración
      telemetry.updateSensorData(calibrationOffset: -15.0);

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Calibración'), findsOneWidget);
      expect(find.text('-15.0°'), findsOneWidget);
    });

    group('Formateo de Valores', () {
      testWidgets('debe formatear FPS correctamente', (WidgetTester tester) async {
        telemetry.recordFrameTime(16667); // 60 FPS

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('60.0'), findsOneWidget);
      });

      testWidgets('debe formatear POIs correctamente', (WidgetTester tester) async {
        telemetry.updatePoiMetrics(visible: 25, total: 450);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('25/450'), findsOneWidget);
      });

      testWidgets('debe formatear cache hit rate como porcentaje', (WidgetTester tester) async {
        telemetry.recordCacheHit();
        telemetry.recordCacheHit();
        telemetry.recordCacheHit();
        telemetry.recordCacheMiss();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('75%'), findsOneWidget);
      });

      testWidgets('debe formatear tiempos en milisegundos', (WidgetTester tester) async {
        telemetry.recordProjectionTime(5.2);
        telemetry.recordDeclutterTime(3.1);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('5.2ms'), findsOneWidget);
        expect(find.text('3.1ms'), findsOneWidget);
      });

      testWidgets('debe formatear coordenadas con 6 decimales', (WidgetTester tester) async {
        telemetry.updateSensorData(
          lat: 28.123456,
          lon: -16.543210,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('28.123456°'), findsOneWidget);
        expect(find.text('-16.543210°'), findsOneWidget);
      });

      testWidgets('debe formatear altitud sin decimales', (WidgetTester tester) async {
        telemetry.updateSensorData(alt: 850.7);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('851m'), findsOneWidget);
      });

      testWidgets('debe formatear ángulos con 1 decimal', (WidgetTester tester) async {
        telemetry.updateSensorData(
          heading: 245.3,
          pitch: -10.5,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('245.3°'), findsOneWidget);
        expect(find.text('-10.5°'), findsOneWidget);
      });

      testWidgets('debe formatear calibración con signo', (WidgetTester tester) async {
        // Calibración negativa
        telemetry.updateSensorData(calibrationOffset: -15.0);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('-15.0°'), findsOneWidget);

        // Calibración positiva
        telemetry.reset();
        telemetry.updateSensorData(calibrationOffset: 15.0);

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('+15.0°'), findsOneWidget);
      });

      testWidgets('debe mostrar — para valores null o 0', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        // Todos los valores deberían ser —
        expect(find.text('—'), findsWidgets);
      });
    });

    group('Sistema de Colores', () {
      testWidgets('debe usar color verde para FPS óptimo (>55)', (WidgetTester tester) async {
        telemetry.recordFrameTime(16667); // 60 FPS

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        // Verificar que hay un texto con color verde
        final textWidgets = tester.widgetList<Text>(find.text('60.0'));
        expect(textWidgets.isNotEmpty, isTrue);
        final textWidget = textWidgets.first;
        expect(textWidget.style?.color, equals(Colors.green));
      });

      testWidgets('debe usar color amarillo para FPS aceptable (30-55)', (WidgetTester tester) async {
        telemetry.recordFrameTime(33333); // 30 FPS

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        final textWidgets = tester.widgetList<Text>(find.text('30.0'));
        expect(textWidgets.isNotEmpty, isTrue);
        final textWidget = textWidgets.first;
        expect(textWidget.style?.color, equals(Colors.yellow));
      });

      testWidgets('debe usar color rojo para FPS bajo (<30)', (WidgetTester tester) async {
        telemetry.recordFrameTime(50000); // 20 FPS

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        final textWidgets = tester.widgetList<Text>(find.text('20.0'));
        expect(textWidgets.isNotEmpty, isTrue);
        final textWidget = textWidgets.first;
        expect(textWidget.style?.color, equals(Colors.red));
      });

      testWidgets('debe usar color verde para cache óptimo (>80%)', (WidgetTester tester) async {
        for (int i = 0; i < 9; i++) {
          telemetry.recordCacheHit();
        }
        telemetry.recordCacheMiss();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        final textWidgets = tester.widgetList<Text>(find.text('90%'));
        expect(textWidgets.isNotEmpty, isTrue);
        final textWidget = textWidgets.first;
        expect(textWidget.style?.color, equals(Colors.green));
      });

      testWidgets('debe usar color cyan para cache medio (50-80%)', (WidgetTester tester) async {
        telemetry.recordCacheHit();
        telemetry.recordCacheHit();
        telemetry.recordCacheMiss();
        telemetry.recordCacheMiss();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        final textWidgets = tester.widgetList<Text>(find.text('50%'));
        expect(textWidgets.isNotEmpty, isTrue);
        final textWidget = textWidgets.first;
        expect(textWidget.style?.color, equals(Colors.cyan));
      });

      testWidgets('debe usar color naranja para cache bajo (<50%)', (WidgetTester tester) async {
        telemetry.recordCacheHit();
        telemetry.recordCacheMiss();
        telemetry.recordCacheMiss();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        final textWidgets = tester.widgetList<Text>(find.text('33%'));
        expect(textWidgets.isNotEmpty, isTrue);
        final textWidget = textWidgets.first;
        expect(textWidget.style?.color, equals(Colors.orange));
      });

      testWidgets('debe usar color verde para tiempos óptimos (<5ms)', (WidgetTester tester) async {
        telemetry.recordProjectionTime(3.2);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        final textWidgets = tester.widgetList<Text>(find.text('3.2ms'));
        expect(textWidgets.isNotEmpty, isTrue);
        final textWidget = textWidgets.first;
        expect(textWidget.style?.color, equals(Colors.green));
      });

      testWidgets('debe usar color amarillo para tiempos aceptables (5-16ms)', (WidgetTester tester) async {
        telemetry.recordDeclutterTime(10.0);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        final textWidgets = tester.widgetList<Text>(find.text('10.0ms'));
        expect(textWidgets.isNotEmpty, isTrue);
        final textWidget = textWidgets.first;
        expect(textWidget.style?.color, equals(Colors.yellow));
      });

      testWidgets('debe usar color rojo para tiempos altos (>16ms)', (WidgetTester tester) async {
        telemetry.recordProjectionTime(20.0);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        final textWidgets = tester.widgetList<Text>(find.text('20.0ms'));
        expect(textWidgets.isNotEmpty, isTrue);
        final textWidget = textWidgets.first;
        expect(textWidget.style?.color, equals(Colors.red));
      });
    });

    group('Estilo y Apariencia', () {
      testWidgets('debe tener fondo semi-transparente negro', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(DebugOverlay),
                matching: find.byType(Container),
              )
              .first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.black.withValues(alpha: 0.7)));
      });

      testWidgets('debe tener bordes redondeados', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(DebugOverlay),
                matching: find.byType(Container),
              )
              .first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(8)));
      });

      testWidgets('debe tener ancho máximo de 220', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugOverlay(),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(DebugOverlay),
                matching: find.byType(Container),
              )
              .first,
        );

        expect(container.constraints?.maxWidth, equals(220));
      });
    });
  });
}
