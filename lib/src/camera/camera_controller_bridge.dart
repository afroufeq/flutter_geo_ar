import 'package:camera/camera.dart';

/// Wrapper para gestionar el CameraController con configuración óptima de batería.
class CameraControllerBridge {
  CameraController? _controller;

  Future<void> initialize(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      ResolutionPreset.low, // CLAVE: 'low' reduce drásticamente consumo CPU/GPU
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _controller?.initialize();
  }

  CameraController? get controller => _controller;

  Future<void> startStream(void Function(CameraImage) onImage) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isStreamingImages) return;
    
    await _controller?.startImageStream(onImage);
  }

  Future<void> stopStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller?.stopImageStream();
    }
  }

  Future<void> pause() async => await _controller?.pausePreview();
  Future<void> resume() async => await _controller?.resumePreview();
  
  void dispose() {
    _controller?.dispose();
  }
}