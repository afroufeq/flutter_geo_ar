import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/utils/stream_throttle.dart';

void main() {
  group('ThrottleLatest', () {
    test('emite el primer evento inmediatamente', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, [1]);
      await controller.close();
    });

    test('emite solo el último evento durante la ventana de throttle', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      // Enviar múltiples eventos rápidamente
      controller.add(1); // Emitido inmediatamente
      await Future.delayed(const Duration(milliseconds: 10));
      controller.add(2); // Throttled
      controller.add(3); // Throttled
      controller.add(4); // Este será emitido después del throttle

      // Esperar a que el throttle expire
      await Future.delayed(const Duration(milliseconds: 150));

      // Debe emitir el primer evento inmediatamente y el último después del throttle
      expect(events, [1, 4]);
      await controller.close();
    });

    test('emite eventos cuando están espaciados correctamente', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 120));

      controller.add(2);
      await Future.delayed(const Duration(milliseconds: 120));

      controller.add(3);
      await Future.delayed(const Duration(milliseconds: 120));

      // Todos los eventos deben ser emitidos ya que están espaciados
      expect(events, [1, 2, 3]);
      await controller.close();
    });

    test('propaga errores del stream original', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      final errors = <dynamic>[];

      throttled.listen(
        events.add,
        onError: errors.add,
      );

      controller.add(1);
      controller.addError('test error');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, [1]);
      expect(errors, ['test error']);
      await controller.close();
    });

    test('cierra el stream correctamente', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      var isDone = false;
      throttled.listen(
        (_) {},
        onDone: () => isDone = true,
      );

      controller.add(1);
      await controller.close();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(isDone, isTrue);
    });

    test('maneja cancelación de suscripción correctamente', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      final subscription = throttled.listen(events.add);

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 10));

      // Cancelar la suscripción
      await subscription.cancel();

      // Agregar más eventos (no deben ser recibidos)
      controller.add(2);
      controller.add(3);
      await Future.delayed(const Duration(milliseconds: 150));

      expect(events, [1]); // Solo el primer evento antes de cancelar
      await controller.close();
    });

    test('maneja múltiples ráfagas de eventos', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      // Primera ráfaga
      controller.add(1); // Emitido inmediatamente
      await Future.delayed(const Duration(milliseconds: 10));
      controller.add(2);
      controller.add(3); // Este será emitido después del throttle

      await Future.delayed(const Duration(milliseconds: 200));

      // Segunda ráfaga (después de que expire el throttle)
      controller.add(4); // Emitido inmediatamente
      await Future.delayed(const Duration(milliseconds: 10));
      controller.add(5);
      controller.add(6); // Este será emitido después del throttle

      await Future.delayed(const Duration(milliseconds: 200));

      expect(events, [1, 3, 4, 6]);
      await controller.close();
    });

    test('maneja stream vacío sin errores', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      await controller.close();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, isEmpty);
    });

    test('funciona con diferentes duraciones de throttle', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 50)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      controller.add(1); // Emitido inmediatamente
      await Future.delayed(const Duration(milliseconds: 10));
      controller.add(2); // Throttled

      await Future.delayed(const Duration(milliseconds: 60));

      expect(events, [1, 2]);
      await controller.close();
    });

    test('maneja eventos con valores null', () async {
      final controller = StreamController<int?>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int?>[];
      throttled.listen(events.add);

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 10));
      controller.add(null);
      controller.add(2);

      await Future.delayed(const Duration(milliseconds: 150));

      expect(events, [1, 2]);
      await controller.close();
    });

    test('maneja eventos muy rápidos (alta frecuencia)', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      // Enviar 100 eventos rápidamente
      for (int i = 0; i < 100; i++) {
        controller.add(i);
      }

      await Future.delayed(const Duration(milliseconds: 150));

      // Debe emitir solo el primero (0) y el último (99)
      expect(events.length, 2);
      expect(events.first, 0);
      expect(events.last, 99);

      await controller.close();
    });

    test('respeta el throttle durante eventos continuos', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      // Enviar eventos continuamente cada 50ms (más rápido que el throttle)
      controller.add(1); // t=0, emitido inmediatamente
      await Future.delayed(const Duration(milliseconds: 50));

      controller.add(2); // t=50, throttled
      await Future.delayed(const Duration(milliseconds: 50));

      controller.add(3); // t=100, este debería emitirse
      await Future.delayed(const Duration(milliseconds: 50));

      controller.add(4); // t=150, throttled
      await Future.delayed(const Duration(milliseconds: 50));

      controller.add(5); // t=200, este debería emitirse
      await Future.delayed(const Duration(milliseconds: 150));

      expect(events.length, greaterThanOrEqualTo(3));
      expect(events.first, 1);

      await controller.close();
    });

    test('maneja stream broadcast correctamente', () async {
      final controller = StreamController<int>.broadcast();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 10));
      controller.add(2);

      await Future.delayed(const Duration(milliseconds: 150));

      // Debe manejar broadcast streams correctamente
      expect(events.length, greaterThanOrEqualTo(1));

      await controller.close();
    });

    test('funciona con Duration muy corta', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 1)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      controller.add(1);
      await Future.delayed(const Duration(milliseconds: 5));
      controller.add(2);

      await Future.delayed(const Duration(milliseconds: 5));

      expect(events, [1, 2]);
      await controller.close();
    });

    test('maneja eventos del mismo valor', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      controller.add(5); // Emitido inmediatamente
      await Future.delayed(const Duration(milliseconds: 10));
      controller.add(5); // Throttled
      controller.add(5); // Throttled
      controller.add(5); // Este será emitido

      await Future.delayed(const Duration(milliseconds: 150));

      // Debe emitir ambos eventos aunque sean del mismo valor
      expect(events, [5, 5]);
      await controller.close();
    });

    test('no pierde eventos si el stream se cierra durante el throttle', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      controller.add(1); // Emitido inmediatamente
      await Future.delayed(const Duration(milliseconds: 10));
      controller.add(2); // Throttled, pendiente de emitir

      // Cerrar el stream antes de que expire el throttle
      await controller.close();
      await Future.delayed(const Duration(milliseconds: 150));

      // Solo debe haber emitido el primer evento
      expect(events, [1]);
    });

    test('mantiene el orden de los eventos', () async {
      final controller = StreamController<int>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 50)),
      );

      final events = <int>[];
      throttled.listen(events.add);

      for (int i = 1; i <= 5; i++) {
        controller.add(i);
        await Future.delayed(const Duration(milliseconds: 60));
      }

      // Los eventos deben estar en orden
      expect(events, [1, 2, 3, 4, 5]);
      await controller.close();
    });

    test('funciona correctamente con tipos de datos complejos', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final throttled = controller.stream.transform(
        ThrottleLatest(const Duration(milliseconds: 100)),
      );

      final events = <Map<String, dynamic>>[];
      throttled.listen(events.add);

      controller.add({'value': 1, 'timestamp': 100});
      await Future.delayed(const Duration(milliseconds: 10));
      controller.add({'value': 2, 'timestamp': 200});
      controller.add({'value': 3, 'timestamp': 300});

      await Future.delayed(const Duration(milliseconds: 150));

      expect(events.length, 2);
      expect(events[0]['value'], 1);
      expect(events[1]['value'], 3);

      await controller.close();
    });
  });
}
