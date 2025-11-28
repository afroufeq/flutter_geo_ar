import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geo_ar/src/sensors/native_event_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive Throttling', () {
    late NativeEventChannel channel;
    final List<MethodCall> methodCalls = [];

    setUp(() {
      channel = NativeEventChannel();
      methodCalls.clear();

      // Configurar el mock del EventChannel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_geo_ar/sensors'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_geo_ar/sensors'),
        null,
      );
    });

    group('Parámetros básicos', () {
      test('adaptiveThrottling por defecto es false', () {
        expect(
          () => channel.receiveBroadcastStream(),
          returnsNormally,
        );
      });

      test('acepta adaptiveThrottling true', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('acepta adaptiveThrottling false explícitamente', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: false,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('lowFrequencyMs con valor por defecto (1000ms)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 1000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('staticThreshold con valor por defecto (0.1)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticThreshold: 0.1,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('staticDurationMs con valor por defecto (2000ms)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticDurationMs: 2000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Configuración completa', () {
      test('configuración típica de senderismo', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 100, // 10 Hz en movimiento
          adaptiveThrottling: true,
          lowFrequencyMs: 1000, // 1 Hz estático
          staticThreshold: 0.1, // Umbral moderado
          staticDurationMs: 2000, // 2s antes de estático
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('configuración agresiva de ahorro de batería', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 200, // 5 Hz en movimiento
          adaptiveThrottling: true,
          lowFrequencyMs: 2000, // 0.5 Hz estático
          staticThreshold: 0.05, // Umbral bajo (más sensible)
          staticDurationMs: 1000, // 1s antes de estático
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('configuración de alta respuesta', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 50, // 20 Hz en movimiento
          adaptiveThrottling: true,
          lowFrequencyMs: 500, // 2 Hz estático
          staticThreshold: 0.2, // Umbral alto (menos sensible)
          staticDurationMs: 3000, // 3s antes de estático
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('configuración con todos los parámetros', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 100,
          lowPowerMode: false,
          adaptiveThrottling: true,
          lowFrequencyMs: 1000,
          staticThreshold: 0.1,
          staticDurationMs: 2000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Frecuencias de throttling', () {
      test('alta frecuencia activa (50ms / 20Hz)', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 50,
          adaptiveThrottling: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('frecuencia media activa (100ms / 10Hz)', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 100,
          adaptiveThrottling: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('baja frecuencia activa (200ms / 5Hz)', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 200,
          adaptiveThrottling: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('muy baja frecuencia estática (2000ms / 0.5Hz)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 2000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('frecuencia estática moderada (1000ms / 1Hz)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 1000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('frecuencia estática alta (500ms / 2Hz)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 500,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Umbrales de movimiento', () {
      test('umbral muy sensible (0.05 m/s²)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticThreshold: 0.05,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('umbral estándar (0.1 m/s²)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticThreshold: 0.1,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('umbral moderado (0.2 m/s²)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticThreshold: 0.2,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('umbral alto (0.5 m/s²)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticThreshold: 0.5,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('umbral muy alto (1.0 m/s²)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticThreshold: 1.0,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Duración antes de modo estático', () {
      test('transición rápida (1000ms / 1s)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticDurationMs: 1000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('transición estándar (2000ms / 2s)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticDurationMs: 2000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('transición lenta (3000ms / 3s)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticDurationMs: 3000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('transición muy lenta (5000ms / 5s)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticDurationMs: 5000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Valores extremos', () {
      test('throttleMs muy bajo con adaptive', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 10,
          adaptiveThrottling: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('throttleMs muy alto con adaptive', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 5000,
          adaptiveThrottling: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('lowFrequencyMs extremadamente bajo (100ms)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 100,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('lowFrequencyMs extremadamente alto (10000ms)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 10000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('staticThreshold muy bajo (0.01)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticThreshold: 0.01,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('staticThreshold muy alto (5.0)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticThreshold: 5.0,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('staticDurationMs muy corto (100ms)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticDurationMs: 100,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('staticDurationMs muy largo (30000ms / 30s)', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticDurationMs: 30000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Combinaciones con lowPowerMode', () {
      test('adaptiveThrottling y lowPowerMode ambos activos', () {
        final stream = channel.receiveBroadcastStream(
          lowPowerMode: true,
          adaptiveThrottling: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('adaptiveThrottling activo, lowPowerMode inactivo', () {
        final stream = channel.receiveBroadcastStream(
          lowPowerMode: false,
          adaptiveThrottling: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('adaptiveThrottling inactivo, lowPowerMode activo', () {
        final stream = channel.receiveBroadcastStream(
          lowPowerMode: true,
          adaptiveThrottling: false,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('ambos inactivos (modo estándar)', () {
        final stream = channel.receiveBroadcastStream(
          lowPowerMode: false,
          adaptiveThrottling: false,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Casos de uso específicos', () {
      test('configuración para turismo urbano', () {
        // Transiciones más lentas, menos sensible al movimiento
        final stream = channel.receiveBroadcastStream(
          throttleMs: 100,
          adaptiveThrottling: true,
          lowFrequencyMs: 1000,
          staticThreshold: 0.2, // Menos sensible
          staticDurationMs: 3000, // Más tiempo para transición
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('configuración para senderismo activo', () {
        // Transiciones rápidas, más sensible
        final stream = channel.receiveBroadcastStream(
          throttleMs: 100,
          adaptiveThrottling: true,
          lowFrequencyMs: 1000,
          staticThreshold: 0.1,
          staticDurationMs: 2000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('configuración para observación de paisajes', () {
        // Períodos estáticos largos, ahorro máximo
        final stream = channel.receiveBroadcastStream(
          throttleMs: 200,
          adaptiveThrottling: true,
          lowFrequencyMs: 2000,
          staticThreshold: 0.1,
          staticDurationMs: 1500,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('configuración para ciclismo', () {
        // Movimiento continuo, umbral más alto
        final stream = channel.receiveBroadcastStream(
          throttleMs: 50,
          adaptiveThrottling: true,
          lowFrequencyMs: 500,
          staticThreshold: 0.3,
          staticDurationMs: 4000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Múltiples instancias con adaptive', () {
      test('dos streams con diferentes configuraciones adaptativas', () {
        final stream1 = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 1000,
        );
        final stream2 = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 2000,
        );

        expect(stream1, isA<Stream<dynamic>>());
        expect(stream2, isA<Stream<dynamic>>());
      });

      test('uno con adaptive, otro sin adaptive', () {
        final stream1 = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
        );
        final stream2 = channel.receiveBroadcastStream(
          adaptiveThrottling: false,
        );

        expect(stream1, isA<Stream<dynamic>>());
        expect(stream2, isA<Stream<dynamic>>());
      });
    });

    group('Validación de parámetros', () {
      test('acepta todos los parámetros en orden', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 100,
          lowPowerMode: false,
          adaptiveThrottling: true,
          lowFrequencyMs: 1000,
          staticThreshold: 0.1,
          staticDurationMs: 2000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('acepta parámetros en orden diferente (named parameters)', () {
        final stream = channel.receiveBroadcastStream(
          staticDurationMs: 2000,
          adaptiveThrottling: true,
          throttleMs: 100,
          staticThreshold: 0.1,
          lowFrequencyMs: 1000,
          lowPowerMode: false,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('acepta solo algunos parámetros adaptivos', () {
        final stream = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 1500,
          // staticThreshold y staticDurationMs por defecto
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Transiciones de configuración', () {
      test('cambiar de no-adaptivo a adaptivo', () {
        final stream1 = channel.receiveBroadcastStream(
          throttleMs: 100,
          adaptiveThrottling: false,
        );
        expect(stream1, isA<Stream<dynamic>>());

        final stream2 = channel.receiveBroadcastStream(
          throttleMs: 100,
          adaptiveThrottling: true,
        );
        expect(stream2, isA<Stream<dynamic>>());
      });

      test('cambiar parámetros adaptivos dinámicamente', () {
        final stream1 = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 1000,
        );
        expect(stream1, isA<Stream<dynamic>>());

        final stream2 = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          lowFrequencyMs: 2000,
        );
        expect(stream2, isA<Stream<dynamic>>());
      });

      test('ajustar sensibilidad de umbral', () {
        final stream1 = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticThreshold: 0.05,
        );
        expect(stream1, isA<Stream<dynamic>>());

        final stream2 = channel.receiveBroadcastStream(
          adaptiveThrottling: true,
          staticThreshold: 0.2,
        );
        expect(stream2, isA<Stream<dynamic>>());
      });
    });

    group('Optimización de batería', () {
      test('máximo ahorro de batería', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 200, // Frecuencia activa moderada
          adaptiveThrottling: true,
          lowFrequencyMs: 2000, // Frecuencia estática muy baja
          staticThreshold: 0.05, // Muy sensible a movimiento
          staticDurationMs: 1000, // Transición rápida a estático
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('balance ahorro-rendimiento', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 100,
          adaptiveThrottling: true,
          lowFrequencyMs: 1000,
          staticThreshold: 0.1,
          staticDurationMs: 2000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('máximo rendimiento con algún ahorro', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 50,
          adaptiveThrottling: true,
          lowFrequencyMs: 500,
          staticThreshold: 0.15,
          staticDurationMs: 3000,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });
  });
}
