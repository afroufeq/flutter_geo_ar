import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_ar/src/session/geoar_session_manager.dart';

void main() {
  group('GeoArSessionManager', () {
    test('es un singleton', () {
      // Arrange & Act
      final manager1 = GeoArSessionManager();
      final manager2 = GeoArSessionManager();

      // Assert
      expect(identical(manager1, manager2), isTrue);
    });

    test('proporciona acceso a poseManager', () {
      // Arrange
      final manager = GeoArSessionManager();

      // Act
      final poseManager = manager.poseManager;

      // Assert
      expect(poseManager, isNotNull);
    });

    test('proporciona acceso a isolate', () {
      // Arrange
      final manager = GeoArSessionManager();

      // Act
      final isolate = manager.isolate;

      // Assert
      expect(isolate, isNotNull);
    });

    test('proporciona acceso a telemetry', () {
      // Arrange
      final manager = GeoArSessionManager();

      // Act
      final telemetry = manager.telemetry;

      // Assert
      expect(telemetry, isNotNull);
    });

    test('stopSession puede ser llamado múltiples veces de forma segura', () {
      // Arrange
      final manager = GeoArSessionManager();

      // Act & Assert - No debería crashear
      expect(() {
        manager.stopSession();
        manager.stopSession();
        manager.stopSession();
      }, returnsNormally);
    });

    test('todos los componentes son accesibles', () {
      // Arrange
      final manager = GeoArSessionManager();

      // Act & Assert - Verificar que todos los getters funcionan
      expect(manager.poseManager, isNotNull);
      expect(manager.isolate, isNotNull);
      expect(manager.telemetry, isNotNull);
    });

    test('la instancia singleton persiste entre llamadas', () {
      // Arrange & Act
      final manager1 = GeoArSessionManager();
      final poseManager1 = manager1.poseManager;

      final manager2 = GeoArSessionManager();
      final poseManager2 = manager2.poseManager;

      // Assert - Deben ser los mismos objetos
      expect(identical(manager1, manager2), isTrue);
      expect(identical(poseManager1, poseManager2), isTrue);
    });

    test('stopSession no falla si no se ha iniciado sesión', () {
      // Arrange
      final manager = GeoArSessionManager();

      // Act & Assert
      expect(() => manager.stopSession(), returnsNormally);
    });

    test('se puede acceder a los componentes sin iniciar sesión', () {
      // Arrange
      final manager = GeoArSessionManager();

      // Act & Assert - Acceso básico sin startSession
      expect(manager.poseManager, isNotNull);
      expect(manager.isolate, isNotNull);
      expect(manager.telemetry, isNotNull);
    });

    test('telemetry service mantiene estado entre accesos', () {
      // Arrange
      final manager = GeoArSessionManager();

      // Act
      final telemetry1 = manager.telemetry;
      final telemetry2 = manager.telemetry;

      // Assert
      expect(identical(telemetry1, telemetry2), isTrue);
    });
  });
}
