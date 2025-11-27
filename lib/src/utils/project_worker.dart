import 'dart:isolate';
import 'dart:ui';
import '../poi/poi_renderer.dart';
import '../poi/poi_model.dart';
import '../sensors/fused_data.dart';

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

List<Map<String, dynamic>> _processFrame(Map<String, dynamic> input, PoiRenderer renderer) {
  final pois = (input['pois'] as List).map((m) => Poi.fromMap(m)).toList();
  final sensors = FusedData.fromMap(input['sensors']);

  renderer.focalLength = (input['focal'] as num).toDouble();

  final projected = renderer.projectPois(
      pois,
      (input['userLat'] as num).toDouble(),
      (input['userLon'] as num).toDouble(),
      (input['userAlt'] as num).toDouble(),
      sensors,
      Size((input['width'] as num).toDouble(), (input['height'] as num).toDouble()),
      calibration: (input['calibration'] as num).toDouble());

  return projected
      .map((rp) => {
            'x': rp.x,
            'y': rp.y,
            'distance': rp.distance,
            'poiName': rp.poi.name,
            'poiKey': rp.poi.key,
            'importance': rp.poi.importance
          })
      .toList();
}
