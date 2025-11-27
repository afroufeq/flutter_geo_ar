import 'dart:typed_data';
import 'package:flutter/services.dart';

class DemService {
  final String? _demPath;
  bool _isInitialized = false;

  // Datos y Metadatos
  Float32List? _elevationData;
  late double _pixelSize;
  late double _minLat, _minLon, _maxLat, _maxLon;
  late int _width, _height;

  DemService([this._demPath]);

  /// Inicializa el servicio cargando el archivo DEM desde assets
  ///
  /// [assetPath] es la ruta del asset DEM (ej: 'assets/data/dem/tenerife_cog.tif')
  /// Si no se proporciona, usa el path del constructor (para compatibilidad)
  Future<void> init([String? assetPath]) async {
    final pathToLoad = assetPath ?? _demPath;
    if (pathToLoad == null) {
      print("[GeoAR] ⚠️  No se proporcionó ruta al DEM. La oclusión/altitud será imprecisa.");
      return;
    }

    ByteData byteData;
    try {
      byteData = await rootBundle.load(pathToLoad);
    } catch (e) {
      print("[GeoAR] ❌ No se pudo cargar el DEM desde $pathToLoad: $e");
      return;
    }

    final bytes = byteData.buffer.asUint8List();

    // Asumimos que el preprocesamiento guardó los metadatos esenciales
    // (Ancho, Alto, Lat/Lon mín/máx) en los primeros 32 bytes del archivo binario,
    // seguido por los datos de elevación como raw Float32List.

    if (bytes.length < 32) {
      print("[GeoAR] ❌ El archivo DEM tiene un formato inválido o está incompleto.");
      return;
    }

    final metadata = ByteData.view(bytes.buffer, 0, 32);
    // 4 bytes: width (int32)
    _width = metadata.getInt32(0, Endian.little);
    // 4 bytes: height (int32)
    _height = metadata.getInt32(4, Endian.little);
    // 8 bytes: minLat (float64)
    _minLat = metadata.getFloat64(8, Endian.little);
    // 8 bytes: minLon (float64)
    _minLon = metadata.getFloat64(16, Endian.little);
    // 8 bytes: maxLat (float64) - maxLon se calcula
    _maxLat = metadata.getFloat64(24, Endian.little);

    // Los datos comienzan después de los 32 bytes de metadatos.
    const dataOffset = 32;
    // La longitud debe ser revisada para evitar error de rango al crear el view
    int expectedLength = _width * _height * 4; // 4 bytes por Float32
    if (bytes.length - dataOffset < expectedLength) {
      print("[GeoAR] ❌ Los datos de elevación están incompletos en el archivo DEM.");
      return;
    }

    _elevationData = Float32List.view(bytes.buffer, dataOffset);

    // Asumimos que la relación de aspecto es 1:1 en el mapa
    _pixelSize = (_maxLat - _minLat) / _height;
    // Se necesita _maxLon real, pero lo simulamos:
    _maxLon = _minLon + _pixelSize * _width;

    _isInitialized = true;
    print(
        "[GeoAR] ✅ DEM cargado: ${_width}x${_height} píxeles, cobertura: (${_minLat.toStringAsFixed(4)},${_minLon.toStringAsFixed(4)}) a (${_maxLat.toStringAsFixed(4)},${_maxLon.toStringAsFixed(4)})");
  }

  /// Obtiene la elevación para una latitud y longitud dadas.
  double? getElevation(double lat, double lon) {
    // **CORRECCIÓN:** Lanza StateError si el servicio no ha sido inicializado.
    if (!_isInitialized) {
      throw StateError('DemService must be successfully initialized before calling getElevation.');
    }

    // Si _isInitialized es true, _elevationData ya no es null.

    // 1. Verificar límites geográficos
    // Usamos las variables late que deben estar inicializadas si _isInitialized es true
    if (lat < _minLat || lat > _maxLat || lon < _minLon || lon > _maxLon) {
      return null; // Fuera de los límites del DEM
    }

    // 2. Mapear coordenadas a índices de píxel
    // Row 0 es latitud máxima (_maxLat)
    int row = ((_maxLat - lat) / _pixelSize).floor();
    int col = ((lon - _minLon) / _pixelSize).floor();

    if (row < 0 || row >= _height || col < 0 || col >= _width) {
      return null;
    }

    // 3. Obtener elevación del índice
    final index = row * _width + col;
    if (index >= 0 && index < _elevationData!.length) {
      return _elevationData![index].toDouble();
    }

    return null;
  }
}
