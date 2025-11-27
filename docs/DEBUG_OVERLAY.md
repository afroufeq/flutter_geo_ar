# Debug Overlay - Monitorización en Tiempo Real

El **Debug Overlay** es una herramienta de desarrollo integrada en `flutter_geo_ar` que permite monitorizar el rendimiento y estado del sistema AR en tiempo real. Es esencial para debugging, optimización y verificación del correcto funcionamiento del plugin.

## Tabla de Contenidos

- [Introducción](#introducción)
- [Activación y Configuración](#activación-y-configuración)
- [Métricas Monitorizadas](#métricas-monitorizadas)
- [Interpretación de Métricas](#interpretación-de-métricas)
- [Casos de Uso](#casos-de-uso)
- [Optimización Basada en Métricas](#optimización-basada-en-métricas)
- [API de TelemetryService](#api-de-telemetryservice)
- [Troubleshooting](#troubleshooting)

---

## Introducción

### ¿Qué es el Debug Overlay?

El Debug Overlay es un widget semitransparente posicionado en la esquina inferior derecha de la pantalla que muestra:

- **Métricas de rendimiento**: FPS, tiempos de procesamiento, cache hit rate
- **Estadísticas de POIs**: Visibles, totales, filtrados
- **Datos de sensores**: GPS, brújula, altitud, calibración
- **Información de filtros**: Horizon culling, importance, categorías

### ¿Cuándo usarlo?

**✅ Escenarios recomendados:**
- Desarrollo y debugging de nuevas features
- Optimización de rendimiento
- Testing en diferentes dispositivos
- Detección de problemas de sensores
- Validación de configuración (throttleHz, maxDistance, etc.)
- Comparación de diferentes configuraciones

**❌ Cuándo NO usarlo:**
- Producción (afecta UX)
- Capturas de pantalla o videos
- Demos a usuarios finales
- Cuando no necesitas debugging activo

---

## Activación y Configuración

### Activación Básica

```dart
import 'package:flutter_geo_ar/flutter_geo_ar.dart';

GeoArView(
  demPath: 'assets/data/dem/region.tif',
  poisPath: 'assets/data/pois/region.json',
  showDebugOverlay: true, // Activa el overlay
)
```

### Configuración Avanzada

```dart
GeoArView(
  demPath: 'assets/data/dem/region.tif',
  poisPath: 'assets/data/pois/region.json',
  showDebugOverlay: true,
  showPerformanceMetrics: true, // Muestra sección de rendimiento
  // Si solo necesitas ver sensores/filtros:
  // showPerformanceMetrics: false
)
```

### Toggle Dinámico en Desarrollo

```dart
class DebugConfig extends StatefulWidget {
  @override
  State<DebugConfig> createState() => _DebugConfigState();
}

class _DebugConfigState extends State<DebugConfig> {
  bool _showDebug = false;
  
  @override
  void initState() {
    super.initState();
    // Activar automáticamente en modo debug de Flutter
    assert(() {
      _showDebug = true;
      return true;
    }());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GeoAR'),
        actions: [
          // Toggle rápido en AppBar
          IconButton(
            icon: Icon(
              _showDebug ? Icons.bug_report : Icons.bug_report_outlined
            ),
            onPressed: () {
              setState(() => _showDebug = !_showDebug);
            },
            tooltip: 'Toggle Debug Overlay',
          ),
        ],
      ),
      body: GeoArView(
        demPath: 'assets/data/dem/region.tif',
        poisPath: 'assets/data/pois/region.json',
        showDebugOverlay: _showDebug,
      ),
    );
  }
}
```

---

## Métricas Monitorizadas

### Sección DEPURACIÓN (RENDIMIENTO)

#### 1. FPS (Frames Por Segundo)

**Descripción**: Mide la fluidez visual de la experiencia AR.

**Valores:**
- **Verde (>55 FPS)**: Excelente rendimiento
- **Amarillo (30-55 FPS)**: Rendimiento aceptable
- **Rojo (<30 FPS)**: Rendimiento deficiente

**Cómo se calcula**: Promedio móvil de los últimos 60 frames.

**Factores que afectan**:
- `throttleHz`: Frecuencia de actualización de sensores
- Número de POIs visibles
- Complejidad del decluttering
- Potencia del dispositivo

**Optimización**:
```dart
// Si FPS < 30
GeoArView(
  throttleHz: 8.0,        // Reducir de 10 a 8
  maxDistance: 15000.0,   // Menos POIs procesados
  declutterMode: DeclutterMode.aggressive,
)
```

#### 2. POIs visible/total

**Descripción**: Muestra cuántos POIs están visibles en pantalla vs. totales cargados.

**Formato**: `"visibles/totales"` (ej: "15/250")

**Interpretación**:
- **Visibles bajos (<10)**: Normal si estás mirando al cielo o mar
- **Visibles altos (>50)**: Posible saturación visual, considerar filtros
- **Totales altos (>1000)**: Considerar usar `minImportance` para filtrar

**Factores que afectan**:
- Orientación de la cámara
- `maxDistance`
- `minImportance`
- `visibleCategories`
- Horizon culling
- Densidad de POIs en la región

**Optimización**:
```dart
// Reducir POIs procesados
GeoArView(
  maxDistance: 15000.0,   // De 20km a 15km
  minImportance: 5,       // Filtrar POIs menos importantes
  visibleCategories: {'natural:peak', 'amenity:shelter'}, // Solo categorías relevantes
)
```

#### 3. Cache hit rate (% de aciertos)

**Descripción**: Porcentaje de proyecciones que se reutilizan del cache sin recalcular.

**Valores:**
- **Verde (>80%)**: Cache funcionando óptimamente
- **Cyan (50-80%)**: Aceptable, usuario en movimiento
- **Naranja (<50%)**: Bajo, usuario moviéndose mucho o umbrales muy estrictos

**Cómo funciona**: El sistema cachea proyecciones cuando el usuario no se ha movido significativamente (< 2m) o rotado (< 2°).

**Interpretación**:
- **Alta (>80%)**: Usuario mayormente estacionario
- **Media (50-80%)**: Usuario caminando lentamente
- **Baja (<50%)**: Usuario en movimiento rápido

**Es normal que sea bajo si**:
- Usuario está caminando activamente
- Usuario está en vehículo
- Usuario está barriendo la cámara rápidamente

**NO es normal si**:
- Usuario está quieto y el rate es <30%
- Puede indicar GPS jitter excesivo

#### 4. Projection time (Tiempo en ms)

**Descripción**: Tiempo de procesamiento de proyección de POIs en el isolate worker.

**Valores:**
- **Verde (<5ms)**: Óptimo
- **Amarillo (5-16ms)**: Aceptable (16ms = budget de 60 FPS)
- **Rojo (>16ms)**: Puede causar drops de FPS

**Incluye**:
- Transformación de coordenadas (LLH → ECEF → ENU → Camera)
- Cálculo de distancias
- Aplicación de horizon culling
- Filtrado por distancia e importancia

**Optimización**:
```dart
// Si Projection > 10ms
GeoArView(
  maxDistance: 10000.0,  // Menos POIs a procesar
  minImportance: 5,      // Pre-filtrar POIs
  useHorizonCulling: false, // Desactivar si no es necesario
)
```

#### 5. Declutter time (Tiempo en ms)

**Descripción**: Tiempo de procesamiento del algoritmo de anti-solapamiento.

**Valores:**
- **Verde (<5ms)**: Óptimo
- **Amarillo (5-16ms)**: Aceptable
- **Rojo (>16ms)**: Revisar configuración

**Factores que afectan**:
- Número de POIs visibles
- `declutterMode` (light, normal, aggressive)
- Spatial index (optimizado en v0.0.10)

**Optimización**:
```dart
// Si Declutter > 10ms
GeoArView(
  declutterMode: DeclutterMode.light, // Menos checks
  maxDistance: 15000.0,                // Menos POIs
)
```

---

### Sección FILTROS

Esta sección aparece solo si hay POIs siendo filtrados activamente.

#### 1. Detrás (Importance Filter)

**Descripción**: Número de POIs filtrados por el parámetro `minImportance`.

**Cuándo aparece**: Solo si `minImportance > 1` y hay POIs siendo filtrados.

**Interpretación**:
- **Alto (>50%)**: Filtro agresivo, considerar reducir `minImportance`
- **Bajo (<10%)**: Filtro poco efectivo, considerar aumentar `minImportance`

**Ejemplo**:
```dart
GeoArView(
  minImportance: 7, // Solo POIs muy importantes
  // Si ves muchos POIs filtrados (>80%), reducir a 5 o 6
)
```

#### 2. Muy lejos (Category Filter)

**Descripción**: Número de POIs filtrados por `visibleCategories`.

**Cuándo aparece**: Solo si `visibleCategories` no está vacío.

**Interpretación**:
- Muestra cuántos POIs están ocultos por no pertenecer a las categorías visibles
- Útil para verificar que el filtro funciona correctamente

**Ejemplo**:
```dart
GeoArView(
  visibleCategories: {'natural:peak', 'amenity:shelter'},
  // Verás cuántos POIs de otras categorías están ocultos
)
```

#### 3. Horizonte (Horizon Culling)

**Descripción**: Número de POIs ocultos por montañas usando horizon culling.

**Cuándo aparece**: Solo si `useHorizonCulling: true` y hay POIs detrás de montañas.

**Interpretación**:
- **0**: No hay POIs ocultos o feature desactivada
- **Alto (>20)**: Normal en áreas montañosas
- **Muy alto (>100)**: Revisar perfil de horizonte

---

### Sección SENSORES

#### 1. Latitud/Longitud

**Descripción**: Coordenadas GPS actuales con 6 decimales.

**Precisión**: ~0.11 metros por decimal (6 decimales = ~11cm teórico)

**Interpretación**:
- **Valores estables**: GPS con buena señal
- **Valores saltando**: GPS jitter o mala señal
- **Sin valores (—)**: Sin señal GPS

**Troubleshooting**:
- Si cambian constantemente sin moverte: GPS jitter, normal en interiores
- Si son —: No hay señal GPS

#### 2. Altitud

**Descripción**: Altitud GPS actual en metros sobre el nivel del mar.

**Precisión**: GPS altitude es menos preciso que lat/lon (±10-50m típico)

**Interpretación**:
- Valor razonable para tu ubicación
- Puede variar incluso sin moverte (normal)

#### 3. Rumbo (Heading)

**Descripción**: Dirección de la brújula en grados (0° = Norte, 90° = Este, etc.)

**Rango**: 0-360°

**Interpretación**:
- **Estable**: Brújula funcionando bien
- **Saltando mucho**: Interferencia magnética o necesita calibración
- **Rotando solo**: Drift, necesita calibración

**Troubleshooting**:
- Si rota sin mover el dispositivo: Calibrar magnetómetro
- Si salta entre valores: Alejar de fuentes magnéticas

#### 4. Inclinación (Pitch)

**Descripción**: Ángulo de inclinación vertical del dispositivo en grados.

**Rango**: -180° a 180° (típicamente -90° a 90°)

**Interpretación**:
- **~0°**: Dispositivo horizontal
- **Negativo**: Dispositivo apuntando hacia abajo
- **Positivo**: Dispositivo apuntando hacia arriba

**Uso**: Importante para determinar si el usuario está mirando el horizonte, el cielo o el suelo.

#### 5. Calibración

**Descripción**: Offset de calibración manual aplicado en grados.

**Cuándo aparece**: Solo si `calibrationOffset ≠ 0.0`

**Rango**: Típicamente -45° a +45°

**Interpretación**:
- **No aparece**: Sin calibración manual aplicada (0°)
- **±10-20°**: Calibración normal
- **>±30°**: Calibración agresiva, puede indicar problema con brújula

---

## Interpretación de Métricas

### Escenarios Comunes

#### Escenario 1: Rendimiento Óptimo

```
DEPURACIÓN
━━━━━━━━━━━━━━━
FPS                 58.3    (verde)
POIs visible/total  12/450
Cache hit rate      92%     (verde)
Projection time     3.2ms   (verde)
Declutter time      1.8ms   (verde)

SENSORES
━━━━━━━━━━━━━━━
Latitud       28.123456°
Longitud     -16.543210°
Altitud       850m
Rumbo         245.3°
Inclinación   -10.5°
```

**Análisis**: Sistema funcionando perfectamente. No requiere optimización.

#### Escenario 2: FPS Bajos

```
DEPURACIÓN
━━━━━━━━━━━━━━━
FPS                 24.1    (rojo)
POIs visible/total  68/1200
Cache hit rate      35%     (naranja)
Projection time     18.4ms  (rojo)
Declutter time      15.2ms  (rojo)
```

**Análisis**: 
- FPS bajos debido a muchos POIs visibles y tiempos de procesamiento altos
- Cache bajo indica movimiento constante
- Projection y Declutter exceden budget de 16ms

**Solución**:
```dart
GeoArView(
  throttleHz: 8.0,                      // Reducir de 10 a 8
  maxDistance: 15000.0,                 // De 20km a 15km
  minImportance: 5,                     // Filtrar POIs
  declutterMode: DeclutterMode.light,   // Menos procesamiento
)
```

#### Escenario 3: GPS Inestable

```
SENSORES
━━━━━━━━━━━━━━━
Latitud       28.123456° → 28.123478° → 28.123442° (cambiando rápido)
Longitud     -16.543210°
Altitud       850m → 862m → 847m (saltando)
Rumbo         245.3° → 248.1° → 243.8°
Calibración   -15.0°
```

**Análisis**: GPS jitter excesivo, posible mala señal.

**Solución**:
1. Mover a área con mejor señal GPS
2. Esperar estabilización GPS
3. Considerar filtro de Kalman
4. Aumentar umbrales de cache

#### Escenario 4: Brújula Desalineada

```
SENSORES
━━━━━━━━━━━━━━━
Rumbo         125.3° (pero mirando al norte visualmente)
Calibración   -42.0° (muy alto)
```

**Análisis**: Brújula necesita calibración o hay interferencia magnética.

**Solución**:
1. Calibrar magnetómetro del dispositivo
2. Alejar de fuentes magnéticas
3. Verificar que no hay funda con imán

#### Escenario 5: Muchos POIs Filtrados

```
DEPURACIÓN
━━━━━━━━━━━━━━━
FPS                 55.2
POIs visible/total  25/850

FILTROS
━━━━━━━━━━━━━━━
Detrás        180    (importanceFiltered)
Muy lejos     350    (categoryFiltered)
Horizonte      45    (horizonCulled)
```

**Análisis**: Filtros muy agresivos, muchos POIs ocultos.

**Solución**:
- Si `Detrás` (importancia) es muy alto: Reducir `minImportance`
- Si `Muy lejos` (categoría) es muy alto: Revisar `visibleCategories`
- Si `Horizonte` es muy alto: Normal en zonas montañosas

---

## Casos de Uso

### Caso 1: Desarrollo de Nueva Feature

**Objetivo**: Verificar que una nueva feature no degrada el rendimiento.

```dart
// Antes de implementar la feature
GeoArView(
  showDebugOverlay: true,
  // ... configuración existente
)

// Anotar métricas baseline:
// - FPS: 55
// - Projection: 4ms
// - Declutter: 2ms

// Después de implementar la feature
// Verificar que las métricas no han empeorado significativamente
```

### Caso 2: Optimización para Dispositivo Específico

**Objetivo**: Encontrar la configuración óptima para un dispositivo de gama baja.

```dart
// Test 1: Configuración base
GeoArView(
  showDebugOverlay: true,
  throttleHz: 10.0,
  maxDistance: 20000.0,
)
// Resultado: FPS = 22 (insuficiente)

// Test 2: Optimización
GeoArView(
  showDebugOverlay: true,
  throttleHz: 8.0,
  maxDistance: 15000.0,
  declutterMode: DeclutterMode.light,
  lowPowerMode: true,
)
// Resultado: FPS = 42 (aceptable)
```

### Caso 3: Debugging de Sensores

**Objetivo**: Verificar que los sensores funcionan correctamente.

```dart
GeoArView(
  showDebugOverlay: true,
  showPerformanceMetrics: false, // Solo sensores
)

// Verificar:
// - GPS está obteniendo posición (lat/lon cambian)
// - Altitud es razonable
// - Brújula responde a rotación del dispositivo
// - Inclinación responde al ángulo del dispositivo
// - Calibración está dentro de rango normal
```

### Caso 4: Comparación de Configuraciones

**Objetivo**: Comparar diferentes modos de declutter.

```dart
// Test A: Normal
GeoArView(
  showDebugOverlay: true,
  declutterMode: DeclutterMode.normal,
)
// Anotar: Declutter = 5.2ms, POIs visibles = 35

// Test B: Light
GeoArView(
  showDebugOverlay: true,
  declutterMode: DeclutterMode.light,
)
// Anotar: Declutter = 2.1ms, POIs visibles = 48

// Test C: Aggressive
GeoArView(
  showDebugOverlay: true,
  declutterMode: DeclutterMode.aggressive,
)
// Anotar: Declutter = 6.8ms, POIs visibles = 22

// Conclusión: Light ofrece mejor balance para este escenario
```

---

## Optimización Basada en Métricas

### Árbol de Decisión

```
¿FPS < 30?
├─ SÍ → ¿Projection > 10ms?
│   ├─ SÍ → Reducir maxDistance y/o minImportance
│   └─ NO → ¿Declutter > 10ms?
│       ├─ SÍ → Cambiar a DeclutterMode.light
│       └─ NO → Reducir throttleHz
└─ NO → Sistema funcionando bien

¿Cache < 50%?
├─ SÍ → ¿Usuario en movimiento?
│   ├─ SÍ → Normal, no requiere acción
│   └─ NO → Revisar GPS jitter o calibración
└─ NO → Cache funcionando bien

¿POIs visibles > 50?
├─ SÍ → Considerar:
│   ├─ Aumentar minImportance
│   ├─ Activar filtros de categoría
│   └─ Reducir maxDistance
└─ NO → Densidad aceptable
```

### Tabla de Optimización

| Síntoma | Métrica | Valor Problemático | Solución |
|---------|---------|-------------------|----------|
| Lag visual | FPS | <30 | Reducir throttleHz, maxDistance |
| POIs no se ven | POIs Visibles | 0 | Verificar orientación, maxDistance, filtros |
| Muchos POIs | POIs Visibles | >50 | Aumentar minImportance, filtros |
| Procesamiento lento | Projection | >16ms | Reducir maxDistance, minImportance |
| Declutter lento | Declutter | >16ms | Cambiar a .light, reducir POIs |
| Cache bajo quieto | Cache | <30% (sin movimiento) | Revisar GPS jitter |
| Brújula inestable | Rumbo | Saltando | Calibrar magnetómetro |
| GPS impreciso | Lat/Lon | Saltando | Esperar estabilización, mover a exterior |

---

## API de TelemetryService

### Uso Directo (Avanzado)

Si necesitas acceder a las métricas programáticamente:

```dart
import 'package:flutter_geo_ar/flutter_geo_ar.dart';

final telemetry = TelemetryService();

// Obtener métricas actuales
final metrics = telemetry.getMetrics();

print('FPS actual: ${metrics.fps}');
print('POIs visibles: ${metrics.poisVisible}');
print('Cache hit rate: ${(metrics.cacheHitRate * 100).toStringAsFixed(0)}%');

// Registrar eventos manualmente (si extiendes el sistema)
telemetry.recordFrameTime(16667); // microsegundos
telemetry.recordProjectionTime(5.2); // milisegundos
telemetry.recordCacheHit();

// Actualizar métricas de POIs
telemetry.updatePoiMetrics(
  visible: 25,
  total: 450,
  horizonCulled: 12,
  importanceFiltered: 180,
  categoryFiltered: 50,
);

// Actualizar datos de sensores
telemetry.updateSensorData(
  lat: 28.123456,
  lon: -16.543210,
  alt: 850.0,
  heading: 245.3,
  pitch: -10.5,
  roll: 2.3,
  calibrationOffset: -15.0,
);

// Resetear métricas (útil para testing)
telemetry.reset();
```

### Clase DebugMetrics

```dart
class DebugMetrics {
  // Rendimiento
  final double fps;                    // Frames por segundo
  final int poisVisible;               // POIs visibles
  final int poisTotal;                 // Total de POIs cargados
  final double cacheHitRate;           // 0.0-1.0
  final double projectionMs;           // Tiempo proyección
  final double declutterMs;            // Tiempo declutter
  
  // Filtros
  final int horizonCulledPois;         // POIs ocultos por horizonte
  final int importanceFilteredPois;    // POIs filtrados por importancia
  final int categoryFilteredPois;      // POIs filtrados por categoría
  
  // Sensores
  final double? lat;                   // Latitud
  final double? lon;                   // Longitud
  final double? alt;                   // Altitud
  final double? heading;               // Rumbo (0-360)
  final double? pitch;                 // Inclinación
  final double? roll;                  // Rotación lateral (no mostrado en overlay)
  final double calibrationOffset;      // Offset de calibración
  
  // Sistema
  final double memoryMb;               // Memoria usada (futuro)
  final int isolateCallbacks;          // Callbacks del isolate
  final bool cacheActive;              // Cache activo o no
}
```

---

## Troubleshooting

### El overlay no aparece

**Verificar**:
1. `showDebugOverlay: true` está configurado
2. No hay otros widgets cubriéndolo (z-index)
3. El plugin se ha inicializado correctamente

**Solución**:
```dart
GeoArView(
  showDebugOverlay: true, // Verificar que está true
  // Si aún no aparece, verificar logs
)
```

### Métricas muestran — o valores inválidos

**Causas posibles**:
- Sistema aún no ha recopilado suficientes datos
- GPS no tiene señal
- Sensores no inicializados

**Solución**: Esperar unos segundos para que el sistema se estabilice.

### FPS siempre muestra el mismo valor

**Causa**: `throttleHz` está limitando la frecuencia de actualización.

**Esperado**: Si `throttleHz = 10`, FPS máximo será ~10.

### Cache siempre muestra 0%

**Causas**:
- Usuario en movimiento constante (normal)
- GPS jitter excesivo
- Umbrales de cache muy estrictos

**Verificar**: Observar lat/lon para ver si cambian constantemente.

### Overlay afecta el rendimiento

**Esperado**: El overlay tiene un impacto mínimo (<1% CPU), actualizando cada 500ms.

**Solución**: Desactivar en producción.

```dart
// En producción
GeoArView(
  showDebugOverlay: false, // Desactivar
)
```

### La sección FILTROS no aparece

**Esperado**: La sección FILTROS solo se muestra si hay POIs siendo filtrados activamente.

**Verificar**:
- Que `useHorizonCulling: true` si quieres ver horizon culling
- Que `minImportance > 1` si quieres ver filtro de importancia
- Que `visibleCategories` no esté vacío si quieres ver filtro de categoría

---

## Mejores Prácticas

### 1. Desarrollo

```dart
// Activar automáticamente en debug builds
class MyGeoArView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool showDebug = false;
    assert(() {
      showDebug = true; // Solo en debug mode
      return true;
    }());
    
    return GeoArView(
      showDebugOverlay: showDebug,
      // ... resto de configuración
    );
  }
}
```

### 2. Testing

```dart
// Guardar métricas para análisis
class MetricsLogger {
  final List<DebugMetrics> _history = [];
  
  void record() {
    final metrics = TelemetryService().getMetrics();
    _history.add(metrics);
    
    // Guardar cada 10 segundos
    if (_history.length % 10 == 0) {
      _saveToFile();
    }
  }
  
  void _saveToFile() {
    // Exportar a CSV o JSON para análisis
  }
}
```

### 3. Producción

```dart
// NUNCA activar en producción
GeoArView(
  showDebugOverlay: false, // Siempre false en producción
)
```

### 4. Comparación

```dart
// Tomar screenshots con métricas para comparar configuraciones
void captureMetrics(String configName) {
  final metrics = TelemetryService().getMetrics();
  print('Config: $configName');
  print('  FPS: ${metrics.fps}');
  print('  Projection: ${metrics.projectionMs}ms');
  print('  POIs: ${metrics.poisVisible}');
  // ...
}
```

---

## Características de la Implementación

### Actualización de Métricas

El overlay se actualiza cada **500ms** mediante un `Timer.periodic`. Esto proporciona un balance entre información actualizada y uso de recursos.

### Posicionamiento

El overlay está posicionado en la **esquina inferior derecha** (bottom: 10, right: 10) para no interferir con la vista AR principal.

### Estilos y Colores

El overlay utiliza un sistema de colores semántico:
- **Verde**: Valores óptimos (FPS >55, Cache >80%, tiempo <5ms)
- **
