# Indicador de Precisión de Sensores

## Descripción General

El **Indicador de Precisión de Sensores** informa al usuario sobre la calidad actual de la calibración de la brújula (magnetómetro), que es fundamental para la orientación en AR. Este indicador ayuda a distinguir entre errores del plugin y problemas ambientales, aumentando la confianza del usuario.

## ¿Por qué es importante?

La brújula (magnetómetro) es muy susceptible a interferencias magnéticas, lo que causa desalineación de los POIs. Con este indicador, el usuario puede:

- Entender por qué la vista AR no es precisa en un momento dado
- Saber cuándo necesita moverse o recalibrar
- Distinguir entre un error del plugin y un problema ambiental
- Reducir la frustración del usuario

## Implementación Técnica

### Android

En Android, se captura la precisión del magnetómetro mediante el callback `onAccuracyChanged`:

```kotlin
override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
    if (sensor?.type == Sensor.TYPE_MAGNETIC_FIELD) {
        magnetometerAccuracy = accuracy
        // Valores: 0=SENSOR_STATUS_UNRELIABLE, 1=LOW, 2=MEDIUM, 3=HIGH
    }
}
```

Los valores se envían en cada evento de orientación dentro del mapa de datos.

### iOS

En iOS, se utiliza la propiedad `headingAccuracy` de `CLHeading`:

```swift
func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    // headingAccuracy en grados (negativo = inválido)
    // < 10° = alta precisión
    // 10-30° = media
    // 30-90° = baja
    // > 90° o negativo = no fiable
}
```

### Modelo de Datos

La clase `FusedData` incluye campos de precisión:

```dart
class FusedData {
  // Campos existentes de orientación y ubicación...
  
  // Campos de precisión
  final int? magnetometerAccuracy;    // Android: 0-3
  final double? headingAccuracy;       // iOS: grados
}
```

### Enum SensorAccuracy

Normaliza los valores entre plataformas:

```dart
enum SensorAccuracy {
  high,        // Alta precisión - Calibración óptima
  medium,      // Precisión media - Puede requerir calibración
  low,         // Precisión baja - Calibración recomendada
  unreliable;  // No fiable - Interferencia magnética

  static SensorAccuracy fromFusedData(FusedData? data) {
    // Convierte valores de Android (0-3) o iOS (grados) a enum
  }
}
```

## Uso de los Widgets

### SensorAccuracyIndicator

Widget principal que muestra el estado con icono y opcionalmente con texto:

```dart
SensorAccuracyIndicator(
  sensorData: fusedData,
  showLabel: true,  // Mostrar texto además del icono
  size: 24.0,       // Tamaño del icono
  onTap: () {
    // Acción al tocar (ej: abrir calibración)
  },
)
```

**Parámetros:**
- `sensorData`: Datos actuales de los sensores (`FusedData?`)
- `showLabel`: Mostrar etiqueta de texto (default: `false`)
- `size`: Tamaño del icono (default: `24.0`)
- `onTap`: Callback opcional cuando se toca el indicador

### CompactSensorAccuracyIndicator

Versión minimalista que muestra solo un punto de color:

```dart
CompactSensorAccuracyIndicator(
  sensorData: fusedData,
  onTap: () {
    // Acción al tocar
  },
)
```

## Estados de Precisión

| Estado | Color | Icono | Android | iOS | Descripción |
|--------|-------|-------|---------|-----|-------------|
| **Alta** | Verde | `gps_fixed` | 3 | < 10° | Calibración óptima |
| **Media** | Naranja | `gps_not_fixed` | 2 | 10-30° | Puede requerir calibración |
| **Baja** | Rojo | `gps_off` | 1 | 30-90° | Calibración recomendada |
| **No fiable** | Rojo oscuro | `error_outline` | 0 | < 0° o > 90° | Interferencia magnética |

## Ejemplo de Integración

```dart
import 'package:flutter_geo_ar/flutter_geo_ar.dart';

class MyArView extends StatelessWidget {
  final FusedData? sensorData;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Vista AR
        GeoArView(
          // ... configuración
        ),
        
        // Indicador en la esquina superior derecha
        Positioned(
          top: 16,
          right: 16,
          child: SensorAccuracyIndicator(
            sensorData: sensorData,
            showLabel: true,
            onTap: () {
              final accuracy = SensorAccuracy.fromFusedData(sensorData);
              if (accuracy == SensorAccuracy.low || 
                  accuracy == SensorAccuracy.unreliable) {
                _showCalibrationDialog();
              }
            },
          ),
        ),
      ],
    );
  }
  
  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibración necesaria'),
        content: const Text(
          'Mueve el dispositivo en forma de "8" o '
          'aléjate de objetos metálicos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
```

## Verificación Automática de Precisión

Puedes monitorear la precisión y actuar proactivamente:

