import 'dart:convert';
import 'package:flutter/services.dart';
import 'poi_model.dart';

/// Utilidad para cargar POIs desde archivos JSON en assets
class PoiLoader {
  /// Carga una lista de POIs desde un archivo JSON en assets
  ///
  /// El JSON puede tener dos formatos:
  /// 1. Array directo: [{"id": "...", "name": "...", ...}, ...]
  /// 2. Objeto con array: {"pois": [{"id": "...", "name": "...", ...}, ...]}
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// final pois = await PoiLoader.loadFromAsset('assets/data/pois/tenerife_pois.json');
  /// ```
  static Future<List<Poi>> loadFromAsset(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);

      if (jsonData is List) {
        // Formato: [{"id": "...", ...}, ...]
        return jsonData.map((item) => Poi.fromMap(item as Map<String, dynamic>)).toList();
      } else if (jsonData is Map && jsonData.containsKey('pois')) {
        // Formato: {"pois": [{"id": "...", ...}, ...]}
        final poisList = jsonData['pois'] as List;
        return poisList.map((item) => Poi.fromMap(item as Map<String, dynamic>)).toList();
      }

      throw FormatException(
          'Formato JSON no válido en $assetPath. Se esperaba un array de POIs o un objeto con clave "pois".');
    } catch (e) {
      throw Exception('Error cargando POIs desde $assetPath: $e');
    }
  }
}
