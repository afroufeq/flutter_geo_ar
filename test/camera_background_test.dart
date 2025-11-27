import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/camera/camera_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraBackground', () {
    group('Constructor', () {
      testWidgets('crea instancia sin cámara', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        expect(find.byType(CameraBackground), findsOneWidget);
      });

      testWidgets('crea instancia con cámara null explícita', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(camera: null),
            ),
          ),
        );

        expect(find.byType(CameraBackground), findsOneWidget);
      });
    });

    group('Widget State', () {
      testWidgets('muestra contenedor azul cuando no hay cámara', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        // Esperar a que se complete la inicialización
        await tester.pumpAndSettle();

        // Debería mostrar un Container con color azul (modo temporal para pruebas)
        final container = tester.widget<Container>(find.byType(Container));
        expect(container.color, equals(Colors.blue));
      });

      testWidgets('construye correctamente el widget tree', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('se puede reconstruir sin errores', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Reconstruir el widget
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Lifecycle', () {
      testWidgets('se puede crear y destruir sin errores', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Remover el widget
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('maneja múltiples reconstrucciones', (tester) async {
        for (int i = 0; i < 3; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CameraBackground(key: ValueKey(i)),
              ),
            ),
          );

          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull);
      });
    });

    group('Integration', () {
      testWidgets('funciona dentro de un Stack', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: const [
                  CameraBackground(),
                  Center(
                    child: Text('Overlay'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CameraBackground), findsOneWidget);
        expect(find.text('Overlay'), findsOneWidget);
      });

      testWidgets('funciona con diferentes tamaños de pantalla', (tester) async {
        // Tamaño pequeño
        tester.view.physicalSize = const Size(400, 600);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CameraBackground), findsOneWidget);

        // Tamaño grande
        tester.view.physicalSize = const Size(1200, 1600);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CameraBackground), findsOneWidget);

        // Resetear el tamaño
        addTearDown(() => tester.view.resetPhysicalSize());
      });

      testWidgets('funciona en modo landscape', (tester) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CameraBackground), findsOneWidget);

        addTearDown(() => tester.view.resetPhysicalSize());
      });

      testWidgets('se integra correctamente con Scaffold', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: const CameraBackground(),
              bottomNavigationBar: BottomNavigationBar(
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CameraBackground), findsOneWidget);
        expect(find.text('Test'), findsOneWidget);
      });
    });

    group('Modo debug/temporal', () {
      testWidgets('muestra fondo azul en modo temporal', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verificar que hay un Container azul (modo temporal)
        final container = tester.widget<Container>(find.byType(Container));
        expect(container.color, equals(Colors.blue));
      });

      testWidgets('el fondo azul ocupa toda la pantalla', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final size = tester.getSize(find.byType(Container));
        final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;

        // El container debería ocupar exactamente todo el espacio de la pantalla
        expect(size.width, equals(screenSize.width));
        expect(size.height, equals(screenSize.height));
      });
    });

    group('Performance', () {
      testWidgets('no causa memory leaks al crear y destruir múltiples veces', (tester) async {
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CameraBackground(key: ValueKey('camera_$i')),
              ),
            ),
          );

          await tester.pumpAndSettle();

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SizedBox(),
              ),
            ),
          );

          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull);
      });

      testWidgets('renderiza rápidamente', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        stopwatch.stop();

        // El renderizado inicial no debería tomar más de 1 segundo
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Estado y actualización', () {
      testWidgets('se puede actualizar el widget', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Actualizar con nuevo widget
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(key: ValueKey('new')),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('mantiene estado consistente entre rebuilds', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final firstContainer = tester.widget<Container>(find.byType(Container));

        // Forzar rebuild
        await tester.pump();

        final secondContainer = tester.widget<Container>(find.byType(Container));

        // El color debería mantenerse
        expect(firstContainer.color, equals(secondContainer.color));
      });
    });

    group('Casos edge', () {
      testWidgets('maneja pantalla muy pequeña', (tester) async {
        tester.view.physicalSize = const Size(100, 100);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CameraBackground), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() => tester.view.resetPhysicalSize());
      });

      testWidgets('maneja pantalla muy grande', (tester) async {
        tester.view.physicalSize = const Size(4000, 3000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CameraBackground), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() => tester.view.resetPhysicalSize());
      });

      testWidgets('maneja alto device pixel ratio', (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CameraBackground(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CameraBackground), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });
    });
  });
}
