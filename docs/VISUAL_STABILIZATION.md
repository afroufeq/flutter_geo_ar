# Estabilización Visual (Visual Tracking)

## Descripción General

El sistema de estabilización visual es una característica que utiliza el giroscopio del dispositivo para contrarrestar las pequeñas vibraciones y movimientos de la mano del usuario. Esto hace que los Puntos de Interés (POIs) parezcan más "anclados" al mundo real, mejorando significativamente la experiencia de usuario en la vista AR.

---

## Tabla de Contenidos

1. [Funcionamiento Técnico](#funcionamiento-técnico)
2. [Niveles de Estabilización](#niveles-de-estabilización)
3. [Configuración](#configuración)
4. [Ejemplos de Uso](#ejemplos-de-uso)
5. [Análisis de Rendimiento](#análisis-de-rendimiento)
6. [Casos de Uso Recomendados](#casos-de-uso-recomendados)
7. [Mejores Prácticas](#mejores-prácticas)
8. [Implementación Técnica](#implementación-técnica)
9. [Troubleshooting](#troubleshooting)
10. [Referencias Técnicas](#referencias-técnicas)

---

## Funcionamiento Técnico

### Implementación

La clase `VisualTracker` (en `lib/src/visual/visual_tracking.dart`) implementa esta funcionalidad:

1. **Lectura del Giroscopio**: Suscripción al stream `gyroscopeEventStream()` de `sensors_plus`
2. **Throttling Inteligente**: Procesa datos solo cada 50ms (20Hz) para optimizar CPU
3. **Cálculo de Offsets**: Aplica los valores del giroscopio a los POIs proyectados
4. **Factor de Decaimiento**: Los offsets decaen gradualmente (multiplicados por 0.94) para evitar deriva acumulativa

### Algoritmo

```dart
// Throttling inteligente: solo procesar cada 50ms
final now = DateTime.now().millisecondsSinceEpoch;
if (_lastUpdate != null && (now - _lastUpdate!) < throttleMs) {
  return; // Saltar este evento
}
_lastUpdate = now;

// Integración de datos del giroscopio
_offsetX += g.y * 0.02 * pixelPerRadian;
_offsetY += g.x * 0.02 * pixelPerRadian;

// Factor de decaimiento para evitar deriva
_offsetX *= 0.94;
_offsetY *= 0.94;
```

---

## Niveles de Estabilización

### VisualTrackingMode.off

- **Descripción**: Estabilización desactivada
- **Uso de Giroscopio**: ❌ No
- **Impacto en Batería**: Ninguno (modo más eficiente)
- **Uso Recomendado**: 
  - Dispositivos con batería baja
  - Cuando se prioriza máximo ahorro de energía
  - Aplicaciones que no requieren estabilización visual

### VisualTrackingMode.lite (Por Defecto)

- **Descripción**: Estabilización ligera con throttling
- **Uso de Giroscopio**: ✅ Sí (20Hz con throttling)
- **Impacto en Batería**: ~2-3% adicional
- **Uso Recomendado**:
  - Uso general de la aplicación (comportamiento por defecto)
  - Balance óptimo entre experiencia y eficiencia
  - Mayoría de casos de uso

---

## Configuración

### Parámetro en GeoArView

```dart
GeoArView(
  demPath: 'assets/data/dem/region.tif',
  poisPath: 'assets/data/pois/pois.json',
  visualStabilization: VisualTrackingMode.lite, // Por defecto
)
```

### Parámetros Disponibles

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `visualStabilization` | `VisualTrackingMode` | `lite` | Modo de estabilización visual |
| `lowPowerMode` | `bool` | `false` | Fuerza estabilización a OFF |

---

## Ejemplos de Uso

### Ejemplo 1: Uso por Defecto (Recomendado)

```dart
import 'package:flutter_geo_ar/flutter_geo_ar.dart';
import 'package:camera/camera.dart';

// La estabilización visual está activada por defecto en modo lite
GeoArView(
  camera: cameras.first,
  demPath: 'assets/data/dem/tenerife_cog.tif',
  poisPath: 'assets/data/pois/tenerife_pois.json',
  // visualStabilization: VisualTrackingMode.lite, // ← Por defecto
)
```

### Ejemplo 2: Desactivar Estabilización

Útil cuando se necesita máximo ahorro de batería:

```dart
GeoArView(
  camera: cameras.first,
  demPath: 'assets/data/dem/tenerife_cog.tif',
  poisPath: 'assets/data/pois/tenerife_pois.json',
  visualStabilization: VisualTrackingMode.off,
)
```

### Ejemplo 3: Modo de Bajo Consumo

El `lowPowerMode` desactiva automáticamente la estabilización:

```dart
GeoArView(
  camera: cameras.first,
  demPath: 'assets/data/dem/tenerife_cog.tif',
  poisPath: 'assets/data/pois/tenerife_pois.json',
  lowPowerMode: true, // Fuerza visualStabilization a off
)
```

### Ejemplo 4: Configuración Dinámica Basada en Batería

```dart
import 'package:battery_plus/battery_plus.dart';

class ArScreen extends StatefulWidget {
  @override
  _ArScreenState createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  final Battery _battery = Battery();
  VisualTrackingMode _stabilizationMode = VisualTrackingMode.lite;
  bool _lowPowerMode = false;

  @override
  void initState() {
    super.initState();
    _configurePowerSettings();
  }

  Future<void> _configurePowerSettings() async {
    final batteryLevel = await _battery.batteryLevel;
    
    setState(() {
      if (batteryLevel <= 20) {
        // Batería crítica: desactivar todo
        _lowPowerMode = true;
        _stabilizationMode = VisualTrackingMode.off;
      } else if (batteryLevel <= 40) {
        // Batería media: solo estabilización sin low power mode
        _lowPowerMode = false;
        _stabilizationMode = VisualTrackingMode.lite;
      } else {
        // Batería buena: todas las funciones activas
        _lowPowerMode = false;
        _stabilizationMode = VisualTrackingMode.lite;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GeoArView(
      camera: widget.camera,
      demPath: 'assets/data/dem/tenerife_cog.tif',
      poisPath: 'assets/data/pois/tenerife_pois.json',
      visualStabilization: _stabilizationMode,
      lowPowerMode: _lowPowerMode,
    );
  }
}
```

### Ejemplo 5: Settings de Usuario

Permitir al usuario controlar la estabilización:

```dart
import 'package:shared_preferences/shared_preferences.dart';

enum StabilizationPreference {
  auto,   // Decide basado en batería
  always, // Siempre lite
  never,  // Siempre off
}

class SettingsService {
  static const String _prefKey = 'stabilization_preference';

  // Guardar preferencia
  static Future<void> savePreference(StabilizationPreference pref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, pref.name);
  }

  // Cargar preferencia
  static Future<StabilizationPreference> loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final prefStr = prefs.getString(_prefKey);
    
    if (prefStr == null) return StabilizationPreference.auto;
    
    return StabilizationPreference.values.firstWhere(
      (e) => e.name == prefStr,
      orElse: () => StabilizationPreference.auto,
    );
  }

  // Obtener modo efectivo según preferencia
  static Future<VisualTrackingMode> getEffectiveMode() async {
    final pref = await loadPreference();
    
    switch (pref) {
      case StabilizationPreference.auto:
        final battery = Battery();
        final level = await battery.batteryLevel;
        return level < 20 
            ? VisualTrackingMode.off 
            : VisualTrackingMode.lite;
            
      case StabilizationPreference.always:
        return VisualTrackingMode.lite;
        
      case StabilizationPreference.never:
        return VisualTrackingMode.off;
    }
  }
}

// Uso en la aplicación
class ArScreen extends StatefulWidget {
  @override
  _ArScreenState createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  VisualTrackingMode _mode = VisualTrackingMode.lite;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = await SettingsService.getEffectiveMode();
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return GeoArView(
      camera: widget.camera,
      demPath: 'assets/data/dem/tenerife_cog.tif',
      poisPath: 'assets/data/pois/tenerife_pois.json',
      visualStabilization: _mode,
    );
  }
}
```

### Ejemplo 6: Monitorización de Batería en Tiempo Real

```dart
import 'dart:async';

class ArScreenWithBatteryMonitoring extends StatefulWidget {
  @override
  _ArScreenWithBatteryMonitoringState createState() => 
      _ArScreenWithBatteryMonitoringState();
}

class _ArScreenWithBatteryMonitoringState 
    extends State<ArScreenWithBatteryMonitoring> {
  final Battery _battery = Battery();
  late StreamSubscription<BatteryState> _batteryStateSubscription;
  
  bool _lowPowerMode = false;
  VisualTrackingMode _stabilizationMode = VisualTrackingMode.lite;
  int _currentBatteryLevel = 100;

  @override
  void initState() {
    super.initState();
    _initBatteryMonitoring();
  }

  Future<void> _initBatteryMonitoring() async {
    // Configuración inicial
    await _updatePowerSettings();
    
    // Monitorear cambios de estado de batería
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((_) {
      _updatePowerSettings();
    });
    
    // Actualizar cada 5 minutos
    Timer.periodic(Duration(minutes: 5), (_) {
      _updatePowerSettings();
    });
  }

  Future<void> _updatePowerSettings() async {
    final level = await _battery.batteryLevel;
    
    setState(() {
      _currentBatteryLevel = level;
      
      if (level <= 15) {
        _lowPowerMode = true;
        _stabilizationMode = VisualTrackingMode.off;
      } else if (level <= 30) {
        _lowPowerMode = false;
        _stabilizationMode = VisualTrackingMode.off;
      } else {
        _lowPowerMode = false;
        _stabilizationMode = VisualTrackingMode.lite;
      }
    });
  }

  @override
  void dispose() {
    _batteryStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GeoArView(
            camera: widget.camera,
            demPath: 'assets/data/dem/tenerife_cog.tif',
            poisPath: 'assets/data/pois/tenerife_pois.json',
            visualStabilization: _stabilizationMode,
            lowPowerMode: _lowPowerMode,
          ),
          
          // Indicador de batería
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentBatteryLevel <= 20 
                          ? Icons.battery_alert 
                          : Icons.battery_std,
                      color: _currentBatteryLevel <= 20 
                          ? Colors.red 
                          : Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '$_currentBatteryLevel%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    if (_lowPowerMode) ...[
                      SizedBox(width: 4),
                      Icon(
                        Icons.power_settings_new,
                        color: Colors.orange,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Interacción con lowPowerMode

⚠️ **IMPORTANTE**: Cuando `lowPowerMode` está activado, la estabilización visual se desactiva automáticamente **independientemente** del valor de `visualStabilization`.

```dart
GeoArView(
  demPath: 'assets/data/dem/region.tif',
  poisPath: 'assets/data/pois/pois.json',
  lowPowerMode: true, // Fuerza visualStabilization a off
  visualStabilization: VisualTrackingMode.lite, // Ignorado cuando lowPowerMode = true
)
```

Esto garantiza el máximo ahorro de batería en el modo de bajo consumo.

---

## Análisis de Rendimiento

### Consumo de CPU

| Modo | CPU Adicional | Descripción |
|------|---------------|-------------|
| off | 0% | Sin procesamiento de giroscopio |
| lite | ~1-2% | Throttling a 20Hz + cálculos de offset |

### Consumo de Batería

| Modo | Impacto en Batería | Detalles |
|------|-------------------|----------|
| off | 0% adicional | Giroscopio completamente desactivado |
| lite | ~2-3% adicional | Giroscopio activo pero con throttling eficiente |

### Optimizaciones Implementadas

1. **Throttling Manual**: Limita procesamiento a 20Hz (50ms entre lecturas)
   - Sin throttling: ~100Hz+ (frecuencia nativa del sensor)
   - Con throttling: 20Hz (80% menos procesamiento)

2. **Verificación Temporal**: 
   ```dart
   if (_lastUpdate != null && (now - _lastUpdate!) < 50) {
     return false; // Saltar este evento
   }
   ```

3. **Factor de Decaimiento**: Evita cálculos de reset complejos
   ```dart
   _offsetX *= 0.94; // Decae naturalmente hacia 0
   ```

---

## Casos de Uso Recomendados

### Usar VisualTrackingMode.lite

✅ **Recomendado para:**
- Uso general de senderismo y turismo
- Cuando la experiencia visual es importante
- Dispositivos con batería >30%
- Sesiones de uso típicas (<2 horas)
- Aplicación de senderismo con mejor experiencia
- Modo demo/presentación con máxima calidad visual

### Usar VisualTrackingMode.off

✅ **Recomendado para:**
- Sesiones de uso muy largas (>3 horas)
- Batería crítica (<20%)
- Dispositivos antiguos con bajo rendimiento
- Cuando se usa junto con otras funciones intensivas (grabación de tracks GPX)
- Testing y desarrollo donde se necesita comportamiento determinista
- Aplicaciones de emergencia donde se prioriza batería

---

## Mejores Prácticas

### 1. Configuración Dinámica Basada en Batería

```dart
// Obtener nivel de batería (usando battery_plus o similar)
final batteryLevel = await Battery().batteryLevel;

GeoArView(
  demPath: 'assets/data/dem/region.tif',
  poisPath: 'assets/data/pois/pois.json',
  visualStabilization: batteryLevel < 20 
    ? VisualTrackingMode.off 
    : VisualTrackingMode.lite,
)
```

### 2. Dar Control al Usuario

```dart
// En settings de la app
enum StabilizationPreference {
  auto, // Decide basado en batería
  always, // Siempre lite
  never, // Siempre off
}

// Implementación
VisualTrackingMode getStabilizationMode(
  StabilizationPreference pref,
  int batteryLevel,
) {
  switch (pref) {
    case StabilizationPreference.auto:
      return batteryLevel < 20 
        ? VisualTrackingMode.off 
        : VisualTrackingMode.lite;
    case StabilizationPreference.always:
      return VisualTrackingMode.lite;
    case StabilizationPreference.never:
      return VisualTrackingMode.off;
  }
}
```

### 3. Logging y Telemetría

```dart
// Útil para analizar uso real
debugPrint('🔧 Visual stabilization mode: ${widget.visualStabilization}');
if (widget.lowPowerMode) {
  debugPrint('⚡ Low power mode active - stabilization forced to OFF');
}
```

### 4. Notificar al Usuario de Cambios

```dart
void _notifyPowerModeChange(bool lowPower) {
  if (lowPower) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚡ Modo de bajo consumo activado\n'
          'Estabilización visual desactivada para ahorrar batería',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
```

---

## Implementación Técnica

### Archivos Modificados

#### 1. `lib/src/visual/visual_tracking.dart`

```dart
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// Modos de estabilización visual disponibles
enum VisualTrackingMode {
  /// Sin estabilización - Giroscopio desactivado (máximo ahorro de batería)
  off,

  /// Estabilización ligera con throttling a 20Hz (balance entre experiencia y eficiencia)
  lite,
}

/// Clase que maneja la estabilización visual usando el giroscopio del dispositivo
///
/// Características:
/// - Throttling inteligente a 20Hz (procesa datos cada 50ms)
/// - Factor de decaimiento (0.94) para evitar deriva acumulativa
/// - Impacto en batería: ~2-3% adicional en modo lite
class VisualTracker {
  final VisualTrackingMode mode;
  double _offsetX = 0.0, _offsetY = 0.0;
  StreamSubscription? _gyroSub;
  final double pixelPerRadian;

  // Variables para throttling inteligente (20Hz = 50ms entre lecturas)
  int? _lastUpdate;
  static const int throttleMs = 50;

  VisualTracker({
    this.mode = VisualTrackingMode.lite,
    this.pixelPerRadian = 500.0,
  });

  void start() {
    if (mode == VisualTrackingMode.lite) {
      print('[VisualTracker] 🎯 Iniciando estabilización visual en modo LITE (20Hz)');
      _gyroSub = gyroscopeEventStream().listen((g) {
        // Throttling inteligente: solo procesar cada 50ms
        final now = DateTime.now().millisecondsSinceEpoch;
        if (_lastUpdate != null && (now - _lastUpdate!) < throttleMs) {
          return; // Saltar este evento
        }
        _lastUpdate = now;

        // Integración de datos del giroscopio
        _offsetX += g.y * 0.02 * pixelPerRadian;
        _offsetY += g.x * 0.02 * pixelPerRadian;

        // Factor de decaimiento para evitar deriva
        _offsetX *= 0.94;
        _offsetY *= 0.94;
      });
    } else {
      print('[VisualTracker] ⚪ Estabilización visual desactivada');
    }
  }

  void stop() {
    print('[VisualTracker] 🛑 Deteniendo estabilización visual');
    _gyroSub?.cancel();
    _offsetX = 0.0;
    _offsetY = 0.0;
    _lastUpdate = null;
  }

  List<Map<String, dynamic>> applyOffset(List<Map<String, dynamic>> inPois) {
    if (mode == VisualTrackingMode.off) return inPois;
    for (var p in inPois) {
      p['x'] = (p['x'] as double) + _offsetX;
      p['y'] = (p['y'] as double) + _offsetY;
    }
    return inPois;
  }
}
```

#### 2. `lib/src/widgets/geo_ar_view.dart`

Nuevos parámetros agregados:

```dart
/// Modo de estabilización visual usando el giroscopio
/// - VisualTrackingMode.off: Sin estabilización (máximo ahorro de batería)
/// - VisualTrackingMode.lite: Estabilización ligera con throttling a 20Hz (por defecto)
final VisualTrackingMode visualStabilization;

/// Modo de bajo consumo de energía
/// Cuando está activado, desactiva automáticamente la estabilización visual
/// independientemente del valor de visualStabilization
final bool lowPowerMode;

const GeoArView({
  // ... otros parámetros
  this.visualStabilization = VisualTrackingMode.lite,
  this.lowPowerMode = false,
});
```

Lógica de inicialización:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  // Inicializar VisualTracker con configuración adecuada
  // lowPowerMode tiene prioridad y fuerza off independientemente de visualStabilization
  final effectiveMode = widget.lowPowerMode 
      ? VisualTrackingMode.off 
      : widget.visualStabilization;

  _tracker = VisualTracker(mode: effectiveMode);

  // Logging de configuración
  print('[GeoAR] 🔧 Configuración de estabilización visual:');
  print('[GeoAR]    - visualStabilization: ${widget.visualStabilization}');
  print('[GeoAR]    - lowPowerMode: ${widget.lowPowerMode}');
  print('[GeoAR]    - Modo efectivo: $effectiveMode');
  if (widget.lowPowerMode && widget.visualStabilization != VisualTrackingMode.off) {
    print('[GeoAR] ⚡ Modo de bajo consumo activo - estabilización forzada a OFF');
  }

  _initSystem();
}
```

### Verificación de Comportamiento

| Configuración | lowPowerMode | visualStabilization | Resultado Esperado |
|---------------|--------------|---------------------|-------------------|
| Por defecto | false | lite | Estabilización LITE |
| Bajo consumo | true | lite | Estabilización OFF |
| Sin estabilización | false | off | Estabilización OFF |
| Prioridad lowPower | true | off | Estabilización OFF |

---

## Troubleshooting

### La estabilización no funciona

1. Verificar que `visualStabilization` no sea `off`
2. Verificar que `lowPowerMode` no esté activado
3. Revisar logs en consola para mensajes de `[VisualTracker]`

**Solución:**
```dart
// Verificar configuración
print('Modo: ${widget.visualStabilization}');
print('Low Power: ${widget.lowPowerMode}');
```

### Consumo de batería alto

1. Activar `lowPowerMode: true`
2. Cambiar a `visualStabilization: VisualTrackingMode.off`
3. Implementar monitoreo de batería automático

**Solución:**
```dart
GeoArView(
  lowPowerMode: true,  // O
  visualStabilization: VisualTrackingMode.off,
)
```

### POIs siguen temblando

La estabilización reduce vibraciones, no las elimina completamente. Es normal ver pequeños movimientos, especialmente si:
- El usuario se mueve mucho
- Hay viento fuerte
- El dispositivo tiene sensores de baja calidad

**Nota**: La estabilización visual solo suaviza los micromovimientos, no afecta la precisión fundamental de la proyección 3D ni la calibración de la brújula.

---

## Preguntas Frecuentes

### ¿Por qué los POIs tiemblan sin estabilización?

Sin estabilización visual, los POIs reflejan directamente los movimientos de la mano del usuario. Aunque esto es técnicamente preciso, la experiencia es menos inmersiva porque rompe la ilusión de que los POIs están "anclados" en el mundo real.

### ¿Cuándo debería desactivar la estabilización?

- Batería crítica (<20%)
- Sesiones muy largas (>3 horas)
- Dispositivos antiguos donde cada % de CPU cuenta
- Cuando se combina con otras funciones intensivas

### ¿Puedo cambiar el modo en runtime?

Actualmente no. El `visualStabilization` se configura al crear el `GeoArView` y permanece constante durante la sesión. Para cambiar el modo, necesitas recrear el widget.

### ¿Afecta a la precisión de los POIs?

No. La estabilización solo suaviza los micromovimientos, pero no afecta la precisión fundamental de la proyección 3D ni la calibración de la brújula.

---

## Dependencias Necesarias

Para los ejemplos avanzados, agregar a `pubspec.yaml`:

```yaml
dependencies:
  battery_plus: ^6.0.0
  shared_preferences: ^2.2.0
```

---

## Referencias Técnicas

- **Archivo de Implementación**: `lib/src/visual/visual_tracking.dart`
- **Integración en GeoArView**: `lib/src/widgets/geo_ar_view.dart`
- **Sensores Utilizados**: `gyroscopeEventStream()` de `sensors_plus`
- **Export Principal**: `lib/flutter_geo_ar.dart`

---

## Historial de Cambios

### v0.0.2 (2025-01-27)
- ✅ Throttling inteligente a 20Hz implementado en `VisualTracker`
- ✅ Parámetro configurable `visualStabilization` en `GeoArView`
- ✅ Parámetro `lowPowerMode` en `GeoArView`
- ✅ Control independiente de `lowPowerMode` sobre estabilización
- ✅ Logging mejorado con emojis informativos
- ✅ Documentación completa del sistema
- ✅ Ejemplos prácticos de uso
- ✅ 80% reducción en procesamiento vs sin throttling

### v0.0.1 (2025-01-24)
- ✅ Implementación inicial de `VisualTracker`
- ✅ Modos básicos: `off` y `lite`

---

## Resumen de Implementación

### ✅ Características Completadas

- **Throttling inteligente**: Procesamiento limitado a 20Hz (50ms entre lecturas)
- **Modos configurables**: `off` y `lite`
- **Integración con lowPowerMode**: Prioridad absoluta del modo de bajo consumo
- **Logging completo**: Mensajes informativos en consola
- **Documentación exhaustiva**: Guías técnicas y ejemplos prácticos
- **Optimización de recursos**: 80% reducción en procesamiento
- **Balance configurable**: Entre experiencia de usuario y eficiencia energética

### 🎯 Impacto Esperado

#### Mejoras en Experiencia de Usuario
- 📱 POIs más estables y "anclados" al mundo real
- 🎯 Mejor inmersión en la experiencia AR
- 🔋 Control fino sobre consumo de batería

#### Optimización de Recursos
- ⚡ 80% reducción en procesamiento vs sin throttling
- 🔌 ~2-3% impacto adicional en batería (modo lite)
- 🎚️ Balance configurable entre experiencia y eficiencia
