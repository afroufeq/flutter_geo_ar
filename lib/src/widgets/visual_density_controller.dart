import 'package:flutter/foundation.dart';
import '../poi/declutter_mode.dart';

/// Callback que se ejecuta cuando cambia la densidad visual
typedef DensityChangedCallback = void Function(
  double density,
  double maxDistance,
  int minImportance,
  DeclutterMode declutterMode,
);

/// Presets predefinidos para densidad visual
enum VisualDensityPreset {
  /// Vista limpia - Solo lo más importante y cercano (0.0)
  minimal,

  /// Vista baja - POIs importantes en rango medio (0.25)
  low,

  /// Vista equilibrada - Recomendado (0.5)
  normal,

  /// Vista alta - Muchos POIs visibles (0.75)
  high,

  /// Vista máxima - Toda la información disponible (1.0)
  maximum,
}

/// Controlador que gestiona la lógica de mapeo entre densidad visual
/// y los parámetros técnicos de GeoArView
///
/// Convierte un valor de densidad simple (0.0-1.0) en los parámetros
/// maxDistance, minImportance y declutterMode.
class VisualDensityController extends ChangeNotifier {
  double _density;
  final DensityChangedCallback? onDensityChanged;

  /// Crea un nuevo controlador de densidad visual
  ///
  /// [initialDensity] - Densidad inicial (0.0-1.0), por defecto 0.5
  /// [onDensityChanged] - Callback opcional que se ejecuta cuando cambia la densidad
  VisualDensityController({
    double initialDensity = 0.5,
    this.onDensityChanged,
  }) : _density = initialDensity.clamp(0.0, 1.0);

  /// Densidad visual actual (0.0-1.0)
  double get density => _density;

  /// Distancia máxima en metros calculada a partir de la densidad
  ///
  /// Mapeo lineal:
  /// - 0.0 (mínima) → 5,000m (5 km)
  /// - 0.5 (normal) → 27,500m (27.5 km)
  /// - 1.0 (máxima) → 50,000m (50 km)
  double get maxDistance => 5000 + (_density * 45000);

  /// Importancia mínima calculada a partir de la densidad
  ///
  /// Mapeo inverso:
  /// - 0.0 (mínima) → 10 (solo POIs muy importantes)
  /// - 0.5 (normal) → 5 (POIs moderadamente importantes)
  /// - 1.0 (máxima) → 1 (todos los POIs)
  int get minImportance => (10 - (_density * 9)).round();

  /// Modo de declutter calculado a partir de la densidad
  ///
  /// Mapeo por rangos:
  /// - 0.0 - 0.3 → aggressive (mayor espaciado)
  /// - 0.3 - 0.7 → normal (equilibrado)
  /// - 0.7 - 0.9 → light (menos restrictivo)
  /// - 0.9 - 1.0 → off (sin filtrado)
  DeclutterMode get declutterMode {
    if (_density < 0.3) {
      return DeclutterMode.aggressive;
    } else if (_density < 0.7) {
      return DeclutterMode.normal;
    } else if (_density < 0.9) {
      return DeclutterMode.light;
    } else {
      return DeclutterMode.off;
    }
  }

  /// Establece un nuevo valor de densidad
  ///
  /// El valor se limita automáticamente entre 0.0 y 1.0
  void setDensity(double value) {
    final newDensity = value.clamp(0.0, 1.0);
    if (_density != newDensity) {
      _density = newDensity;
      notifyListeners();
      onDensityChanged?.call(_density, maxDistance, minImportance, declutterMode);
    }
  }

  /// Establece la densidad usando un preset predefinido
  void setPreset(VisualDensityPreset preset) {
    switch (preset) {
      case VisualDensityPreset.minimal:
        setDensity(0.0);
        break;
      case VisualDensityPreset.low:
        setDensity(0.25);
        break;
      case VisualDensityPreset.normal:
        setDensity(0.5);
        break;
      case VisualDensityPreset.high:
        setDensity(0.75);
        break;
      case VisualDensityPreset.maximum:
        setDensity(1.0);
        break;
    }
  }

  /// Obtiene el valor de densidad para un preset específico
  static double getPresetValue(VisualDensityPreset preset) {
    switch (preset) {
      case VisualDensityPreset.minimal:
        return 0.0;
      case VisualDensityPreset.low:
        return 0.25;
      case VisualDensityPreset.normal:
        return 0.5;
      case VisualDensityPreset.high:
        return 0.75;
      case VisualDensityPreset.maximum:
        return 1.0;
    }
  }
}
