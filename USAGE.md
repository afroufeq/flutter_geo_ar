# Guía de Uso - Flutter GeoAR

## Carga de Datos (DEMs y POIs)

El plugin `flutter_geo_ar` ahora permite que la aplicación que lo integra proporcione las rutas a los archivos de datos (DEMs y POIs) en lugar de incluirlos dentro del plugin.

### Configuración de Assets

1. **Coloca los archivos en tu app:**
   ```
   tu_app/
   ├── assets/
   │   └── data/
   │       ├── dem/
   │       │   ├── tenerife_cog.tif
   │       │   ├── gran_canaria_cog.tif
   │       │   └── ...
   │       └── pois/
   │           ├── tenerife_pois.json
   │           ├── gran_canaria_pois.json
   │           └── ...
   ```

2. **Declara los assets en `pubspec.yaml`:**
   ```yaml
   flutter:
     assets:
       - assets/data/dem/
       - assets/data/pois/
   ```

### Uso del Widget GeoArView

El widget `GeoArView` acepta los siguientes parámetros:

#### Parámetros Principales

- **`demPath`** (String?, opcional): Ruta al archivo DEM (Digital Elevation Model) en formato GeoTIFF
  - Ejemplo: `'assets/data/dem/tenerife_cog.tif'`

- **`poisPath`** (String?, opcional): Ruta al archivo JSON con los POIs
  - Ejemplo: `'assets/data/pois/tenerife_pois.json'`

- **`pois`** (List<Poi>, opcional): Lista de POIs definidos manualmente en código
  - Nota: Debes proporcionar POIs mediante `pois` o `poisPath` (al menos uno)

- **`camera`** (CameraDescription?, opcional): Cámara a utilizar

- **`focalLength`** (double, default: 500): Longitud focal para la proyección

### Ejemplos de Uso

#### Opción 1: Cargar desde Archivos

```dart
GeoArView(
  camera: camera,
  poisPath: 'assets/data/pois/tenerife_pois.json',
  demPath: 'assets/data/dem/tenerife_cog.tif',
  focalLength: 520,
)
```

#### Opción 2: POIs Manuales

```dart
final pois = [
  Poi(
    id: 'teide',
    name: 'Teide',
    lat: 28.2723,
    lon: -16.6425,
    elevation: 3718,
    importance: 5,
    category: 'natural',
    subtype: 'peak',
  ),
];

GeoArView(
  camera: camera,
  pois: pois,
  demPath: 'assets/data/dem/tenerife_cog.tif',
)
```

#### Opción 3: Solo POIs (sin DEM)

```dart
GeoArView(
  camera: camera,
  poisPath: 'assets/data/pois/tenerife_pois.json',
  // Sin demPath - funcionará pero sin oclusión de terreno
)
```

### Formato de Archivos POIs (JSON)

Los archivos JSON de POIs pueden tener dos formatos:

**Formato 1: Array directo**
```json
[
  {
    "id": "teide",
    "name": "Teide",
    "lat": 28.2723,
    "lon": -16.6425,
    "elevation": 3718,
    "importance": 5,
    "category": "natural",
    "subtype": "peak"
  }
]
```

**Formato 2: Objeto con array**
```json
{
  "pois": [
    {
      "id": "teide",
      "name": "Teide",
      "lat": 28.2723,
      "lon": -16.6425,
      "elevation": 3718,
      "importance": 5,
      "category": "natural",
      "subtype": "peak"
    }
  ]
}
```

### Cargar POIs Programáticamente

También puedes cargar POIs usando la clase `PoiLoader`:

```dart
import 'package:flutter_geo_ar/flutter_geo_ar.dart';

// Cargar POIs desde un archivo
final pois = await PoiLoader.loadFromAsset('assets/data/pois/tenerife_pois.json');

// Usar los POIs cargados
GeoArView(
  camera: camera,
  pois: pois,
  demPath: 'assets/data/dem/tenerife_cog.tif',
)
```

### Formato de Archivos DEM

Los archivos DEM deben estar en formato binario preprocesado con:
- Primeros 32 bytes: Metadatos (width, height, minLat, minLon, maxLat)
- Resto: Datos de elevación como Float32List

Consulta la documentación del plugin para más detalles sobre el preprocesamiento de archivos DEM.

### Ejemplo Completo

Ver `example/lib/main.dart` para un ejemplo completo de implementación.
