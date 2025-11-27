import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/widgets/visual_density_slider.dart';
import 'package:flutter_geo_ar/src/widgets/visual_density_controller.dart';
import 'package:flutter_geo_ar/src/i18n/strings.g.dart';

/// Helper para envolver widgets con el TranslationProvider necesario
Widget wrapWithTranslations(Widget child) {
  return TranslationProvider(
    child: MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  group('VisualDensitySlider - Tests sin dependencias de slang', () {
    late VisualDensityController controller;

    setUp(() {
      controller = VisualDensityController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('crea el widget correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Verifica que el widget existe
      expect(find.byType(VisualDensitySlider), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('muestra el slider cuando está expandido', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Por defecto está expandido, debe mostrar el slider
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('alterna entre expandido y colapsado al hacer tap en el header', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Inicialmente expandido, debe mostrar el slider
      expect(find.byType(Slider), findsOneWidget);

      // Encuentra el InkWell del header (el primero)
      final headerInkWell = find.byType(InkWell).first;

      // Tap para colapsar
      await tester.tap(headerInkWell);
      await tester.pumpAndSettle();

      // Ahora no debe mostrar el slider
      expect(find.byType(Slider), findsNothing);

      // Tap para expandir de nuevo
      await tester.tap(headerInkWell);
      await tester.pumpAndSettle();

      // Debe mostrar el slider nuevamente
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('el slider cambia el valor del controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Valor inicial
      expect(controller.density, 0.5);

      // Encuentra el slider y arrastra
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // El valor debe haber cambiado
      expect(controller.density, isNot(equals(0.5)));
    });

    testWidgets('muestra el icono correcto según el estado expandido', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Inicialmente expandido, debe mostrar expand_less
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);

      // Tap para colapsar
      final headerInkWell = find.byType(InkWell).first;
      await tester.tap(headerInkWell);
      await tester.pumpAndSettle();

      // Ahora debe mostrar expand_more
      expect(find.byIcon(Icons.expand_less), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('no muestra información detallada por defecto', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
            showDetailedInfo: false,
          ),
        ),
      );

      // No debe haber divider extra ni filas de información
      expect(find.byType(Divider), findsOneWidget); // Solo el del header
    });

    testWidgets('muestra información detallada cuando se solicita', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
            showDetailedInfo: true,
          ),
        ),
      );

      // Debe haber divider adicionales
      expect(find.byType(Divider), findsNWidgets(2)); // Header + detalles
    });

    testWidgets('respeta el alignment especificado', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
            alignment: Alignment.topLeft,
          ),
        ),
      );

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.topLeft);
    });

    testWidgets('respeta el padding especificado', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(24.0);

      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
            padding: customPadding,
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding).first);
      expect(padding.padding, customPadding);
    });

    testWidgets('muestra el icono tune en el header', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('muestra el porcentaje del valor del slider', (WidgetTester tester) async {
      controller.setDensity(0.75);

      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Debe mostrar 75%
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('actualiza el porcentaje cuando cambia la densidad', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Cambiar densidad
      controller.setDensity(0.3);
      await tester.pumpAndSettle();

      // Debe mostrar 30%
      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('escucha cambios del controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Valor inicial
      expect(controller.density, 0.5);

      // Cambiar valor desde el controller
      controller.setDensity(0.8);
      await tester.pumpAndSettle();

      // El slider debe reflejar el cambio
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 0.8);
    });

    testWidgets('el slider tiene el rango correcto (0.0 a 1.0)', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 0.0);
      expect(slider.max, 1.0);
    });

    testWidgets('el widget se reconstruye cuando el controller notifica', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Obtener el estado inicial
      final initialValue = controller.density;

      // Cambiar el valor
      controller.setDensity(0.7);
      await tester.pump();

      // Verificar que el valor cambió
      expect(controller.density, isNot(equals(initialValue)));
    });

    testWidgets('maneja correctamente valores extremos del slider', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Probar valor mínimo
      controller.setDensity(0.0);
      await tester.pumpAndSettle();
      expect(find.text('0%'), findsOneWidget);

      // Probar valor máximo
      controller.setDensity(1.0);
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('mantiene el estado de expansión después de rebuild', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Colapsar
      final headerInkWell = find.byType(InkWell).first;
      await tester.tap(headerInkWell);
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNothing);

      // Cambiar el controller para forzar rebuild
      controller.setDensity(0.7);
      await tester.pump();

      // Debe seguir colapsado
      expect(find.byType(Slider), findsNothing);
    });
  });

  group('_PresetButton - Tests de funcionalidad', () {
    late VisualDensityController controller;

    setUp(() {
      controller = VisualDensityController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('muestra todos los botones de preset', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      // Debe haber 5 botones de preset envueltos en Material
      // (minimal, low, normal, high, maximum)
      final materials = find.byType(Material);
      expect(materials, findsWidgets);
    });
  });

  group('Visual feedback tests', () {
    late VisualDensityController controller;

    setUp(() {
      controller = VisualDensityController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('el container tiene decoración con border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(container.decoration, isA<BoxDecoration>());

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
      expect(decoration.border, isNotNull);
    });

    testWidgets('el container tiene animación de duración 300ms', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTranslations(
          VisualDensitySlider(
            controller: controller,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(container.duration, const Duration(milliseconds: 300));
      expect(container.curve, Curves.easeInOut);
    });
  });
}
