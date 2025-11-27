# Control de Densidad Visual y Filtrado de POIs

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Sistema de Control de Densidad Visual](#sistema-de-control-de-densidad-visual)
3. [Filtros de Visualización](#filtros-de-visualización)
4. [Modos de Declutter](#modos-de-declutter)
5. [Integración y Uso](#integración-y-uso)
6. [Casos de Uso](#casos-de-uso)
7. [Optimización y Rendimiento](#optimización-y-rendimiento)
8. [Referencia de API](#referencia-de-api)

---

## Introducción

El sistema de **Control de Densidad Visual** de `flutter_geo_ar` proporciona herramientas avanzadas para gestionar la cantidad y calidad de información mostrada en la vista AR. En lugar de obligar a los usuarios a configurar manualmente múltiples parámetros técnicos, el sistema ofrece tanto una interfaz simplificada (slider de densidad) como acceso granular a cada componente de filtrado.

### Componentes Principales

1. **VisualDensityController**: Gestiona el mapeo entre densidad (0.0-1.0) y parámetros técnicos
2. **VisualDensitySlider**: Widget UI para ajustar la densidad en tiempo real
3. **Filtros de distancia**: Control de `maxDistance` (hasta dónde se muestran POIs)
4. **Filtros de importancia**: Control de `minImportance` (qué POIs se muestran según relevancia)
5. **Sistema de Declutter**: Control de `declutterMode` (cómo se gestionan solapamientos)

---

## Sistema de Control de Densidad Visual

### ¿Qué es la Densidad Visual?

La densidad visual es un valor único (0.0-1.0) que controla intuitivamente tres parámetros técnicos:

- **maxDistance**: Distancia máxima para mostrar POIs
- **minImportance**: Nivel mínimo de importancia de POIs
- **declutterMode**: Agresividad del filtrado de solapamientos

### VisualDensityController

Clase que gestiona la lógica de mapeo entre el valor de densidad y los parámetros de visualización.

#### Características

- ✅ Mapeo automático de densidad a parámetros técnicos
- ✅ Notificación de cambios mediante `ChangeNotifier`
- ✅ Presets predefinidos para configuración rápida
- ✅ Callback opcional para recibir actualizaciones

#### Ejemplo Básico

```dart
// Crear controlador con densidad inicial normal
final controller = VisualDensityController(
  initialDensity: 0.5, // Vista equilibrada
  onDensityChanged: (density, maxDistance, minImportance, declutterMode) {
    print('Densidad: $density');
    print('Distancia máxima: ${maxDistance}m');
    print('Importancia mínima: $minImportance');
    print('Modo declutter: $declutterMode');
  },
);

// Cambiar densidad programáticamente
controller.setDensity(0.8); // Alta densidad

// Usar presets
controller.setPreset(VisualDensityPreset.minimal);
```

#### Mapeo de Parámetros

##### 1. maxDistance (Distancia Máxima)

Controla hasta qué distancia se muestran los POIs.

| Densidad | Distancia | Descripción |
|----------|-----------|-------------|
| 0.0 (mínima) | 5,000 m (5 km) | Solo POIs muy cercanos |
| 0.25 (baja) | 16,250 m (16.25 km) | POIs cercanos y algunos medios |
| 0.5 (normal) | 27,500 m (27.5 km) | Balance óptimo |
| 0.75 (alta) | 38,750 m (38.75 km) | POIs lejanos visibles |
| 1.0 (máxima) | 50,000 m (50 km) | Máximo alcance visual |

**Fórmula:** `maxDistance = 5000 + (density * 45000)`

##### 2. minImportance (Importancia Mínima)

Filtra POIs por su nivel de importancia (escala 1-10).

| Densidad | Importancia | POIs Mostrados |
|----------|-------------|----------------|
| 0.0 (mínima) | 10 | Solo POIs extremadamente importantes |
| 0.25 (baja) | 8 | POIs muy importantes |
| 0.5 (normal) | 5 | POIs moderadamente importantes y superiores |
| 0.75 (alta) | 3 | La mayoría de POIs |
| 1.0 (máxima) | 1 | Todos los POIs sin filtrar |

**Fórmula:** `minImportance = round(10 - (density * 9))`

##### 3. declutterMode (Modo Anti-solapamiento)

Controla el nivel de filtrado de etiquetas superpuestas.

| Densidad | Modo | Comportamiento |
|----------|------|----------------|
| 0.0 - 0.3 | `aggressive` | Mayor espaciado entre etiquetas |
| 0.3 - 0.7 | `normal` | Balance entre densidad y legibilidad |
| 0.7 - 0.9 | `light` | Permite solapamientos menores |
| 0.9 - 1.0 | `off` | Sin filtrado de solapamientos |

### VisualDensitySlider

Widget UI que proporciona una interfaz visual para ajustar la densidad en tiempo real.

#### Características

- 🎚️ Slider continuo de 0.0 a 1.0
- 🎯 Botones de preset para cambios rápidos
- 📊 Información detallada opcional de parámetros
- 🎨 Diseño compacto y semitransparente
- 🔄 Expandible/colapsable
- 🌐 Totalmente internacionalizado (ES/EN)

#### Ejemplo de Uso

```dart
Stack(
  children: [
    GeoArView(
      demPath: 'assets/data/dem/gran_canaria_cog.tif',
      poisPath: 'assets/data/pois/gran_canaria_pois.json',
      maxDistance: controller.maxDistance,
      minImportance: controller.minImportance,
      declutterMode: controller.declutterMode,
    ),
    VisualDensitySlider(
      controller: controller,
      showDetailedInfo: true, // Muestra parámetros resultantes
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.all(16.0),
    ),
  ],
)
```

### Presets Predefinidos

#### VisualDensityPreset.minimal (0.0)
**Vista limpia - Solo lo más importante y cercano**

| Parámetro | Valor |
|-----------|-------|
| maxDistance | 5 km |
| minImportance | 10 |
| declutterMode | aggressive |

**Ideal para:**
- Navegación enfocada
- Encontrar puntos específicos importantes
- Dispositivos con recursos limitados

**Ejemplo:** Ver solo picos principales cercanos durante una ascensión.

---

#### VisualDensityPreset.low (0.25)
**Vista baja - POIs importantes en rango medio**

| Parámetro | Valor |
|-----------|-------|
| maxDistance | 16.25 km |
| minImportance | 8 |
| declutterMode | aggressive |

**Ideal para:**
- Turismo urbano
- Exploración básica
- Conservación de batería

**Ejemplo:** Tour turístico mostrando monumentos principales de una ciudad.

---

#### VisualDensityPreset.normal (0.5) ⭐ RECOMENDADO
**Vista equilibrada - Balance óptimo**

| Parámetro | Valor |
|-----------|-------|
| maxDistance | 27.5 km |
| minImportance | 5 |
| declutterMode | normal |

**Ideal para:**
- Uso general
- Senderismo
- Exploración de paisajes
- Aplicaciones de turismo

**Ejemplo:** Ruta de senderismo mostrando picos, refugios y puntos de interés en el camino.

---

#### VisualDensityPreset.high (0.75)
**Vista alta - Muchos POIs visibles**

| Parámetro | Valor |
|-----------|-------|
| maxDistance | 38.75 km |
| minImportance | 3 |
| declutterMode | light |

**Ideal para:**
- Exploración detallada
- Fotografía de paisaje
- Planificación de rutas
- Análisis de terreno

**Ejemplo:** Planificar una ruta de varios días viendo todos los recursos disponibles.

---

#### VisualDensityPreset.maximum (1.0)
**Vista máxima - Toda la información disponible**

| Parámetro | Valor |
|-----------|-------|
| maxDistance | 50 km |
| minImportance | 1 |
| declutterMode | off |

**Ideal para:**
- Análisis exhaustivo
- Visualización de datos completa
- Debugging y desarrollo
- Estudios geoespaciales

**Ejemplo:** Análisis topográfico completo de una región para investigación.

---

## Filtros de Visualización

### Filtro de Distancia (`maxDistance`)

El filtro de distancia controla el radio máximo en el que se muestran los POIs.

#### Uso Directo

```dart
GeoArView(
  demPath: 'assets/data/dem/region.tif',
  poisPath: 'assets/data/pois/region.json',
  maxDistance: 15000.0, // 15 km
)
```

#### Rangos Recomendados

| Distancia | Uso Recomendado |
|-----------|-----------------|
| 5-10 km | Exploración local, navegación urbana |
| 10-20 km | Senderismo, turismo regional |
| 20-30 km | Exploración de montaña, vistas panorámicas |
| 30-50 km | Análisis geográfico, planificación de rutas largas |
| >50 km | Estudios topográficos, visualización científica |

### Filtro de Importancia (`minImportance`)

El filtro de importancia permite mostrar solo POIs que cumplan un nivel mínimo de relevancia.

#### Escala de Importancia

Los POIs tienen una importancia asignada en escala 1-10:

| Nivel | Descripción | Ejemplos |
|-------|-------------|----------|
| 10 | Extremadamente importante | Capitales, picos más altos, monumentos mundiales |
| 8-9 | Muy importante | Ciudades principales, picos destacados, monumentos nacionales |
| 6-7 | Importante | Pueblos, montañas notables, iglesias históricas |
| 4-5 | Moderadamente importante | Aldeas, colinas, ermitas, miradores |
| 2-3 | Poco importante | Caseríos, puntos menores, fuentes |
| 1 | Información general | Cualquier punto catalogado |

#### Uso Directo

```dart
GeoArView(
  demPath: 'assets/data/dem/region.tif',
  poisPath: 'assets/data/pois/region.json',
  minImportance: 7, // Solo POIs muy importantes
)
```

#### Estrategias de Filtrado

**Filtrado Conservador (minImportance: 8-10):**
- Solo puntos muy destacados
- Vista muy limpia
- Ideal para primeras impresiones y demos

**Filtrado Equilibrado (minImportance: 5-7):**
- Balance entre información y legibilidad
- Uso general y turismo
- Recomendado para la mayoría de casos

**Filtrado Permisivo (minImportance: 1-4):**
- Muestra la mayoría de puntos
- Análisis detallado
- Puede requerir declutter agresivo

---

## Modos de Declutter

El sistema de declutter controla cómo se manejan los solapamientos entre etiquetas de POIs en la vista AR. En lugar de un simple booleano on/off, se ofrece un control fino mediante el enum `DeclutterMode` con cuatro niveles de agresividad.

### DeclutterMode.off
**Sin decluttering - Muestra todos los POIs**

#### Comportamiento
Muestra todos los POIs sin evitar solapamientos entre etiquetas.

#### Uso Recomendado
- ✅ Visualización de datos completos para análisis
- ✅ Cuando se necesita ver absolutamente todos los POIs disponibles
- ✅ Debugging o desarrollo
- ✅ Estudios de densidad de puntos

#### Ventajas
- ✅ Muestra el 100% de los POIs disponibles
- ✅ Sin procesamiento adicional de filtrado
- ✅ Máximo rendimiento (sin overhead de cálculo)

#### Desventajas
- ⚠️ Puede resultar en pantalla muy saturada
- ⚠️ Etiquetas pueden superponerse y ser difíciles de leer
- ⚠️ Impacto visual negativo en zonas densas

#### Ejemplo de Uso

```dart
GeoArView(
  demPath: 'assets/data/dem/gran_canaria_cog.tif',
  poisPath: 'assets/data/pois/gran_canaria_pois.json',
  declutterMode: DeclutterMode.off, // Sin filtrado
  minImportance: 1, // Todos los POIs
)
```

---

### DeclutterMode.light
**Declutter ligero - Solo evita overlaps grandes (>80%)**

#### Comportamiento
Permite solapamientos menores entre etiquetas, pero evita que se cubran casi completamente.

#### Algoritmo
```dart
// Solo omite POIs si el solapamiento cubre más del 80% del área
return spatialIndex.hasLargeOverlap(rect, overlapThreshold: 0.8);
```

#### Uso Recomendado
- ✅ Áreas con alta densidad de POIs (>500 POIs)
- ✅ Cuando se quiere maximizar la información visible
- ✅ Zonas urbanas densas o rutas de senderismo con muchos puntos
- ✅ Combinado con minImportance medio-alto

#### Ventajas
- ✅ Muestra más POIs que el modo normal (~80-90% de POIs visibles)
- ✅ Mantiene legibilidad básica
- ✅ Buen balance entre densidad y usabilidad
- ✅ Overhead mínimo de procesamiento

#### Desventajas
- ⚠️ Puede haber solapamientos menores visibles
- ⚠️ No tan "limpio" visualmente como los modos normal o aggressive

#### Ejemplo de Uso

```dart
GeoArView(
  demPath: 'assets/data/dem/gran_canaria_cog.tif',
  poisPath: 'assets/data/pois/gran_canaria_pois.json',
  declutterMode: DeclutterMode.light,
  maxDistance: 30000.0, // 30 km
  minImportance: 4, // POIs con algo de importancia
)
```

---

### DeclutterMode.normal ⭐ (Default)
**Declutter normal - Evita cualquier overlap**

#### Comportamiento
Comportamiento por defecto. Evita cualquier solapamiento entre etiquetas, garantizando que todas las etiquetas visibles sean completamente legibles.

#### Algoritmo
```dart
// Evita cualquier solapamiento, incluso mínimo
return spatialIndex.overlapsAny(rect);
```

#### Uso Recomendado
- ✅ Uso general
- ✅ Balance óptimo entre densidad de información y legibilidad
- ✅ Aplicaciones de turismo y exploración
- ✅ Senderismo y actividades outdoor
- ✅ **Configuración por defecto recomendada**

#### Ventajas
- ✅ Etiquetas completamente legibles (~60-70% de POIs visibles)
- ✅ Aspecto visual limpio y profesional
- ✅ Buen rendimiento
- ✅ Balance ideal para la mayoría de casos

#### Desventajas
- ⚠️ Puede ocultar algunos POIs en zonas muy densas

#### Ejemplo de Uso

```dart
GeoArView(
  demPath: 'assets/data/dem/gran_canaria_cog.tif',
  poisPath: 'assets/data/pois/gran_canaria_pois.json',
  declutterMode: DeclutterMode.normal, // Default (puede omitirse)
)
```

---

### DeclutterMode.aggressive
**Declutter agresivo - Mayor spacing**

#### Comportamiento
Evita cualquier overlap con un margen de seguridad adicional del 20%, creando un espaciado generoso entre etiquetas.

#### Algoritmo
```dart
// Expande el rectángulo un 20% y luego verifica overlap
final expandedRect = rect.inflate(rect.width * 0.1);
return spatialIndex.overlapsAny(expandedRect);
```

#### Uso Recomendado
- ✅ Presentaciones o demos
- ✅ Aplicaciones donde la claridad es prioritaria sobre la cantidad
- ✅ Dispositivos con pantallas pequeñas
- ✅ Usuarios con dificultades visuales
- ✅ Screenshots y material promocional

#### Ventajas
- ✅ Máxima legibilidad (~40-50% de POIs visibles)
- ✅ Aspecto visual más espaciado y "limpio"
- ✅ Ideal para screenshots y presentaciones
- ✅ Excelente experiencia en pantallas pequeñas

#### Desventajas
- ⚠️ Muestra menos POIs que otros modos
- ⚠️ Puede parecer "vacío" en zonas con pocos POIs

#### Ejemplo de Uso

```dart
GeoArView(
  demPath: 'assets/data/dem/gran_canaria_cog.tif',
  poisPath: 'assets/data/pois/gran_canaria_pois.json',
  declutterMode: DeclutterMode.aggressive,
  minImportance: 7, // Solo POIs importantes
)
```

---

### Comparación de Modos de Declutter

| Modo | POIs Visibles | Legibilidad | Rendimiento | Caso de Uso Principal |
|------|---------------|-------------|-------------|----------------------|
| **off** | 100% | ⭐ | ⭐⭐⭐⭐⭐ | Análisis de datos, debugging |
| **light** | ~80-90% | ⭐⭐⭐ | ⭐⭐⭐⭐ | Áreas densas (>500 POIs) |
| **normal** ⭐ | ~60-70% | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Uso general (default) |
| **aggressive** | ~40-50% | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Presentaciones, claridad máxima |

### Implementación Técnica del Declutter

El sistema de declutter utiliza un **Spatial Index** basado en grid para detección eficiente de solapamientos con complejidad O(n) en lugar de O(n²).

#### Características del Spatial Index

- 📦 Grid espacial para detección rápida de vecinos
- ⚡ Complejidad O(n) vs O(n²) de algoritmo naive
- 🎯 Detección precisa de overlaps rectangulares
- 💾 ~2-3 KB de memoria adicional para el grid
- 🚀 < 1ms de overhead por frame con 500 POIs

#### Proceso de Filtrado

```
1. POI es proyectado a pantalla → genera rectángulo de etiqueta
2. Verificar con Spatial Index si solapamiento:
   - off: Nunca omitir → mostrar siempre
   - light: Omitir solo si overlap > 80%
   - normal: Omitir si hay cualquier overlap
   - aggressive: Expandir rectángulo +20% y verificar overlap
3. Si no hay solapamiento → agregar al Spatial Index y mostrar
4. Si hay solapamiento → omitir POI (no se muestra)
```

---

## Integración y Uso

### Enfoque Simplificado: VisualDensityController

Recomendado para la mayoría de aplicaciones.

```dart
class MyArView extends StatefulWidget {
  @override
  State<MyArView> createState() => _MyArViewState();
}

class _MyArViewState extends State<MyArView> {
  final _densityController = VisualDensityController(
    initialDensity: 0.5, // Normal
  );
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Vista AR con parámetros del controlador
        GeoArView(
          demPath: 'assets/data/dem/region.tif',
          poisPath: 'assets/data/pois/region.json',
          maxDistance: _densityController.maxDistance,
          minImportance: _densityController.minImportance,
          declutterMode: _densityController.declutterMode,
        ),
        
        // Slider de densidad
        VisualDensitySlider(
          controller: _densityController,
          showDetailedInfo: true,
          alignment: Alignment.bottomCenter,
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _densityController.dispose();
    super.dispose();
  }
}
```

### Enfoque Granular: Control Directo

Para casos donde se necesita control fino de cada parámetro.

```dart
class CustomArView extends StatefulWidget {
  @override
  State<CustomArView> createState() => _CustomArViewState();
}

class _CustomArViewState extends State<CustomArView> {
  double _maxDistance = 20000.0;
  int _minImportance = 5;
  DeclutterMode _declutterMode = DeclutterMode.normal;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controles personalizados
        Row(
          children: [
            Text('Distancia: ${(_maxDistance / 1000).toStringAsFixed(1)} km'),
            Slider(
              value: _maxDistance,
              min: 5000,
              max: 50000,
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
          ],
        ),
        
        Row(
          children: [
            Text('Importancia mínima: $_minImportance'),
            Slider(
              value: _minImportance.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _minImportance = v.round()),
            ),
          ],
        ),
        
        SegmentedButton<DeclutterMode>(
          segments: [
            ButtonSegment(value: DeclutterMode.off, label: Text('Off')),
            ButtonSegment(value: DeclutterMode.light, label: Text('Light')),
            ButtonSegment(value: DeclutterMode.normal, label: Text('Normal')),
            ButtonSegment(value: DeclutterMode.aggressive, label: Text('Aggressive')),
          ],
          selected: {_declutterMode},
          onSelectionChanged: (modes) {
            setState(() => _declutterMode = modes.first);
          },
        ),
        
        // Vista AR
        Expanded(
          child: GeoArView(
            demPath: 'assets/data/dem/region.tif',
            poisPath: 'assets/data/pois/region.json',
            maxDistance: _maxDistance,
            minImportance: _minImportance,
            declutterMode: _declutterMode,
          ),
        ),
      ],
    );
  }
}
```

### Combinación de Filtros

Los filtros trabajan en conjunto de forma secuencial:

```
1. Filtro de Distancia (maxDistance)
   ↓ (POIs dentro del radio)
2. Filtro de Importancia (minImportance)
   ↓ (POIs suficientemente importantes)
3. Filtro de Visibilidad (detrás del usuario, bajo horizonte)
   ↓ (POIs visibles en el campo de visión)
4. Declutter (declutterMode)
   ↓ (POIs sin solapamiento de etiquetas)
5. POIs finales mostrados en pantalla
```

#### Ejemplo de Combinación Estratégica

```dart
// CASO 1: Exploración amplia con alta densidad
GeoArView(
  maxDistance: 40000.0,      // 40 km de alcance
  minImportance: 3,          // POIs con algo de importancia
  declutterMode: DeclutterMode.light, // Permite más densidad
)

// CASO 2: Vista limpia de puntos importantes
GeoArView(
  maxDistance: 15000.0,      // 15 km cercano
  minImportance: 8,          // Solo muy importantes
  declutterMode: DeclutterMode.aggressive, // Máxima claridad
)

// CASO 3: Análisis exhaustivo
GeoArView(
  maxDistance: 50000.0,      // Máximo alcance
  minImportance: 1,          // Todos los POIs
  declutterMode: DeclutterMode.off, // Sin filtrado
)
```

---

## Casos de Uso

### 1. Aplicación de Turismo

**Objetivo:** Mostrar monumentos y puntos de interés turístico de forma clara y atractiva.

```dart
final controller = VisualDensityController(
  initialDensity: 0.25, // Vista baja
);

GeoArView(
  demPath: 'assets/data/dem/ciudad.tif',
  poisPath: 'assets/data/pois/monumentos.json',
  maxDistance: controller.maxDistance,      // ~16 km
  minImportance: controller.minImportance,  // 8 (muy importantes)
  declutterMode: controller.declutterMode,  // aggressive
)
```

**Resultado:**
- ✅ Solo monumentos principales y destacados
- ✅ Vista muy limpia para screenshots
- ✅ Fácil navegación para turistas
- ✅ Excelente primera impresión

---

### 2. Aplicación de Senderismo

**Objetivo:** Balance entre información útil y legibilidad durante la ruta.

```dart
final controller = VisualDensityController(
  initialDensity: 0.5, // Vista normal
);

GeoArView(
  demPath: 'assets/data/dem/sierra.tif',
  poisPath: 'assets/data/pois/montana.json',
  maxDistance: controller.maxDistance,      // ~27.5 km
  minImportance: controller.minImportance,  // 5 (moderados)
  declutterMode: controller.declutterMode,  // normal
)
```

**Resultado:**
- ✅ Picos, refugios, fuentes visibles
- ✅ Información suficiente para planificar
- ✅ Legible durante la actividad
- ✅ Balance óptimo información/claridad

---

### 3. Herramienta de Análisis Geoespacial

**Objetivo:** Ver absolutamente todos los datos disponibles para estudios.

```dart
final controller = VisualDensityController(
  initialDensity: 1.0, // Vista máxima
);

GeoArView(
  demPath: 'assets/data/dem/region.tif',
  poisPath: 'assets/data/pois/completo.json',
  maxDistance: controller.maxDistance,      // 50 km
  minImportance: controller.minImportance,  // 1 (todos)
  declutterMode: controller.declutterMode,  // off
)
```

**Resultado:**
- ✅ 100% de POIs visibles
- ✅ Sin filtrado, datos completos
- ✅ Ideal para análisis exhaustivo
- ⚠️ Puede estar saturado visualmente

---

### 4. App para Pantallas Pequeñas

**Objetivo:** Máxima legibilidad en dispositivos con pantalla pequeña.

```dart
final controller = VisualDensityController(
  initialDensity: 0.0, // Vista mínima
);

GeoArView(
  demPath: 'assets/data/dem/region.tif',
  poisPath: 'assets/data/pois/region.json',
  maxDistance: controller.maxDistance,      // 5 km
  minImportance: controller.minImportance,  // 10 (extremos)
  declutterMode: controller.declutterMode,  // aggressive
)
```

**Resultado:**
- ✅ Solo POIs más importantes y cercanos
- ✅ Etiquetas grandes y legibles
- ✅ Perfecta para pantallas pequeñas
- ✅ Ahorro de batería

---

### 5. Configuración Previa con Preview

Permitir al usuario configurar antes de abrir la vista AR.

```dart
class ConfigScreen extends StatefulWidget {
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _controller = VisualDensityController(initialDensity: 0.5);
  
  void _openArView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GeoArView(
          demPath: 'assets/data/dem/region.tif',
          poisPath: 'assets/data/pois/region.json',
          maxDistance: _controller.maxDistance,
          minImportance: _controller.minImportance,
          declutterMode: _controller.declutterMode,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configuración')),
      body: Column(
        children: [
          // Preview de parámetros
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Card(
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración actual:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text('Distancia máxima: ${(_controller.maxDistance / 1000).toStringAsFixed(1)} km'),
                      Text('Importancia mínima: ${_controller.minImportance}'),
                      Text('Modo declutter: ${_controller.declutterMode}'),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Slider de densidad
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Densidad Visual'),
                Slider(
                  value: _controller.density,
                  onChanged: (v) => _controller.setDensity(v),
                ),
              ],
            ),
          ),
          
          // Botones de presets
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _controller.setPreset(VisualDensityPreset.minimal),
                child: Text('Mínima'),
              ),
              ElevatedButton(
                onPressed: () => _controller.setPreset(VisualDensityPreset.normal),
                child: Text('Normal'),
              ),
              ElevatedButton(
                onPressed: () => _controller.setPreset(VisualDensityPreset.maximum),
                child: Text('Máxima'),
              ),
            ],
          ),
          
          Spacer(),
          
          // Botón para abrir vista AR
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _openArView,
              child: Text('Abrir Vista AR'),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Resultado:**
- ✅ Usuario configura antes de abrir AR
- ✅ Preview de parámetros resultantes
- ✅ Acceso rápido a presets
- ✅ Mejor experiencia de usuario

---

### 6. Ajuste Dinámico Durante Uso

Permitir cambios en tiempo real mientras se usa la vista AR.

```dart
class DynamicArView extends StatefulWidget {
  @override
  State<DynamicArView> createState() => _DynamicArViewState();
}

class _DynamicArViewState extends State<DynamicArView> {
  final _controller = VisualDensityController(initialDensity: 0.5);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Vista AR que se actualiza automáticamente
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return GeoArView(
              demPath: 'assets/data/dem/region.tif',
              poisPath: 'assets/data/pois/region.json',
              maxDistance: _controller.maxDistance,
              minImportance: _controller.minImportance,
              declutterMode: _controller.declutterMode,
            );
          },
        ),
        
        // Slider flotante
        VisualDensitySlider(
          controller: _controller,
          showDetailedInfo: true,
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Resultado:**
- ✅ Cambios en tiempo real sin reiniciar
- ✅ Feedback inmediato del efecto
- ✅ Experimentación fluida del usuario
- ✅ Adaptación dinámica a condiciones

---

## Optimización y Rendimiento

### Impacto en Rendimiento por Densidad

| Densidad | POIs Procesados | Tiempo Proyección | Tiempo Declutter | FPS Esperado |
|----------|-----------------|-------------------|------------------|--------------|
| **Mínima (0.0)** | ~50-200 | <1ms | <0.5ms | 60 FPS |
| **Baja (0.25)** | ~100-300 | ~1ms | ~0.5ms | 60 FPS |
| **Normal (0.5)** | ~200-500 | ~2ms | ~1ms | 60 FPS |
| **Alta (0.75)** | ~500-1000 | ~3ms | ~1.5ms | 55-60 FPS |
| **Máxima (1.0)** | ~1000-2000+ | ~5ms | ~2ms | 50-55 FPS |

### Sistema de Cache

El sistema implementa un cache inteligente para evitar reprocesar proyecciones cuando el usuario está quieto.

#### Criterios de Cache

```dart
// Cache válido si:
- Movimiento < 2 metros (~0.00002° de lat/lon)
- Rotación < 2° de heading

// Beneficios:
- Reduce procesamiento en ~70-80% cuando usuario quieto
- Mantiene 60 FPS con alta densidad
- Ahorro significativo de batería
```

### Optimizaciones del Spatial Index

El sistema de declutter usa un spatial index optimizado:

```
Complejidad sin Spatial Index: O(n²)
- Con 500 POIs: ~250,000 comparaciones
- Tiempo: ~10-15ms por frame

Complejidad con Spatial Index: O(n)
- Con 500 POIs: ~2,000 comparaciones
- Tiempo: <1ms por frame

Mejora: 10-15x más rápido
```

### Recomendaciones por Dispositivo

#### Dispositivos Antiguos (< 2GB RAM)
```dart
controller.setPreset(VisualDensityPreset.minimal); // o low
// Resultado: 50-200 POIs, 60 FPS estable
```

#### Dispositivos de Gama Media (2-4GB RAM)
```dart
controller.setPreset(VisualDensityPreset.normal);
// Resultado: 200-500 POIs, 60 FPS
```

#### Dispositivos de Alta Gama (>4GB RAM)
```dart
controller.setPreset(VisualDensityPreset.high); // o maximum
// Resultado: 500-2000 POIs, 55-60 FPS
```

### Modo de Bajo Consumo

Para maximizar duración de batería:

```dart
GeoArView(
  demPath: 'assets/data/dem/region.tif',
  poisPath: 'assets/data/pois/region.json',
  maxDistance: 10000.0,           // Reducir alcance
  minImportance: 8,                // Solo muy importantes
  declutterMode: DeclutterMode.aggressive, // Menos POIs finales
  lowPowerMode: true,              // Desactiva estabilización visual
  visualStabilization: VisualTrackingMode.off,
)
```

**Ahorro estimado:** 30-40% de consumo de CPU

---

## Referencia de API

### GeoArView Parámetros Relacionados

```dart
GeoArView({
  // Filtros de visualización
  double maxDistance = 20000.0,        // Distancia máxima en metros
  int minImportance = 5,               // Importancia mínima (1-10)
  DeclutterMode declutterMode = DeclutterMode.normal,
  
  // Otros parámetros...
  String? demPath,
  String? poisPath,
  List<Poi> pois = const [],
  bool showHorizon = true,
  bool debugMode = false,
  bool showDebugOverlay = false,
  // ...
})
```

### VisualDensityController API

#### Constructor

```dart
VisualDensityController({
  double initialDensity = 0.5,
  DensityChangedCallback? onDensityChanged,
})
```

#### Propiedades

| Propiedad | Tipo | Descripción |
|-----------|------|-------------|
| `density` | `double` | Densidad actual (0.0-1.0) |
| `maxDistance` | `double` | Distancia máxima calculada (metros) |
| `minImportance` | `int` | Importancia mínima calculada (1-10) |
| `declutterMode` | `DeclutterMode` | Modo de declutter calculado |

#### Métodos

| Método | Descripción |
|--------|-------------|
| `setDensity(double value)` | Establece densidad (0.0-1.0) |
| `setPreset(VisualDensityPreset preset)` | Aplica preset predefinido |
| `dispose()` | Libera recursos del controlador |

#### Callback

```dart
typedef DensityChangedCallback = void Function(
  double density,
  double maxDistance,
  int minImportance,
  DeclutterMode declutterMode,
);
```

### VisualDensitySlider API

#### Constructor

```dart
VisualDensitySlider({
  required VisualDensityController controller,
  bool showDetailedInfo = false,
  Alignment alignment = Alignment.bottomCenter,
  EdgeInsets padding = const EdgeInsets.all(16.0),
})
```

#### Parámetros

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `controller` | `VisualDensityController` | requerido | Controlador de densidad |
| `showDetailedInfo` | `bool` | `false` | Muestra parámetros técnicos |
| `alignment` | `Alignment` | `bottomCenter` | Posición en pantalla |
| `padding` | `EdgeInsets` | `all(16.0)` | Padding alrededor |

### DeclutterMode Enum

```dart
enum DeclutterMode {
  off,        // Sin filtrado de overlaps
  light,      // Solo overlaps grandes (>80%)
  normal,     // Cualquier overlap (default)
  aggressive, // Con margen extra del 20%
}
```

### VisualDensityPreset Enum

```dart
enum VisualDensityPreset {
  minimal,  // 0.0 - Vista muy limpia
  low,      // 0.25 - Vista baja
  normal,   // 0.5 - Vista equilibrada (default)
  high,     // 0.75 - Vista alta
  maximum,  // 1.0 - Vista completa
}
```

---

## Internacionalización

El sistema está completamente internacionalizado usando **slang** con soporte para:

- 🇪🇸 **Español (es)** - Idioma base
- 🇬🇧 **English (en)**

### Configuración del Idioma

```dart
// En GeoArView
GeoArView(
  language: 'es', // o 'en'
  // ...
)

// Globalmente
LocaleSettings.setLocale(AppLocale.en);
```

### Textos del Sistema

Los textos se encuentran en:
- `assets/translations/strings.i18n.json` (español)
- `assets/translations/strings_en.i18n.json` (inglés)

```json
"visualDensity": {
  "title": "Densidad Visual",
  "description": "Ajusta la cantidad de información visible",
  "minimal": "Mínima",
  "low": "Baja",
  "normal": "Normal",
  "high": "Alta",
  "maximum": "Máxima",
  "hint": "Desliza para ajustar cuántos POIs se muestran",
  "settings": {
    "maxDistance": "Distancia máxima",
    "minImportance": "Importancia mínima",
    "declutterMode": "Modo anti-solapamiento"
  }
}
```

---

## Ventajas del Sistema

### 1. Usabilidad Mejorada
- ✅ **Simplicidad**: Un único control en lugar de tres parámetros técnicos
- ✅ **Intuitividad**: Términos comprensibles (mínima, normal, máxima)
- ✅ **Previsualización**: Usuario ve parámetros resultantes en tiempo real
- ✅ **Presets**: Configuraciones rápidas predefinidas

### 2. Flexibilidad
- ✅ **Configuración previa**: Ajustar antes de abrir vista AR
- ✅ **Ajuste dinámico**: Cambiar durante el uso de la vista AR
- ✅ **Control granular**: Acceso directo a cada parámetro si es necesario
- ✅ **Callbacks**: Notificaciones de cambios para lógica personalizada

### 3. Consistencia
- ✅ **Mapeo coherente**: Los parámetros cambian de forma lógica y predecible
- ✅ **Rangos optimizados**: Valores basados en casos de uso reales
- ✅ **Retroalimentación**: Usuario siempre sabe qué parámetros está usando
- ✅ **Documentación**: Sistema bien documentado y ejemplos claros

### 4. Rendimiento
- ✅ **Cache inteligente**: Evita reprocesar cuando usuario quieto
- ✅ **Spatial Index**: Algoritmo O(n) para declutter
- ✅ **Bajo overhead**: <1ms adicional por frame
- ✅ **Adaptativo**: Se ajusta según capacidades del dispositivo

---

## Ejemplo Completo Funcional

Ver `example/lib/visual_density_example.dart` para un ejemplo completo que incluye:

- ✅ Configuración previa con preview
- ✅ Vista AR con slider integrado
- ✅ Información de parámetros en tiempo real
- ✅ Uso de presets
- ✅ Gestión de permisos
- ✅ Múltiples modos de uso

```dart
import 'package:flutter/material.dart';
import 'package:flutter_geo_ar/flutter_geo_ar.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VisualDensityExample(),
    );
  }
}

class VisualDensityExample extends StatefulWidget {
  @override
  State<VisualDensityExample> createState() => _VisualDensityExampleState();
}

class _VisualDensityExampleState extends State<VisualDensityExample> {
  final _controller = VisualDensityController(
    initialDensity: 0.5,
    onDensityChanged: (density, distance, importance, mode) {
      print('Densidad cambiada: $density');
    },
  );
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return GeoArView(
                demPath: 'assets/data/dem/gran_canaria_cog.tif',
                poisPath: 'assets/data/pois/gran_canaria_pois.json',
                maxDistance: _controller.maxDistance,
                minImportance: _controller.minImportance,
                declutterMode: _controller.declutterMode,
                showDebugOverlay: true,
              );
            },
          ),
          VisualDensitySlider(
            controller: _controller,
            showDetailedInfo: true,
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## Referencias

### Código Fuente

- [VisualDensityController](../lib/src/widgets/visual_density_controller.dart)
- [VisualDensitySlider](../lib/src/widgets/visual_density_slider.dart)
- [DeclutterMode](../lib/src/poi/declutter_mode.dart)
- [Spatial Index](../lib/src/utils/spatial_index.dart)
- [POI Painter](../lib/src/poi/poi_painter.dart)
- [GeoArView](../lib/src/widgets/geo_ar_view.dart)

### Documentación Relacionada

- [DEBUG_OVERLAY.md](./DEBUG_OVERLAY.md) - Sistema de debug y métricas
- [VISUAL_STABILIZATION.md](./VISUAL_STABILIZATION.md) - Estabilización visual

### Ejemplos

- [visual_density_example.dart](../example/lib/visual_density_example.dart)

---

## Conclusión

El sistema de Control de Densidad Visual mejora drásticamente la experiencia del usuario al:

1. **Simplificar** la configuración compleja en un único control intuitivo
2. **Proporcionar** feedback visual inmediato de los cambios
3. **Permitir** ajustes tanto previos como dinámicos durante el uso
4. **Mantener** coherencia y previsibilidad en el comportamiento
5. **Optimizar** el rendimiento mediante cache y algoritmos eficientes

Es especialmente útil en aplicaciones donde los usuarios no técnicos necesitan controlar la cantidad de información mostrada sin entender los detalles de implementación, mientras que los desarrolladores mantienen acceso completo a cada parámetro individual cuando lo necesitan.

El sistema está diseñado para ser:
- 🎯 **Intuitivo** para usuarios finales
- 🔧 **Flexible** para desarrolladores
- ⚡ **Eficiente** en rendimiento
- 📱 **Adaptable** a diferentes dispositivos
- 🌐 **Internacional** con soporte multiidioma
