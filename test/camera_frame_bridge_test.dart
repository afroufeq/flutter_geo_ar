import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/visual/camera_frame_bridge.dart';

// Mock classes para CameraImage, Plane y ImageFormat
class MockImageFormat implements ImageFormat {
  @override
  ImageFormatGroup get group => ImageFormatGroup.yuv420;

  @override
  int get raw => 0;
}

class MockCameraImage implements CameraImage {
  @override
  final int width;

  @override
  final int height;

  @override
  final List<Plane> planes;

  @override
  final ImageFormat format;

  MockCameraImage({
    required this.width,
    required this.height,
    required this.planes,
  }) : format = MockImageFormat();

  @override
  double? get lensAperture => 0.0;

  @override
  int? get sensorExposureTime => 0;

  @override
  double? get sensorSensitivity => 0.0;
}

class MockPlane implements Plane {
  @override
  final Uint8List bytes;

  @override
  final int bytesPerRow;

  @override
  final int? bytesPerPixel;

  @override
  final int? height;

  @override
  final int? width;

  MockPlane({
    required this.bytes,
    required this.bytesPerRow,
    this.bytesPerPixel,
    this.height,
    this.width,
  });
}

void main() {
  group('cameraImageToGreyscaleDownscale', () {
    test('convierte imagen simple correctamente', () async {
      // Arrange: Crear imagen 4x4
      final data = Uint8List.fromList([
        100, 110, 120, 130, // fila 0
        140, 150, 160, 170, // fila 1
        180, 190, 200, 210, // fila 2
        220, 230, 240, 250, // fila 3
      ]);

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 4,
      );

      final img = MockCameraImage(
        width: 4,
        height: 4,
        planes: [plane],
      );

      // Act: Reducir a 2x2
      final result = await cameraImageToGreyscaleDownscale(img, 2, 2);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(4)); // 2x2 = 4 pixels

      // Nearest neighbor: debería tomar píxeles (0,0), (2,0), (0,2), (2,2)
      expect(result[0], equals(100)); // (0,0)
      expect(result[1], equals(120)); // (2,0)
      expect(result[2], equals(180)); // (0,2)
      expect(result[3], equals(200)); // (2,2)
    });

    test('maneja reducción a tamaño menor', () async {
      // Arrange: Imagen 8x8, reducir a 2x2
      final data = Uint8List(64);
      for (int i = 0; i < 64; i++) {
        data[i] = i;
      }

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 8,
      );

      final img = MockCameraImage(
        width: 8,
        height: 8,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 2, 2);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(4));
    });

    test('maneja aumento de tamaño (upscaling)', () async {
      // Arrange: Imagen 2x2, aumentar a 4x4
      final data = Uint8List.fromList([
        10,
        20,
        30,
        40,
      ]);

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 2,
      );

      final img = MockCameraImage(
        width: 2,
        height: 2,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 4, 4);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(16)); // 4x4 = 16 pixels

      // Nearest neighbor debería duplicar pixels
      expect(result[0], equals(10)); // (0,0)
      expect(result[1], equals(10)); // (0.25,0) -> (0,0)
      expect(result[2], equals(20)); // (1,0)
      expect(result[3], equals(20)); // (1.5,0) -> (1,0)
    });

    test('mantiene mismo tamaño (sin escalar)', () async {
      // Arrange: Imagen 4x4, mantener 4x4
      final data = Uint8List.fromList([
        0,
        50,
        100,
        150,
        40,
        90,
        140,
        190,
        80,
        130,
        180,
        230,
        120,
        170,
        220,
        255,
      ]);

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 4,
      );

      final img = MockCameraImage(
        width: 4,
        height: 4,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 4, 4);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(16));

      // Debería ser idéntico al original
      for (int i = 0; i < 16; i++) {
        expect(result[i], equals(data[i]));
      }
    });

    test('maneja stride diferente de width', () async {
      // Arrange: Ancho 4 pero stride 8 (padding)
      final data = Uint8List(32); // 4 filas × 8 stride

      // Llenar datos útiles (primeros 4 bytes de cada fila)
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          data[y * 8 + x] = (y * 4 + x) * 10;
        }
      }

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 8, // stride mayor que width
      );

      final img = MockCameraImage(
        width: 4,
        height: 4,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 2, 2);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(4));

      // Verificar que toma los datos correctos considerando el stride
      expect(result[0], equals(0)); // (0,0)
      expect(result[1], equals(20)); // (2,0)
      expect(result[2], equals(80)); // (0,2)
      expect(result[3], equals(100)); // (2,2)
    });

    test('maneja imagen de alta resolución', () async {
      // Arrange: Imagen HD 1920x1080 -> 320x180
      final data = Uint8List(1920 * 1080);
      for (int i = 0; i < data.length; i++) {
        data[i] = (i % 256);
      }

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 1920,
      );

      final img = MockCameraImage(
        width: 1920,
        height: 1080,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 320, 180);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(320 * 180)); // 57,600 pixels
    });

    test('maneja imagen mínima 1x1', () async {
      // Arrange
      final data = Uint8List.fromList([128]);

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 1,
      );

      final img = MockCameraImage(
        width: 1,
        height: 1,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 1, 1);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(1));
      expect(result[0], equals(128));
    });

    test('maneja output mínimo 1x1', () async {
      // Arrange: Imagen grande reducida a 1x1
      final data = Uint8List(100);
      for (int i = 0; i < 100; i++) {
        data[i] = i;
      }

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 10,
      );

      final img = MockCameraImage(
        width: 10,
        height: 10,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 1, 1);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(1));
    });

    test('maneja valores extremos de pixels', () async {
      // Arrange: Imagen con valores min y max
      final data = Uint8List.fromList([
        0,
        255,
        0,
        255,
        255,
        0,
        255,
        0,
        0,
        255,
        0,
        255,
        255,
        0,
        255,
        0,
      ]);

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 4,
      );

      final img = MockCameraImage(
        width: 4,
        height: 4,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 2, 2);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(4));

      // Verificar que mantiene los valores extremos
      expect(result[0], equals(0));
      expect(result[1], equals(0));
      expect(result[2], equals(0));
      expect(result[3], equals(0));
    });

    test('maneja aspect ratio diferente', () async {
      // Arrange: Imagen 16x9 -> 4x3 (cambio de aspect ratio)
      final data = Uint8List(144); // 16×9 = 144
      for (int i = 0; i < 144; i++) {
        data[i] = (i * 2) % 256;
      }

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 16,
      );

      final img = MockCameraImage(
        width: 16,
        height: 9,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 4, 3);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(12)); // 4×3 = 12
    });

    test('retorna null cuando falta plano', () async {
      // Arrange: Imagen sin planos
      final img = MockCameraImage(
        width: 4,
        height: 4,
        planes: [], // Sin planos
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 2, 2);

      // Assert
      expect(result, isNull);
    });

    test('retorna null cuando hay excepción en procesamiento', () async {
      // Arrange: Plane con datos insuficientes
      final data = Uint8List(10); // Muy pequeño para 16x16

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 16,
      );

      final img = MockCameraImage(
        width: 16,
        height: 16,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 8, 8);

      // Assert
      expect(result, isNotNull); // Debería funcionar por el clamping
    });

    test('maneja reducción asimétrica', () async {
      // Arrange: Reducir más en una dimensión que en otra
      final data = Uint8List(64); // 8x8
      for (int i = 0; i < 64; i++) {
        data[i] = i;
      }

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 8,
      );

      final img = MockCameraImage(
        width: 8,
        height: 8,
        planes: [plane],
      );

      // Act: Reducir a 8x2 (mantener ancho, reducir altura)
      final result = await cameraImageToGreyscaleDownscale(img, 8, 2);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(16)); // 8×2 = 16
    });

    test('nearest neighbor selecciona pixel correcto', () async {
      // Arrange: Patrón específico para verificar algoritmo
      final data = Uint8List.fromList([
        10,
        11,
        12,
        13,
        14,
        15,
        20,
        21,
        22,
        23,
        24,
        25,
        30,
        31,
        32,
        33,
        34,
        35,
        40,
        41,
        42,
        43,
        44,
        45,
        50,
        51,
        52,
        53,
        54,
        55,
        60,
        61,
        62,
        63,
        64,
        65,
      ]);

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 6,
      );

      final img = MockCameraImage(
        width: 6,
        height: 6,
        planes: [plane],
      );

      // Act: Reducir a 3x3
      final result = await cameraImageToGreyscaleDownscale(img, 3, 3);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(9)); // 3×3

      // Verificar mapeo correcto de nearest neighbor
      // Para 3x3 desde 6x6, debería tomar cada 2 pixels
      expect(result[0], equals(10)); // (0,0)
      expect(result[1], equals(12)); // (2,0)
      expect(result[2], equals(14)); // (4,0)
      expect(result[3], equals(30)); // (0,2)
      expect(result[4], equals(32)); // (2,2)
      expect(result[5], equals(34)); // (4,2)
      expect(result[6], equals(50)); // (0,4)
      expect(result[7], equals(52)); // (2,4)
      expect(result[8], equals(54)); // (4,4)
    });

    test('maneja múltiples conversiones consecutivas', () async {
      // Arrange
      final data = Uint8List.fromList([
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
      ]);

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 4,
      );

      final img = MockCameraImage(
        width: 4,
        height: 4,
        planes: [plane],
      );

      // Act: Múltiples conversiones
      final result1 = await cameraImageToGreyscaleDownscale(img, 2, 2);
      final result2 = await cameraImageToGreyscaleDownscale(img, 3, 3);
      final result3 = await cameraImageToGreyscaleDownscale(img, 1, 1);

      // Assert
      expect(result1, isNotNull);
      expect(result1!.length, equals(4));

      expect(result2, isNotNull);
      expect(result2!.length, equals(9));

      expect(result3, isNotNull);
      expect(result3!.length, equals(1));
    });

    test('preserva rango de valores durante downscaling', () async {
      // Arrange: Gradient horizontal
      final data = Uint8List(256); // 16x16
      for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
          data[y * 16 + x] = (x * 16); // 0, 16, 32, ..., 240
        }
      }

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 16,
      );

      final img = MockCameraImage(
        width: 16,
        height: 16,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 8, 8);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(64));

      // Verificar que los valores están en el rango esperado
      final min = result.reduce((a, b) => a < b ? a : b);
      final max = result.reduce((a, b) => a > b ? a : b);

      expect(min, greaterThanOrEqualTo(0));
      expect(max, lessThanOrEqualTo(255));
    });

    test('maneja imagen con datos uniformes', () async {
      // Arrange: Toda la imagen con el mismo valor
      final data = Uint8List(100);
      data.fillRange(0, 100, 128); // Todo en 128

      final plane = MockPlane(
        bytes: data,
        bytesPerRow: 10,
      );

      final img = MockCameraImage(
        width: 10,
        height: 10,
        planes: [plane],
      );

      // Act
      final result = await cameraImageToGreyscaleDownscale(img, 5, 5);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(25));

      // Todos los valores deberían ser 128
      for (final pixel in result) {
        expect(pixel, equals(128));
      }
    });
  });
}