```dart
void _monitorSensorAccuracy() {
  poseManager.stream.listen((data) {
    final accuracy = SensorAccuracy.fromFusedData(data);
    
    // Alertar si la precisión cae drásticamente
    if (accuracy == SensorAccuracy.unreliable) {
      _showCalibrationWarning();
    }
    
    // Opcional: Ajustar el filtro de POIs según la precisión
    if (accuracy == SensorAccuracy.low || 
        accuracy == SensorAccuracy.unreliable) {
      // Reducir sensibilidad o aumentar tolerancia
    }
  });
}
```

## Internacionalización

Todos los textos están traducidos:

```dart
// Español
t.sensorAccuracy.high              // "Alta"
t.sensorAccuracy.medium            // "Media"
t.sensorAccuracy.low               // "Baja"
t.sensorAccuracy.unreliable        // "No fiable"
t.sensorAccuracy.tapToCalibrate    // "Toca para calibrar"

// English
t.sensorAccuracy.high              // "High"
t.sensorAccuracy.medium            // "Medium"
t.sensorAccuracy.low               // "Low"
t.sensorAccuracy.unreliable        // "Unreliable"
t.sensorAccuracy.tapToCalibrate    // "Tap to calibrate"
```

## Impacto en el Rendimiento

- **Batería**: Nulo. Solo visualiza datos que el sistema operativo ya proporciona
- **CPU**: Mínimo. Solo evalúa un valor numérico cuando cambia
- **Memoria**: Despreciable. Solo almacena 1-2 valores adicionales en `FusedData`

## Mejores Prácticas

### 1. Ubicación del Indicador

Colócalo en una posición visible pero no intrusiva:

```dart
// Bueno: Esquina superior
Positioned(top: 16, right: 16, child: indicator)

// Evitar: Centro de la pantalla (bloquea vista AR)
```

### 2. Acción Interactiva

Si la precisión es baja, permite al usuario calibrar:

```dart
onTap: () {
  if (needsCalibration) {
    showCalibrationInstructions();
  }
}
```

### 3. Notificaciones Proactivas

Para precisión crítica, alerta automáticamente:

```dart
if (accuracy == SensorAccuracy.unreliable) {
  showDialog(context: context, builder: (_) => CalibrationAlert());
}
```

### 4. Combinación con Debug Overlay

En modo debug, muestra valores exactos:

```dart
if (debugMode) {
  Column(
    children: [
      SensorAccuracyIndicator(sensorData: data, showLabel: true),
      Text('Android: ${data.magnetometerAccuracy}'),
      Text('iOS: ${data.headingAccuracy}°'),
    ],
  )
}
```

## Troubleshooting

### El indicador siempre muestra "No fiable"

**Posibles causas:**
- Dispositivo cerca de superficies metálicas (mesa, coche)
- Interferencia electromagnética (altavoces, imanes)
- Magnetómetro no calibrado
- Magnetómetro defectuoso

**Soluciones:**
1. Alejar el dispositivo de fuentes magnéticas
2. Mover el dispositivo en forma de "8" para auto-calibrar
3. Reiniciar la aplicación
4. En iOS: Ir a Ajustes → Privacidad → Servicios de localización → Calibración de brújula

### Diferencias entre Android e iOS

Los sistemas usan métricas diferentes que son normalizadas por `SensorAccuracy.fromFusedData()`:

| Nivel | Android | iOS |
|-------|---------|-----|
| High | 3 | < 10° |
| Medium | 2 | 10-30° |
| Low | 1 | 30-90° |
| Unreliable | 0 | < 0° o > 90° |

### El indicador no se actualiza

Verifica que:
1. Los sensores están iniciados: `poseManager.start()`
2. Estás pasando datos actualizados: `sensorData: currentData`
3. El widget se reconstruye cuando cambian los datos: `setState()`

## Ejemplo Completo

Ver `example/lib/sensor_accuracy_example.dart` para un ejemplo funcional completo que incluye:

- Inicialización de sensores
- Visualización de ambos indicadores (completo y compacto)
- Verificación automática de precisión
- Diálogo de calibración
- Panel de debug con valores numéricos

## Referencias

### Documentación de Plataforma

- [Android SensorManager](https://developer.android.com/reference/android/hardware/SensorManager)
- [iOS CLHeading](https://developer.apple.com/documentation/corelocation/clheading)

### Archivos Relacionados

- `lib/src/sensors/fused_data.dart` - Modelo de datos
- `lib/src/sensors/sensor_accuracy.dart` - Enum y conversión
- `lib/src/widgets/sensor_accuracy_indicator.dart` - Widgets
- `android/src/main/kotlin/.../SensorEventStreamHandler.kt` - Android
- `ios/Classes/SensorStreamHandler.swift` - iOS

---

**Versión**: 1.0.0  
**Fecha**: 27 de noviembre de 2025  
**Autor**: Optimización de sensores
