import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/horizon/terrain_layers_painter.dart';
import 'package:flutter_geo_ar/src/poi/dem_service.dart';
import 'package:flutter_geo_ar/src/sensors/fused_data.dart';

// Mock DemService para testing
class MockDemService extends DemService {
  final Map<String, double> _elevations = {};
  bool _isReady = false;

  MockDemService() : super(null);

  void setElevation(double lat, double lon, double elevation) {
    final key = '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
    _elevations[key] = elevation;
    _isReady = true;
  }

  @override
  double? getElevation(double lat, double lon) {
    if (!_isReady) return null;
    final key = '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
    return _elevations[key];
  }
}

void main() {
  group('TerrainLayer', () {
    test('se crea correctamente con parámetros requeridos', () {
      const layer = TerrainLayer(
        distance: 5000.0,
        color: Colors.blue,
        strokeWidth: 2.0,
        label: '5km',
      );

      expect(layer.distance, 5000.0);
      expect(layer.color, Colors.blue);
      expect(layer.strokeWidth, 2.0);
      expect(layer.label, '5km');
    });

    test('usa valores por defecto cuando no se especifican', () {
      const layer = TerrainLayer(
        distance: 5000.0,
        color: Colors.blue,
      );

      expect(layer.strokeWidth, 1.5);
      expect(layer.label, '');
    });
  });

  group('TerrainLayersPainter', () {
    late MockDemService mockDem;
    late FusedData testData;
    late List<TerrainLayer> testLayers;

    setUp(() {
      mockDem = MockDemService();

      // Configurar algunos datos de elevación de prueba
      for (double lat = 27.9; lat <= 28.1; lat += 0.01) {
        for (double lon = -16.1; lon <= -15.9; lon += 0.01) {
          mockDem.setElevation(lat, lon, 500.0 + (lat - 28.0) * 100);
        }
      }

      testData = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 0.0,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
      );

      testLayers = [
        const TerrainLayer(
          distance: 5000.0,
          color: Colors.blue,
          strokeWidth: 2.0,
          label: '5km',
        ),
        const TerrainLayer(
          distance: 10000.0,
          color: Colors.green,
          strokeWidth: 1.5,
          label: '10km',
        ),
      ];
    });

    test('se crea correctamente con parámetros requeridos', () {
      final painter = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
      );

      expect(painter.dem, mockDem);
      expect(painter.sensors, testData);
      expect(painter.layers, testLayers);
      expect(painter.focalLength, 500.0);
      expect(painter.calibration, 0.0);
      expect(painter.showLabels, false);
    });

    test('acepta parámetros opcionales', () {
      final painter = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        focalLength: 600.0,
        calibration: 10.0,
        showLabels: true,
      );

      expect(painter.focalLength, 600.0);
      expect(painter.calibration, 10.0);
      expect(painter.showLabels, true);
    });

    test('paint se ejecuta sin errores con datos válidos', () {
      final painter = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
      );

      final canvas = MockCanvas();
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('paint maneja sensors null sin errores', () {
      final painter = TerrainLayersPainter(
        dem: mockDem,
        sensors: null,
        layers: testLayers,
      );

      final canvas = MockCanvas();
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('paint maneja heading null sin errores', () {
      final dataWithoutHeading = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: null,
        pitch: 0.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
      );

      final painter = TerrainLayersPainter(
        dem: mockDem,
        sensors: dataWithoutHeading,
        layers: testLayers,
      );

      final canvas = MockCanvas();
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('paint maneja pitch null sin errores', () {
      final dataWithoutPitch = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 0.0,
        pitch: null,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
      );

      final painter = TerrainLayersPainter(
        dem: mockDem,
        sensors: dataWithoutPitch,
        layers: testLayers,
      );

      final canvas = MockCanvas();
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('paint maneja lat o lon null sin errores', () {
      final dataWithoutCoords = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 0.0,
        pitch: 0.0,
        roll: 0.0,
        lat: null,
        lon: null,
        alt: 100.0,
      );

      final painter = TerrainLayersPainter(
        dem: mockDem,
        sensors: dataWithoutCoords,
        layers: testLayers,
      );

      final canvas = MockCanvas();
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('paint maneja lista de capas vacía sin errores', () {
      final painter = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: [],
      );

      final canvas = MockCanvas();
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('paint aplica calibración correctamente', () {
      final painter = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        calibration: 45.0,
      );

      final canvas = MockCanvas();
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('paint con showLabels true se ejecuta sin errores', () {
      final painter = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        showLabels: true,
      );

      final canvas = MockCanvas();
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('shouldRepaint devuelve true cuando cambian los sensores', () {
      final painter1 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
      );

      final newData = FusedData(
        ts: DateTime.now().millisecondsSinceEpoch,
        heading: 45.0,
        pitch: 10.0,
        roll: 0.0,
        lat: 28.0,
        lon: -16.0,
        alt: 100.0,
      );

      final painter2 = TerrainLayersPainter(
        dem: mockDem,
        sensors: newData,
        layers: testLayers,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint devuelve true cuando cambia la calibración', () {
      final painter1 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        calibration: 0.0,
      );

      final painter2 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        calibration: 10.0,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint devuelve true cuando cambia focalLength', () {
      final painter1 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        focalLength: 500.0,
      );

      final painter2 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        focalLength: 600.0,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint devuelve true cuando cambian las capas', () {
      final painter1 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
      );

      final newLayers = [
        const TerrainLayer(
          distance: 3000.0,
          color: Colors.red,
          strokeWidth: 1.0,
          label: '3km',
        ),
      ];

      final painter2 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: newLayers,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint devuelve true cuando cambia showLabels', () {
      final painter1 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        showLabels: false,
      );

      final painter2 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        showLabels: true,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint devuelve false cuando nada cambia', () {
      final painter1 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        focalLength: 500.0,
        calibration: 0.0,
        showLabels: false,
      );

      final painter2 = TerrainLayersPainter(
        dem: mockDem,
        sensors: testData,
        layers: testLayers,
        focalLength: 500.0,
        calibration: 0.0,
        showLabels: false,
      );

      expect(painter1.shouldRepaint(painter2), false);
    });

    test('funciona con diferentes orientaciones de heading', () {
      final headings = [0.0, 45.0, 90.0, 180.0, 270.0, 359.9];

      for (final heading in headings) {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: heading,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
        );

        final painter = TerrainLayersPainter(
          dem: mockDem,
          sensors: data,
          layers: testLayers,
        );

        final canvas = MockCanvas();
        const size = Size(800, 600);

        expect(() => painter.paint(canvas, size), returnsNormally, reason: 'Failed with heading $heading');
      }
    });

    test('funciona con diferentes valores de pitch', () {
      final pitches = [-90.0, -45.0, 0.0, 45.0, 90.0];

      for (final pitch in pitches) {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 0.0,
          pitch: pitch,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: 100.0,
        );

        final painter = TerrainLayersPainter(
          dem: mockDem,
          sensors: data,
          layers: testLayers,
        );

        final canvas = MockCanvas();
        const size = Size(800, 600);

        expect(() => painter.paint(canvas, size), returnsNormally, reason: 'Failed with pitch $pitch');
      }
    });

    test('funciona con diferentes altitudes', () {
      final altitudes = [0.0, 500.0, 1000.0, 2000.0];

      for (final alt in altitudes) {
        final data = FusedData(
          ts: DateTime.now().millisecondsSinceEpoch,
          heading: 0.0,
          pitch: 0.0,
          roll: 0.0,
          lat: 28.0,
          lon: -16.0,
          alt: alt,
        );

        final painter = TerrainLayersPainter(
          dem: mockDem,
          sensors: data,
          layers: testLayers,
        );

        final canvas = MockCanvas();
        const size = Size(800, 600);

        expect(() => painter.paint(canvas, size), returnsNormally, reason: 'Failed with altitude $alt');
      }
    });

    test('funciona con diferentes tamaños de canvas', () {
      final sizes = [
        const Size(400, 300),
        const Size(800, 600),
        const Size(1920, 1080),
      ];

      for (final size in sizes) {
        final painter = TerrainLayersPainter(
          dem: mockDem,
          sensors: testData,
          layers: testLayers,
        );

        final canvas = MockCanvas();

        expect(() => painter.paint(canvas, size), returnsNormally, reason: 'Failed with size $size');
      }
    });

    test('maneja DEM sin datos de elevación', () {
      final emptyDem = MockDemService();

      final painter = TerrainLayersPainter(
        dem: emptyDem,
        sensors: testData,
        layers: testLayers,
      );

      final canvas = MockCanvas();
      const size = Size(800, 600);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });
  });
}

