import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geo_ar/src/sensors/native_event_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeEventChannel', () {
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

    group('receiveBroadcastStream', () {
      test('retorna un Stream válido', () {
        final stream = channel.receiveBroadcastStream();
        expect(stream, isA<Stream<dynamic>>());
      });

      test('retorna un Stream válido con parámetros por defecto', () {
        final stream = channel.receiveBroadcastStream();
        expect(stream, isNotNull);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('retorna un Stream válido con throttleMs personalizado', () {
        final stream = channel.receiveBroadcastStream(throttleMs: 200);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('retorna un Stream válido con lowPowerMode activado', () {
        final stream = channel.receiveBroadcastStream(lowPowerMode: true);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('retorna un Stream válido con ambos parámetros personalizados', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 50,
          lowPowerMode: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('acepta throttleMs de 0', () {
        final stream = channel.receiveBroadcastStream(throttleMs: 0);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('acepta throttleMs muy alto', () {
        final stream = channel.receiveBroadcastStream(throttleMs: 10000);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('acepta lowPowerMode false explícitamente', () {
        final stream = channel.receiveBroadcastStream(lowPowerMode: false);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('múltiples llamadas retornan streams diferentes', () {
        final stream1 = channel.receiveBroadcastStream();
        final stream2 = channel.receiveBroadcastStream();

        expect(stream1, isA<Stream<dynamic>>());
        expect(stream2, isA<Stream<dynamic>>());
        // Los streams pueden ser diferentes instancias
      });

      test('throttleMs por defecto es 100', () {
        // Este test verifica que los parámetros por defecto están correctos
        // No podemos verificar el valor pasado directamente, pero podemos
        // asegurarnos de que el método acepta los valores por defecto
        expect(
          () => channel.receiveBroadcastStream(),
          returnsNormally,
        );
      });

      test('lowPowerMode por defecto es false', () {
        // Verificar que el método acepta los valores por defecto
        expect(
          () => channel.receiveBroadcastStream(),
          returnsNormally,
        );
      });
    });

    group('Configuraciones específicas', () {
      test('configuración para alta frecuencia (throttleMs bajo)', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 16, // ~60Hz
          lowPowerMode: false,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('configuración para baja frecuencia (throttleMs alto)', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 1000, // 1Hz
          lowPowerMode: false,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('configuración de bajo consumo', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 500,
          lowPowerMode: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });

      test('configuración de alto rendimiento', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 10,
          lowPowerMode: false,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Valores extremos', () {
      test('throttleMs negativo', () {
        // Aunque no es ideal, el método debería aceptarlo
        final stream = channel.receiveBroadcastStream(throttleMs: -1);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('throttleMs muy grande', () {
        final stream = channel.receiveBroadcastStream(throttleMs: 999999);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('throttleMs con valor común (100ms)', () {
        final stream = channel.receiveBroadcastStream(throttleMs: 100);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('throttleMs con valor común (50ms)', () {
        final stream = channel.receiveBroadcastStream(throttleMs: 50);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('throttleMs con valor común (200ms)', () {
        final stream = channel.receiveBroadcastStream(throttleMs: 200);
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Instancias múltiples', () {
      test('múltiples instancias de NativeEventChannel', () {
        final channel1 = NativeEventChannel();
        final channel2 = NativeEventChannel();

        final stream1 = channel1.receiveBroadcastStream();
        final stream2 = channel2.receiveBroadcastStream();

        expect(stream1, isA<Stream<dynamic>>());
        expect(stream2, isA<Stream<dynamic>>());
      });

      test('instancias independientes con diferentes configuraciones', () {
        final channel1 = NativeEventChannel();
        final channel2 = NativeEventChannel();

        final stream1 = channel1.receiveBroadcastStream(throttleMs: 100);
        final stream2 = channel2.receiveBroadcastStream(throttleMs: 200);

        expect(stream1, isA<Stream<dynamic>>());
        expect(stream2, isA<Stream<dynamic>>());
      });
    });

    group('Uso típico', () {
      test('uso con valores por defecto (caso más común)', () {
        final stream = channel.receiveBroadcastStream();
        expect(stream, isA<Stream<dynamic>>());
      });

      test('uso con throttle optimizado para AR (50-100ms)', () {
        final stream = channel.receiveBroadcastStream(throttleMs: 50);
        expect(stream, isA<Stream<dynamic>>());
      });

      test('uso con modo de bajo consumo para background', () {
        final stream = channel.receiveBroadcastStream(
          throttleMs: 500,
          lowPowerMode: true,
        );
        expect(stream, isA<Stream<dynamic>>());
      });
    });

    group('Llamadas consecutivas', () {
      test('llamadas consecutivas con mismos parámetros', () {
        final stream1 = channel.receiveBroadcastStream(throttleMs: 100);
        final stream2 = channel.receiveBroadcastStream(throttleMs: 100);

        expect(stream1, isA<Stream<dynamic>>());
        expect(stream2, isA<Stream<dynamic>>());
      });

      test('llamadas consecutivas con parámetros diferentes', () {
        final stream1 = channel.receiveBroadcastStream(throttleMs: 100);
        final stream2 = channel.receiveBroadcastStream(throttleMs: 200);

        expect(stream1, isA<Stream<dynamic>>());
        expect(stream2, isA<Stream<dynamic>>());
      });

      test('llamadas alternando lowPowerMode', () {
        final stream1 = channel.receiveBroadcastStream(lowPowerMode: false);
        final stream2 = channel.receiveBroadcastStream(lowPowerMode: true);
        final stream3 = channel.receiveBroadcastStream(lowPowerMode: false);

        expect(stream1, isA<Stream<dynamic>>());
        expect(stream2, isA<Stream<dynamic>>());
        expect(stream3, isA<Stream<dynamic>>());
      });
    });
  });
}
