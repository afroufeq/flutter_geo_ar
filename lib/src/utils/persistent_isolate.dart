import 'dart:async';
import 'dart:isolate';

/// Mantiene un Isolate vivo para procesar frames continuamente sin overhead de spawn.
class PersistentIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  final Map<int, Completer<dynamic>> _pending = {};
  int _idCounter = 0;

  Future<void> spawn(void Function(SendPort) entryPoint) async {
    final initPort = ReceivePort();
    _isolate = await Isolate.spawn(entryPoint, initPort.sendPort);
    _sendPort = await initPort.first as SendPort;
    
    _receivePort.listen((message) {
      if (message is Map && message.containsKey('id')) {
        final id = message['id'] as int;
        if (_pending.containsKey(id)) {
          if (message.containsKey('error')) {
            _pending[id]?.completeError(message['error']);
          } else {
            _pending[id]?.complete(message['result']);
          }
          _pending.remove(id);
        }
      }
    });
    
    // Handshake inicial
    _sendPort?.send({'cmd': 'init', 'port': _receivePort.sendPort});
  }

  Future<dynamic> compute(Map<String, dynamic> task) {
    final completer = Completer<dynamic>();
    final id = _idCounter++;
    _pending[id] = completer;
    
    task['id'] = id;
    _sendPort?.send(task);
    
    return completer.future;
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
  }
}