// Mock Canvas para testing
class MockCanvas implements Canvas {
  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {}

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {}

  @override
  void clipRect(Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {}

  @override
  void clipRSuperellipse(RSuperellipse rsuperellipse, {bool doAntiAlias = true}) {}

  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint) {}

  @override
  void drawAtlas(ui.Image atlas, List<RSTransform> transforms, List<Rect> rects, List<Color>? colors,
      BlendMode? blendMode, Rect? cullRect, Paint paint) {}

  @override
  void drawCircle(Offset c, double radius, Paint paint) {}

  @override
  void drawColor(Color color, BlendMode blendMode) {}

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {}

  @override
  void drawImage(ui.Image image, Offset offset, Paint paint) {}

  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) {}

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {}

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {}

  @override
  void drawOval(Rect rect, Paint paint) {}

  @override
  void drawPaint(Paint paint) {}

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {}

  @override
  void drawPath(Path path, Paint paint) {}

  @override
  void drawPicture(ui.Picture picture) {}

  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) {}

  @override
  void drawRRect(RRect rrect, Paint paint) {}

  @override
  void drawRSuperellipse(RSuperellipse rsuperellipse, Paint paint) {}

  @override
  void drawRawAtlas(ui.Image atlas, Float32List rstTransforms, Float32List rects, Int32List? colors,
      BlendMode? blendMode, Rect? cullRect, Paint paint) {}

  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, Paint paint) {}

  @override
  void drawRect(Rect rect, Paint paint) {}

  @override
  void drawShadow(Path path, Color color, double elevation, bool transparentOccluder) {}

  @override
  void drawVertices(ui.Vertices vertices, BlendMode blendMode, Paint paint) {}

  @override
  int getSaveCount() => 0;

  @override
  void restore() {}

  @override
  void restoreToCount(int count) {}

  @override
  void rotate(double radians) {}

  @override
  void save() {}

  @override
  void saveLayer(Rect? bounds, Paint paint) {}

  @override
  void scale(double sx, [double? sy]) {}

  @override
  void skew(double sx, double sy) {}

  @override
  void transform(Float64List matrix4) {}

  @override
  void translate(double dx, double dy) {}

  @override
  Rect getDestinationClipBounds() => Rect.zero;

  @override
  Rect getLocalClipBounds() => Rect.zero;

  @override
  Float64List getTransform() => Float64List(16);
}
