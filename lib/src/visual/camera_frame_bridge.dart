import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Utilidad para convertir y reducir frames de cámara de forma eficiente.
/// Se ejecuta en un Isolate (compute) para no bloquear UI.
Future<Uint8List?> cameraImageToGreyscaleDownscale(CameraImage img, int outW, int outH) async {
  try {
    // En Android/iOS YUV420, el plano 0 es la luminancia (escala de grises)
    final Plane yPlane = img.planes[0];
    final int srcW = img.width;
    final int srcH = img.height;
    final Uint8List src = yPlane.bytes;
    final int stride = yPlane.bytesPerRow;

    return await compute(_downscale, _Args(src, srcW, srcH, outW, outH, stride));
  } catch (e) {
    return null;
  }
}

class _Args {
  final Uint8List src;
  final int srcW, srcH, outW, outH, stride;
  _Args(this.src, this.srcW, this.srcH, this.outW, this.outH, this.stride);
}

// Función top-level para compute()
Uint8List _downscale(_Args args) {
  final out = Uint8List(args.outW * args.outH);

  // Nearest neighbor downsampling
  for (int y = 0; y < args.outH; y++) {
    final int srcY = (y * args.srcH) ~/ args.outH;
    final int rowOffset = srcY * args.stride;

    for (int x = 0; x < args.outW; x++) {
      final int srcX = (x * args.srcW) ~/ args.outW;
      // Clamp por seguridad, aunque la matemática debería ser exacta
      int idx = rowOffset + srcX;
      if (idx < args.src.length) {
        out[y * args.outW + x] = args.src[idx];
      }
    }
  }
  return out;
}
