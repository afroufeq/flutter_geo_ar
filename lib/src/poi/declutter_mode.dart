/// Modos de declutter para controlar cómo se manejan los solapamientos entre etiquetas de POIs
///
/// El sistema de declutter controla la densidad visual de las etiquetas en la vista AR,
/// permitiendo un balance entre mostrar la máxima información posible y mantener
/// la legibilidad.
enum DeclutterMode {
  /// Sin decluttering - Muestra todos los POIs sin evitar solapamientos
  ///
  /// **Uso recomendado:**
  /// - Visualización de datos completos para análisis
  /// - Cuando se necesita ver absolutamente todos los POIs disponibles
  /// - Debugging o desarrollo
  ///
  /// **Ventajas:**
  /// - Muestra el 100% de los POIs disponibles
  /// - Sin procesamiento adicional de filtrado
  ///
  /// **Desventajas:**
  /// - Puede resultar en pantalla muy saturada
  /// - Etiquetas pueden superponerse y ser difíciles de leer
  off,

  /// Declutter ligero - Solo evita overlaps grandes (>80%)
  ///
  /// Permite solapamientos menores entre etiquetas, pero evita que se cubran casi completamente.
  ///
  /// **Uso recomendado:**
  /// - Áreas con alta densidad de POIs (>500 POIs)
  /// - Cuando se quiere maximizar la información visible
  /// - Zonas urbanas densas o rutas de senderismo con muchos puntos
  ///
  /// **Ventajas:**
  /// - Muestra más POIs que el modo normal (~80-90%)
  /// - Mantiene legibilidad básica
  /// - Buen balance entre densidad y usabilidad
  light,

  /// Declutter normal - Evita cualquier overlap (Default)
  ///
  /// Comportamiento por defecto. Evita cualquier solapamiento entre etiquetas.
  ///
  /// **Uso recomendado:**
  /// - Uso general
  /// - Balance óptimo entre densidad de información y legibilidad
  /// - Aplicaciones de turismo y exploración
  ///
  /// **Ventajas:**
  /// - Etiquetas completamente legibles (~60-70% visible)
  /// - Aspecto visual limpio y profesional
  /// - Buen rendimiento
  normal,

  /// Declutter agresivo - Mayor spacing
  ///
  /// Evita cualquier overlap con un margen de seguridad adicional del 20%.
  ///
  /// **Uso recomendado:**
  /// - Presentaciones o demos
  /// - Aplicaciones donde la claridad es prioritaria sobre la cantidad
  /// - Dispositivos con pantallas pequeñas
  /// - Usuarios con dificultades visuales
  ///
  /// **Ventajas:**
  /// - Máxima legibilidad (~40-50% visible)
  /// - Aspecto visual más espaciado y "limpio"
  /// - Ideal para screenshots y presentaciones
  aggressive,
}
