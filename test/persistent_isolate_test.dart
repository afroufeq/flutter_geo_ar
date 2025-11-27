import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/utils/persistent_isolate.dart';

void main() {
  group('PersistentIsolate', () {
    test('se puede crear instancia', () {
      // Arrange & Act
      final isolate = PersistentIsolate();

      // Assert
      expect(isolate, isNotNull);

      // Cleanup
      isolate.dispose();
    });

    test('dispose puede ser llamado sin spawn', () {
      // Arrange
      final isolate = PersistentIsolate();

      // Act & Assert
      expect(() => isolate.dispose(), returnsNormally);
    });

    test('múltiples dispose son seguros', () {
      // Arrange
      final isolate = PersistentIsolate();

      // Act & Assert
      expect(() {
        isolate.dispose();
        isolate.dispose();
        isolate.dispose();
      }, returnsNormally);
    });

    test('verifica que la clase tiene los métodos esperados', () {
      // Arrange
      final isolate = PersistentIsolate();

      // Assert - Verificar que los métodos existen
      expect(isolate.spawn, isA<Function>());
      expect(isolate.compute, isA<Function>());
      expect(isolate.dispose, isA<Function>());

      // Cleanup
      isolate.dispose();
    });
  });
}
