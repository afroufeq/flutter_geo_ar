import 'dart:isolate';
import 'dart:ui';
import '../poi/poi_renderer.dart';
import '../poi/poi_model.dart';
import '../sensors/fused_data.dart';
import '../horizon/horizon_generator.dart';

void projectWorkerEntry(SendPort sendPort) {
  final port = ReceivePort();
  sendPort.send(port.sendPort);
  final renderer = PoiRenderer();
  SendPort? mainThreadPort;

  port.listen((message) {
    if (message is Map) {
      if (message['cmd'] == 'init') {
        mainThreadPort = message['port'];
      } else if (message.containsKey('id')) {
        try {
          final result = _processFrame(message as Map<String, dynamic>, renderer);
          mainThreadPort?.send({'id': message['id'], 'result': result});
        } catch (e) {
          mainThreadPort?.send({'id': message['id'], 'error': e.toString()});
        }
      }
    }
  });
}

Map<String, dynamic> _processFrame(Map<String, dynamic> input, PoiRenderer renderer) {
  final startTime = DateTime.now();

  final pois = (input['pois'] as List).map((m) => Poi.fromMap(m)).toList();
  final sensors = FusedData.fromMap(input['sensors']);

  renderer.focalLength = (input['focal'] as num).toDouble();
  renderer.maxDistance = (input['maxDistance'] as num?)?.toDouble() ?? 20000.0;
  renderer.minImportance = (input['minImportance'] as num?)?.toInt() ?? 1;

  // Deserializar HorizonProfile si está presente
  HorizonProfile? horizonProfile;
  if (input.containsKey('horizonProfile') && input['horizonProfile'] != null) {
    horizonProfile = HorizonProfile.fromMap(input['horizonProfile'] as Map<String, dynamic>);
  }

  // Medir tiempo de proyección
  final projectionStart = DateTime.now();
  final projectionResult = renderer.projectPois(
      pois,
      (input['userLat'] as num).toDouble(),
      (input['userLon'] as num).toDouble(),
      (input['userAlt'] as num).toDouble(),
      sensors,
      Size((input['width'] as num).toDouble(), (input['height'] as num).toDouble()),
      calibration: (input['calibration'] as num).toDouble(),
      horizonProfile: horizonProfile);
  final projectionEnd = DateTime.now();
  final projectionMs = projectionEnd.difference(projectionStart).inMicroseconds / 1000.0;

  // El decluttering se realiza en PoiPainter, no en el worker de proyección
  final declutterMs = 0.0;

  final result = projectionResult.pois
      .map((rp) => {
            'x': rp.x,
            'y': rp.y,
            'distance': rp.distance,
            'poiName': rp.poi.name,
            'poiKey': rp.poi.key,
            'importance': rp.poi.importance
          })
      .toList();

  final endTime = DateTime.now();
  final totalMs = endTime.difference(startTime).inMicroseconds / 1000.0;

  // Calcular total de POIs filtrados
  final totalFiltered = projectionResult.behindUser +
      projectionResult.tooFar +
      projectionResult.lowImportance +
      projectionResult.horizonCulled;

  // Retornar resultado con métricas detalladas
  return {
    'pois': result,
    'metrics': {
      'projectionMs': projectionMs,
      'declutterMs': declutterMs,
      'totalMs': totalMs,
      'totalPois': projectionResult.totalProcessed,
      'visiblePois': projectionResult.pois.length,
      'filteredPois': totalFiltered,
      'behindUser': projectionResult.behindUser,
      'tooFar': projectionResult.tooFar,
      'lowImportance': projectionResult.lowImportance,
      'horizonCulled': projectionResult.horizonCulled,
    }
  };
}
