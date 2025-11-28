/// Modo de visualización de la información de los POIs
///
/// Controla cómo se muestra la información de los POIs según su distancia
enum PoiDisplayMode {
  /// Muestra siempre toda la información del POI (icono, nombre y distancia)
  /// independientemente de la distancia
  always,

  /// Muestra la información del POI basándose en la distancia (LOD - Level of Detail):
  /// - Cerca (< 500m): icono + nombre + distancia
  /// - Media distancia (500-2000m): icono + nombre
  /// - Lejos (> 2000m): solo icono
  distanceBased,
}
