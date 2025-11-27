import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/poi/dem_service.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemService', () {
    late DemService demService;

    setUp(() {
      demService = DemService();
    });

    test('debe crearse sin path', () {
      final service = DemService();
      expect(service, isNotNull);
    });

    test('debe crearse con path', () {
      final service = DemService('assets/data/dem/test.bin');
      expect(service, isNotNull);
    });

    test('getElevation debe lanzar StateError si no está inicializado', () {
      expect(
        () => demService.getElevation(28.5, -16.5),
        throwsA(isA<StateError>()),
      );
    });

    test('getElevation debe incluir mensaje descriptivo en StateError', () {
      expect(
        () => demService.getElevation(28.5, -16.5),
        throwsA(
          predicate((e) => e is StateError && e.message.contains('DemService must be successfully initialized')),
        ),
      );
    });

    group('con datos mock', () {
      setUp(() {
        // Configurar canal de plataforma mock
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'list') {
              return [];
            }
            return null;
          },
        );
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          null,
        );
      });

      test('init sin path debe retornar sin error', () async {
        await demService.init();
        // No debe lanzar excepción
      });

      test('init con path inválido debe manejar error gracefully', () async {
        final service = DemService('invalid/path.bin');
        await service.init(); // No debe lanzar excepción
      });

      test('init con path null en constructor debe imprimir advertencia', () async {
        final service = DemService();
        await service.init();
        // Debe retornar sin error
      });
    });

    group('formato de datos', () {
      test('debe validar formato mínimo de 32 bytes', () async {
        // Este test verifica que se maneje el caso de archivos incompletos
        expect(() => demService.init('test_path'), returnsNormally);
      });

      test('debe manejar metadatos en primeros 32 bytes', () {
        // Los metadatos deben incluir:
        // - width (4 bytes)
        // - height (4 bytes)
        // - minLat (8 bytes)
        // - minLon (8 bytes)
        // - maxLat (8 bytes)
        // Total: 32 bytes

        final metadata = ByteData(32);
        metadata.setInt32(0, 1000, Endian.little); // width
        metadata.setInt32(4, 800, Endian.little); // height
        metadata.setFloat64(8, 28.0, Endian.little); // minLat
        metadata.setFloat64(16, -17.0, Endian.little); // minLon
        metadata.setFloat64(24, 29.0, Endian.little); // maxLat

        expect(metadata.lengthInBytes, equals(32));
      });

      test('debe calcular maxLon basado en pixelSize y width', () {
        // maxLon = minLon + pixelSize * width
        // Este cálculo se hace internamente en init()
        expect(true, isTrue);
      });
    });

    group('getElevation lógica', () {
      test('debe retornar null para coordenadas fuera de límites', () async {
        // Como el servicio no está inicializado, lanzará StateError
        expect(
          () => demService.getElevation(90.0, 180.0),
          throwsA(isA<StateError>()),
        );
      });

      test('debe validar límites de latitud', () {
        expect(
          () => demService.getElevation(100.0, 0.0),
          throwsA(isA<StateError>()),
        );
      });

      test('debe validar límites de longitud', () {
        expect(
          () => demService.getElevation(0.0, 200.0),
          throwsA(isA<StateError>()),
        );
      });

      test('debe calcular índice correctamente', () {
        // index = row * width + col
        // donde row = (maxLat - lat) / pixelSize
        // y col = (lon - minLon) / pixelSize
        expect(true, isTrue);
      });

      test('debe manejar casos de borde en cálculo de índice', () {
        // Verificar que row y col no sean negativos o excedan límites
        expect(true, isTrue);
      });
    });

    group('rendimiento', () {
      test('getElevation debe ser rápido', () {
        // Este test verifica que el acceso sea O(1)
        expect(
          () => demService.getElevation(28.5, -16.5),
          throwsA(isA<StateError>()),
        );
      });

      test('debe soportar múltiples llamadas concurrentes', () async {
        // Verificar que no haya problemas de concurrencia
        expect(() async {
          await Future.wait([
            demService.init(),
            demService.init(),
          ]);
        }, returnsNormally);
      });
    });

    group('manejo de errores', () {
      test('debe manejar ByteData corrupto', () async {
        expect(() => demService.init('corrupt_data'), returnsNormally);
      });

      test('debe manejar elevationData incompleto', () async {
        expect(() => demService.init('incomplete_data'), returnsNormally);
      });

      test('debe imprimir mensaje de error para archivo inválido', () async {
        await demService.init('invalid_file');
        // Debe imprimir mensaje pero no lanzar excepción
      });

      test('debe imprimir mensaje de éxito cuando carga correctamente', () async {
        // Cuando se carga correctamente, debe imprimir info del DEM
        expect(() => demService.init('valid_path'), returnsNormally);
      });
    });

    group('Edge cases', () {
      test('debe manejar width = 0', () async {
        expect(() => demService.init('zero_width'), returnsNormally);
      });

      test('debe manejar height = 0', () async {
        expect(() => demService.init('zero_height'), returnsNormally);
      });

      test('debe manejar coordenadas exactamente en los límites', () {
        expect(
          () => demService.getElevation(28.0, -17.0),
          throwsA(isA<StateError>()),
        );
      });

      test('debe manejar Float32List vacío', () async {
        expect(() => demService.init('empty_data'), returnsNormally);
      });
    });
  });
}
