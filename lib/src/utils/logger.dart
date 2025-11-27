import 'package:flutter/foundation.dart';

/// Una función de registro (logging) segura para producción.
/// Solo llama a la función 'print' (o debugPrint) si estamos en modo Debug.
void utilLog(String message) {
  if (kDebugMode) {
    // Usamos 'debugPrint' de Flutter en lugar de 'print' estándar
    // ya que es más optimizada para el motor de Flutter.
    debugPrint('AR Plugin LOG: $message');
  }
}
