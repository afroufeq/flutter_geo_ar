import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:camera/camera.dart';
import 'package:flutter_geo_ar/flutter_geo_ar.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solicitar permisos necesarios
  await _requestPermissions();

  final cameras = await availableCameras();
  runApp(MyApp(camera: cameras.firstOrNull));
}

/// Solicita permisos de ubicación y cámara en runtime
Future<void> _requestPermissions() async {
  // Solicitar permisos de ubicación
  var locationStatus = await Permission.location.status;
  if (!locationStatus.isGranted) {
    print('[GeoAR] 📍 Solicitando permisos de ubicación...');
    locationStatus = await Permission.location.request();
    if (locationStatus.isGranted) {
      print('[GeoAR] ✅ Permisos de ubicación concedidos');
    } else {
      print('[GeoAR] ❌ Permisos de ubicación denegados');
    }
  } else {
    print('[GeoAR] ✅ Permisos de ubicación ya concedidos');
  }

  // Solicitar permisos de cámara
  var cameraStatus = await Permission.camera.status;
  if (!cameraStatus.isGranted) {
    print('[GeoAR] 📷 Solicitando permisos de cámara...');
    cameraStatus = await Permission.camera.request();
    if (cameraStatus.isGranted) {
      print('[GeoAR] ✅ Permisos de cámara concedidos');
    } else {
      print('[GeoAR] ❌ Permisos de cámara denegados');
    }
  } else {
    print('[GeoAR] ✅ Permisos de cámara ya concedidos');
  }
}

class MyApp extends StatelessWidget {
  final CameraDescription? camera;
  const MyApp({this.camera, super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(home: HomeScreen(camera: camera));
}

class HomeScreen extends StatelessWidget {
  final CameraDescription? camera;
  const HomeScreen({this.camera, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Geo-AR Example")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ejemplo de uso del plugin flutter_geo_ar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Gran Canaria AR (con cámara)"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GeoArView(
                    camera: camera,
                    // Cargar POIs desde archivo JSON
                    poisPath: 'assets/data/pois/gran_canaria_pois.json',
                    // Ruta al archivo DEM binario preprocesado
                    demPath: 'assets/data/dem/gran_canaria.bin',
                    focalLength: 520,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              child: const Text("🔧 MODO DEBUG (con sensores)"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GeoArView(
                    // Pasar cámara para activar sensores, pero ocultar preview con debugMode
                    camera: camera,
                    poisPath: 'assets/data/pois/gran_canaria_pois.json',
                    demPath: 'assets/data/dem/gran_canaria.bin',
                    focalLength: 520,
                    debugMode: true, // Oculta imagen de cámara pero mantiene sensores
                    showHorizonDebug: true, // Mostrar info de debug del horizonte
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              child: const Text("Gran Canaria (POIs manuales)"),
              onPressed: () {
                // Ejemplo con POIs definidos manualmente - Cercanos a tu ubicación
                // Tu posición: 28.139867, -15.4347245
                final pois = [
                  // Norte - 100m
                  Poi(
                    id: 'poi_norte',
                    name: 'POI Norte',
                    lat: 28.140767,
                    lon: -15.4347245,
                    elevation: 100,
                    importance: 5,
                    category: 'natural',
                    subtype: 'peak',
                  ),
                  // Sur - 100m
                  Poi(
                    id: 'poi_sur',
                    name: 'POI Sur',
                    lat: 28.138967,
                    lon: -15.4347245,
                    elevation: 100,
                    importance: 5,
                    category: 'natural',
                    subtype: 'peak',
                  ),
                  // Este - 100m
                  Poi(
                    id: 'poi_este',
                    name: 'POI Este',
                    lat: 28.139867,
                    lon: -15.4337245,
                    elevation: 100,
                    importance: 5,
                    category: 'natural',
                    subtype: 'peak',
                  ),
                  // Oeste - 100m
                  Poi(
                    id: 'poi_oeste',
                    name: 'POI Oeste',
                    lat: 28.139867,
                    lon: -15.4357245,
                    elevation: 100,
                    importance: 5,
                    category: 'natural',
                    subtype: 'peak',
                  ),
                  // Noreste - 150m
                  Poi(
                    id: 'poi_noreste',
                    name: 'POI NE',
                    lat: 28.141217,
                    lon: -15.4337245,
                    elevation: 120,
                    importance: 4,
                    category: 'tourism',
                    subtype: 'viewpoint',
                  ),
                  // Noroeste - 150m
                  Poi(
                    id: 'poi_noroeste',
                    name: 'POI NO',
                    lat: 28.141217,
                    lon: -15.4357245,
                    elevation: 120,
                    importance: 4,
                    category: 'tourism',
                    subtype: 'viewpoint',
                  ),
                  // Sureste - 150m
                  Poi(
                    id: 'poi_sureste',
                    name: 'POI SE',
                    lat: 28.138517,
                    lon: -15.4337245,
                    elevation: 80,
                    importance: 4,
                    category: 'tourism',
                    subtype: 'viewpoint',
                  ),
                  // Suroeste - 150m
                  Poi(
                    id: 'poi_suroeste',
                    name: 'POI SO',
                    lat: 28.138517,
                    lon: -15.4357245,
                    elevation: 80,
                    importance: 4,
                    category: 'tourism',
                    subtype: 'viewpoint',
                  ),
                ];

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GeoArView(
                      camera: camera,
                      pois: pois,
                      demPath: 'assets/data/dem/gran_canaria.bin',
                      focalLength: 520,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
