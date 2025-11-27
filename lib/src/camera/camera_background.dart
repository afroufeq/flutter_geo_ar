import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera_controller_bridge.dart';

class CameraBackground extends StatefulWidget {
  final CameraDescription? camera;
  const CameraBackground({this.camera, super.key});

  @override
  State<CameraBackground> createState() => CameraBackgroundState();
}

class CameraBackgroundState extends State<CameraBackground> with WidgetsBindingObserver {
  final CameraControllerBridge _bridge = CameraControllerBridge();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    if (widget.camera == null) return;
    await _bridge.initialize(widget.camera!);
    if (mounted) setState(() => _isReady = true);
  }

  // Métodos públicos para control desde GeoArView
  Future<void> pause() async => await _bridge.pause();
  Future<void> resume() async => await _bridge.resume();
  CameraController? get controller => _bridge.controller;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _bridge.pause();
    if (state == AppLifecycleState.resumed) _bridge.resume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TEMPORAL: Fondo azul para pruebas en oficina
    return Container(color: Colors.blue);

    // TODO: Descomentar para volver a usar la cámara en pruebas de campo
    // if (!_isReady || _bridge.controller == null) return Container(color: Colors.black);
    // return CameraPreview(_bridge.controller!);
  }
}
