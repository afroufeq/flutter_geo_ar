import 'dart:ui';
import 'dart:math' as math;

/// Spatial Index basado en grid para detección eficiente de solapamientos
///
/// Utiliza una cuadrícula (grid) para dividir el espacio 2D en celdas,
/// permitiendo búsquedas de solapamiento en O(n) en lugar de O(n²).
///
/// **Algoritmo:**
/// 1. Dividir el espacio en celdas de tamaño fijo (cellSize)
/// 2. Al agregar un rectángulo, insertarlo en todas las celdas que ocupa
/// 3. Al verificar overlap, solo comprobar rectángulos en las mismas celdas
///
/// **Complejidad:**
/// - Inserción: O(k) donde k es el número de celdas que ocupa el rectángulo
/// - Búsqueda: O(m) donde m es el número promedio de rectángulos por celda
/// - Total para n rectángulos: O(n * k * m) ≈ O(n) cuando k y m son pequeños
class SpatialIndex {
  /// Tamaño de cada celda del grid en píxeles
  final double cellSize;

  /// Ancho del espacio indexado (generalmente el ancho de la pantalla)
  final double width;

  /// Alto del espacio indexado (generalmente el alto de la pantalla)
  final double height;

  /// Grid de celdas, cada celda contiene una lista de rectángulos
  /// La clave es "x,y" donde x,y son las coordenadas de la celda
  final Map<String, List<Rect>> _grid = {};

  /// Lista de todos los rectángulos agregados (para debugging/estadísticas)
  final List<Rect> _allRects = [];

  SpatialIndex({
    required this.width,
    required this.height,
    this.cellSize = 100.0,
  });

  /// Reinicia el índice, eliminando todos los rectángulos
  void clear() {
    _grid.clear();
    _allRects.clear();
  }

  /// Agrega un rectángulo al índice espacial
  ///
  /// El rectángulo se inserta en todas las celdas que intersecta.
  void add(Rect rect) {
    _allRects.add(rect);

    // Calcular las celdas que ocupa este rectángulo
    final minCellX = _getCellX(rect.left);
    final maxCellX = _getCellX(rect.right);
    final minCellY = _getCellY(rect.top);
    final maxCellY = _getCellY(rect.bottom);

    // Insertar el rectángulo en todas las celdas que ocupa
    for (int cellX = minCellX; cellX <= maxCellX; cellX++) {
      for (int cellY = minCellY; cellY <= maxCellY; cellY++) {
        final key = '$cellX,$cellY';
        _grid.putIfAbsent(key, () => []).add(rect);
      }
    }
  }

  /// Verifica si el rectángulo dado se solapa con algún rectángulo ya agregado
  ///
  /// **Modo normal:** Retorna true si hay cualquier overlap
  bool overlapsAny(Rect rect) {
    // Obtener las celdas que ocuparía este rectángulo
    final minCellX = _getCellX(rect.left);
    final maxCellX = _getCellX(rect.right);
    final minCellY = _getCellY(rect.top);
    final maxCellY = _getCellY(rect.bottom);

    // Verificar overlap solo con rectángulos en las mismas celdas
    for (int cellX = minCellX; cellX <= maxCellX; cellX++) {
      for (int cellY = minCellY; cellY <= maxCellY; cellY++) {
        final key = '$cellX,$cellY';
        final rectsInCell = _grid[key];
        if (rectsInCell != null) {
          for (final existingRect in rectsInCell) {
            if (rect.overlaps(existingRect)) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  /// Verifica si el rectángulo tiene un overlap grande (mayor al umbral especificado)
  ///
  /// **Modo light:** Solo retorna true si el área de overlap es mayor al umbral
  /// del área del rectángulo más pequeño.
  ///
  /// Por ejemplo, con overlapThreshold = 0.8:
  /// - Si dos rectángulos se solapan en un 85%, retorna true
  /// - Si dos rectángulos se solapan en un 50%, retorna false
  ///
  /// [overlapThreshold] Umbral de overlap (0.0 a 1.0). Por defecto 0.8 (80%)
  bool hasLargeOverlap(Rect rect, {double overlapThreshold = 0.8}) {
    // Obtener las celdas que ocuparía este rectángulo
    final minCellX = _getCellX(rect.left);
    final maxCellX = _getCellX(rect.right);
    final minCellY = _getCellY(rect.top);
    final maxCellY = _getCellY(rect.bottom);

    final rectArea = rect.width * rect.height;

    // Verificar overlap con rectángulos en las mismas celdas
    for (int cellX = minCellX; cellX <= maxCellX; cellX++) {
      for (int cellY = minCellY; cellY <= maxCellY; cellY++) {
        final key = '$cellX,$cellY';
        final rectsInCell = _grid[key];
        if (rectsInCell != null) {
          for (final existingRect in rectsInCell) {
            final intersection = rect.intersect(existingRect);
            if (!intersection.isEmpty) {
              // Calcular el área de overlap
              final overlapArea = intersection.width * intersection.height;
              final existingArea = existingRect.width * existingRect.height;

              // Usar el área del rectángulo más pequeño como referencia
              final smallerArea = math.min(rectArea, existingArea);

              // Si el overlap es mayor al umbral del área más pequeña, es un overlap grande
              if (overlapArea / smallerArea > overlapThreshold) {
                return true;
              }
            }
          }
        }
      }
    }

    return false;
  }

  /// Obtiene el índice de celda X para una coordenada X
  int _getCellX(double x) {
    return (x / cellSize).floor().clamp(0, (width / cellSize).ceil() - 1);
  }

  /// Obtiene el índice de celda Y para una coordenada Y
  int _getCellY(double y) {
    return (y / cellSize).floor().clamp(0, (height / cellSize).ceil() - 1);
  }

  /// Obtiene estadísticas del índice (útil para debugging)
  Map<String, dynamic> getStats() {
    final cellsUsed = _grid.length;
    final totalCells = ((width / cellSize).ceil() * (height / cellSize).ceil());
    final rectsPerCell = _grid.values.map((list) => list.length).toList();
    final avgRectsPerCell = rectsPerCell.isEmpty ? 0.0 : rectsPerCell.reduce((a, b) => a + b) / rectsPerCell.length;
    final maxRectsInCell = rectsPerCell.isEmpty ? 0 : rectsPerCell.reduce(math.max);

    return {
      'totalRects': _allRects.length,
      'cellsUsed': cellsUsed,
      'totalCells': totalCells,
      'cellUsagePercent': (cellsUsed / totalCells * 100).toStringAsFixed(1),
      'avgRectsPerCell': avgRectsPerCell.toStringAsFixed(1),
      'maxRectsInCell': maxRectsInCell,
      'memoryEstimateKB': ((cellsUsed * 50 + _allRects.length * 32) / 1024).toStringAsFixed(1),
    };
  }
}
