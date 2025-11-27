import 'dart:async';

/// Transforma un stream para emitir como máximo una vez cada [duration].
class ThrottleLatest<T> extends StreamTransformerBase<T, T> {
  final Duration duration;
  ThrottleLatest(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamController<T> controller;
    Timer? timer;
    T? latestEvent;
    bool hasPending = false;

    controller = StreamController<T>(
      onListen: () {
        stream.listen(
          (event) {
            latestEvent = event;
            hasPending = true;
            if (timer == null || !timer!.isActive) {
              controller.add(latestEvent as T);
              hasPending = false;
              timer = Timer(duration, () {
                if (hasPending && latestEvent != null) {
                  controller.add(latestEvent as T);
                  hasPending = false;
                  // Loop si siguen llegando eventos rápido
                  timer = Timer(duration, () {}); 
                }
              });
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }
}