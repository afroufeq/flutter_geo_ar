import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/widgets/sensor_accuracy_indicator.dart';
import 'package:flutter_geo_ar/src/sensors/fused_data.dart';
import 'package:flutter_geo_ar/src/sensors/sensor_accuracy.dart';
import 'package:flutter_geo_ar/src/i18n/strings.g.dart';

void main() {
  group('SensorAccuracyIndicator', () {
    testWidgets('muestra icono verde para precisión alta', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 3,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(sensorData: data),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.gps_fixed));
      expect(icon.color, Colors.green);
    });

    testWidgets('muestra icono naranja para precisión media', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 2,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(sensorData: data),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.gps_not_fixed), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.gps_not_fixed));
      expect(icon.color, Colors.orange);
    });

    testWidgets('muestra icono rojo para precisión baja', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 1,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(sensorData: data),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.gps_off), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.gps_off));
      expect(icon.color, Colors.red);
    });

    testWidgets('muestra icono de error para precisión no fiable', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 0,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(sensorData: data),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, Colors.red[900]);
    });

    testWidgets('muestra etiqueta cuando showLabel es true', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 3,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(
                sensorData: data,
                showLabel: true,
              ),
            ),
          ),
        ),
      );

      // Debe mostrar al menos un texto (la etiqueta)
      expect(find.byType(Text), findsAtLeast(1));
    });

    testWidgets('no muestra etiqueta cuando showLabel es false', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 3,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(
                sensorData: data,
                showLabel: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('muestra mensaje de calibración para precisión baja', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 1,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(
                sensorData: data,
                showLabel: true,
              ),
            ),
          ),
        ),
      );

      // Debe mostrar al menos dos textos (etiqueta + mensaje de calibración)
      expect(find.byType(Text), findsAtLeast(2));
    });

    testWidgets('es clickeable cuando onTap está definido', (tester) async {
      bool tapped = false;
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 1,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(
                sensorData: data,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('no es clickeable cuando onTap es null', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 3,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(
                sensorData: data,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('respeta el tamaño personalizado del icono', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 3,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(
                sensorData: data,
                size: 32.0,
              ),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 32.0);
    });

    testWidgets('maneja sensorData null mostrando estado unreliable', (tester) async {
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: SensorAccuracyIndicator(sensorData: null),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('CompactSensorAccuracyIndicator', () {
    testWidgets('muestra punto verde para precisión alta', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 3,
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: CompactSensorAccuracyIndicator(sensorData: data),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CompactSensorAccuracyIndicator),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.green);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('muestra punto naranja para precisión media', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSensorAccuracyIndicator(sensorData: data),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CompactSensorAccuracyIndicator),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.orange);
    });

    testWidgets('muestra punto rojo para precisión baja', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSensorAccuracyIndicator(sensorData: data),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CompactSensorAccuracyIndicator),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
    });

    testWidgets('muestra punto rojo oscuro para precisión no fiable', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSensorAccuracyIndicator(sensorData: data),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CompactSensorAccuracyIndicator),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red[900]);
    });

    testWidgets('es clickeable cuando onTap está definido', (tester) async {
      bool tapped = false;
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSensorAccuracyIndicator(
              sensorData: data,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('no es clickeable cuando onTap es null', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSensorAccuracyIndicator(sensorData: data),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('tiene tamaño correcto (12x12)', (tester) async {
      final data = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
        magnetometerAccuracy: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSensorAccuracyIndicator(sensorData: data),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CompactSensorAccuracyIndicator),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.constraints?.maxWidth, 12);
      expect(container.constraints?.maxHeight, 12);
    });

    testWidgets('maneja sensorData null mostrando estado unreliable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactSensorAccuracyIndicator(sensorData: null),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CompactSensorAccuracyIndicator),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red[900]);
    });
  });
}
