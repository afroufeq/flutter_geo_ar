# 📍 Scripts de POIs para flutter_geo_ar

Este directorio contiene scripts para convertir POIs desde diferentes formatos al formato JSON optimizado del plugin `flutter_geo_ar`.

## 📋 Índice

- [Conversión de POIs](#conversión-de-pois)
- [Formatos Soportados](#formatos-soportados)
- [Ejemplos de Uso](#ejemplos-de-uso)
- [Fuentes de POIs](#fuentes-de-pois)
- [Formato de Salida](#formato-de-salida)

---

## Conversión de POIs

### Instalación de Dependencias

El script principal `convert_pois.py` solo requiere Python 3.6+ con las bibliotecas estándar. No necesita dependencias adicionales.

```bash
# Verificar versión de Python
python3 --version

# El script está listo para usar
```

### Uso de Entorno Virtual (Recomendado en macOS)

Aunque este script no requiere dependencias externas, es una buena práctica usar entornos virtuales en Python para aislar proyectos y evitar conflictos.

#### ¿Por qué usar un entorno virtual?

- Aísla las dependencias del proyecto del sistema
- Previene conflictos entre versiones de paquetes
- Facilita la gestión de dependencias
- Permite trabajar en múltiples proyectos sin interferencias

#### Crear un entorno virtual en macOS

```bash
# Navega al directorio del proyecto
cd /ruta/a/flutter_geo_ar

# Crea el entorno virtual (solo una vez)
python3 -m venv venv

# O con un nombre personalizado
python3 -m venv .venv
```

#### Activar el entorno virtual

```bash
# Activar el entorno virtual
source venv/bin/activate

# Tu prompt debería cambiar a mostrar (venv)
# (venv) usuario@mac flutter_geo_ar %
```

#### Usar el script dentro del entorno virtual

```bash
# Una vez activado el entorno virtual, usa el script normalmente
python scripts/convert_pois.py input.geojson output.json

# Nota: Dentro del entorno virtual puedes usar 'python' en lugar de 'python3'
```

#### Desactivar el entorno virtual

```bash
# Cuando termines de trabajar
deactivate

# Tu prompt volverá a la normalidad
```

#### Comando completo (flujo típico)

```bash
# 1. Crear entorno (solo la primera vez)
python3 -m venv venv

# 2. Activar entorno
source venv/bin/activate

# 3. Usar el script
python scripts/convert_pois.py tenerife.geojson output/tenerife_pois.json

# 4. Desactivar cuando termines
deactivate
```

#### Agregar al .gitignore

Si usas Git, añade el entorno virtual al `.gitignore`:

```bash
# Añadir al .gitignore
echo "venv/" >> .gitignore
echo ".venv/" >> .gitignore
```

#### Notas adicionales

- **macOS con Homebrew Python**: Si instalaste Python con Homebrew, el comando `python3` funciona perfectamente.
- **Permisos de ejecución**: Si marcaste el script como ejecutable (`chmod +x`), puedes ejecutarlo directamente: `./scripts/convert_pois.py input.geojson output.json`
- **Dependencias futuras**: Si en el futuro se añaden dependencias externas, podrás instalarlas dentro del entorno virtual con: `pip install -r requirements.txt`

### Uso Básico

```bash
python3 scripts/convert_pois.py <archivo_entrada> <archivo_salida> [opciones]
```

#### Parámetros:

- `archivo_entrada`: Archivo de POIs en formato GeoJSON, KML, CSV o GPX
- `archivo_salida`: Archivo JSON de salida (formato optimizado del plugin)
- `--min-importance N`: (Opcional) Filtrar POIs con importancia mínima N (1-10)

---

## Formatos Soportados

### 1. GeoJSON (.geojson, .json)

**Formato estándar RFC 7946 para datos geoespaciales**

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [-16.6429, 28.2723, 3718.0]
      },
      "properties": {
        "id": "poi_001",
        "name": "Pico del Teide",
        "category": "natural:peak",
        "importance": 10
      }
    }
  ]
}
```

**Campos reconocidos en properties:**
- `name` o `title`: Nombre del POI (requerido)
- `id`: Identificador único (opcional, se autogenera)
- `category` o `type`: Categoría del POI
- `subtype`: Subcategoría
- `importance`: Importancia 1-10 (se infiere si no existe)

### 2. KML (.kml)

**Formato de Google Earth**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>Pico del Teide</name>
      <description>Volcán más alto de España</description>
      <Point>
        <coordinates>-16.6429,28.2723,3718.0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>
```

**Notas:**
- Solo se procesan elementos `Placemark` con `Point`
- La categoría se infiere del nombre, descripción y styleUrl
- Las coordenadas están en formato lon,lat,elevation

### 3. CSV (.csv, .txt)

**Formato de texto plano separado por comas**

#### Con encabezado:

```csv
lat,lon,name,elevation,category,importance
28.2723,-16.6429,Pico del Teide,3718.0,natural:peak,10
28.0997,-16.8831,Mirador de La Fortaleza,1243.0,tourism:viewpoint,7
```

#### Sin encabezado (orden estándar):

```csv
28.2723,-16.6429,Pico del Teide,3718.0,natural:peak,10
28.0997,-16.8831,Mirador de La Fortaleza,1243.0,tourism:viewpoint,7
```

**Columnas reconocidas en encabezado:**
- `lat`, `latitude`, `Lat`: Latitud (requerido)
- `lon`, `longitude`, `lng`, `Lon`: Longitud (requerido)
- `name`, `nombre`, `title`, `Name`: Nombre del POI (requerido)
- `elevation`, `alt`, `altitude`: Elevación en metros (opcional)
- `category`, `type`, `Category`: Categoría (opcional)
- `importance`, `Importance`: Importancia 1-10 (opcional)

### 4. GPX (.gpx)

**Formato de waypoints GPS**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <wpt lat="28.2723" lon="-16.6429">
    <ele>3718.0</ele>
    <name>Pico del Teide</name>
    <desc>Volcán más alto de España</desc>
    <type>natural:peak</type>
  </wpt>
</gpx>
```

**Notas:**
- Solo se procesan waypoints (`wpt`)
- Los tracks y rutas se ignoran
- La categoría se infiere del tipo, nombre y descripción

---

## Ejemplos de Uso

### Ejemplo 1: Convertir GeoJSON

```bash
python3 scripts/convert_pois.py pois_tenerife.geojson output/tenerife_pois.json
```

**Salida:**
```
📍 Parseando GeoJSON: pois_tenerife.geojson
✅ 150 POIs parseados desde GeoJSON
💾 Guardando 150 POIs en: output/tenerife_pois.json
✅ POIs guardados exitosamente

🎉 Conversión completada exitosamente!
📊 Total de POIs: 150
```

### Ejemplo 2: Convertir KML con filtro de importancia

```bash
python3 scripts/convert_pois.py miradores.kml output/miradores_importantes.json --min-importance 7
```

**Salida:**
```
📍 Parseando KML: miradores.kml
✅ 45 POIs parseados desde KML
🔍 Filtrados 20 POIs por importancia mínima 7
💾 Guardando 25 POIs en: output/miradores_importantes.json
✅ POIs guardados exitosamente

🎉 Conversión completada exitosamente!
📊 Total de POIs: 25
```

### Ejemplo 3: Convertir CSV simple

```bash
python3 scripts/convert_pois.py puntos.csv output/puntos.json
```

### Ejemplo 4: Convertir waypoints GPX

```bash
python3 scripts/convert_pois.py ruta_senderismo.gpx output/waypoints.json
```

---

## Fuentes de POIs

### 1. OpenStreetMap (Overpass API)

**La fuente más completa de datos geográficos**

#### Usar Overpass Turbo (Recomendado)

1. Visita https://overpass-turbo.eu/
2. Ingresa una consulta para tu área de interés
3. Ejecuta la consulta
4. Exporta como GeoJSON

**Ejemplo de consulta para picos en Tenerife:**

```overpass
[out:json];
(
  node["natural"="peak"](28.0,-16.9,28.6,-16.1);
  node["tourism"="viewpoint"](28.0,-16.9,28.6,-16.1);
);
out body;
```

**Luego convertir:**

```bash
python3 scripts/convert_pois.py tenerife_osm.geojson output/tenerife_pois.json
```

#### Categorías útiles de OpenStreetMap:

- `natural=peak`: Picos y cumbres
- `tourism=viewpoint`: Miradores
- `tourism=attraction`: Atracciones turísticas
- `amenity=shelter`: Refugios
- `amenity=restaurant`: Restaurantes
- `historic=monument`: Monumentos
- `natural=beach`: Playas

### 2. Google Earth / Google Maps

**Exportar desde Google Earth:**

1. Abre Google Earth Pro
2. Crea o importa tus puntos de interés
3. Click derecho en la carpeta → "Guardar lugar como..."
4. Selecciona formato KML
5. Guarda el archivo

**Convertir:**

```bash
python3 scripts/convert_pois.py mis_lugares.kml output/lugares.json
```

### 3. Wikiloc (Rutas y Waypoints)

**Descargar tracks GPX de Wikiloc:**

1. Busca una ruta en https://www.wikiloc.com/
2. Descarga el archivo GPX
3. Extrae los waypoints

```bash
python3 scripts/convert_pois.py ruta_wikiloc.gpx output/waypoints.json
```

### 4. Natural Earth Data

**Datos geográficos mundiales:**

1. Visita https://www.naturalearthdata.com/
2. Descarga datasets (ciudades, montañas, etc.)
3. Convierte el shapefile a GeoJSON con GDAL:

```bash
ogr2ogr -f GeoJSON ciudades.geojson ne_10m_populated_places.shp
python3 scripts/convert_pois.py ciudades.geojson output/ciudades.json
```

### 5. GeoNames

**Base de datos geográfica mundial:**

1. Visita http://www.geonames.org/
2. Busca y descarga datos (formato TXT)
3. Convierte a CSV con las columnas apropiadas
4. Usa el script de conversión

### 6. Datos Abiertos Gubernamentales

**Muchos gobiernos publican datasets:**

- **España**: https://datos.gob.es/
- **Canarias**: https://opendata.sitcan.es/
- **Europa**: https://data.europa.eu/

Busca datasets de puntos de interés, monumentos, miradores, etc.

### 7. Crear tus propios POIs

#### Opción A: Usar GeoJSON.io

1. Visita http://geojson.io/
2. Crea puntos manualmente en el mapa
3. Agrega propiedades en el panel derecho
4. Guarda como GeoJSON
5. Convierte con el script

#### Opción B: Crear CSV en Excel/Google Sheets

1. Crea una hoja de cálculo con columnas: lat, lon, name, elevation, category, importance
2. Rellena los datos
3. Exporta como CSV
4. Convierte con el script

```bash
python3 scripts/convert_pois.py mis_pois.csv output/pois.json
```

---

## Formato de Salida

El script genera un archivo JSON optimizado para el plugin:

```json
[
  {
    "id": "poi_001",
    "name": "Pico del Teide",
    "lat": 28.2723,
    "lon": -16.6429,
    "elevation": 3718.0,
    "importance": 10,
    "category": "natural:peak",
    "subtype": "volcano"
  },
  {
    "id": "poi_002",
    "name": "Mirador de La Fortaleza",
    "lat": 28.0997,
    "lon": -16.8831,
    "elevation": 1243.0,
    "importance": 7,
    "category": "tourism:viewpoint",
    "subtype": "default"
  }
]
```

### Uso en Flutter:

```dart
import 'package:flutter_geo_ar/flutter_geo_ar.dart';

GeoArView(
  demPath: 'assets/data/dem/region_cog.tif',
  poisPath: 'assets/data/pois/tenerife_pois.json', // ← Tu archivo convertido
)
```

---

## Categorías y su Importancia

El script asigna automáticamente importancia basada en la categoría:

| Categoría | Importancia | Descripción |
|-----------|-------------|-------------|
| `natural:peak` | 8 | Picos y cumbres |
| `tourism:viewpoint` | 7 | Miradores |
| `tourism:city` | 6 | Ciudades |
| `amenity:shelter` | 5 | Refugios |
| `tourism:village` | 4 | Pueblos |
| `generic` | 1 | Por defecto |

Puedes ajustar manualmente la importancia editando el JSON de salida o usando el parámetro `--min-importance` para filtrar.

---

## Conversión con GDAL (Avanzado)

Si tienes GDAL instalado, puedes convertir entre formatos antes de usar el script:

### Instalar GDAL:

```bash
# macOS
brew install gdal

# Ubuntu/Debian
sudo apt install gdal-bin

# Windows
# Descargar desde https://gdal.org/
```

### Ejemplos de conversión con GDAL:

```bash
# Shapefile a GeoJSON
ogr2ogr -f GeoJSON output.geojson input.shp

# KML a GeoJSON
ogr2ogr -f GeoJSON output.geojson input.kml

# GeoJSON a KML
ogr2ogr -f KML output.kml input.geojson

# GPX waypoints a GeoJSON
ogr2ogr -f GeoJSON output.geojson input.gpx waypoints
```

---

## Solución de Problemas

### Error: "El archivo no existe"

```bash
# Verifica que la ruta es correcta
ls -la input.geojson

# Usa rutas absolutas si es necesario
python3 scripts/convert_pois.py /ruta/completa/input.geojson output.json
```

### Error: "GeoJSON inválido"

```bash
# Valida tu GeoJSON
cat input.geojson | python3 -m json.tool

# O usa geojsonhint si está instalado
npm install -g @mapbox/geojsonhint
geojsonhint input.geojson
```

### Error: "No se encontraron POIs"

- Verifica que el archivo contiene POIs (puntos)
- En GeoJSON, asegúrate que son Features con geometría type="Point"
- En KML, verifica que hay Placemarks con elementos Point
- En GPX, asegúrate que hay waypoints (`<wpt>`)

### Encoding de caracteres

Si tienes problemas con caracteres especiales (acentos, ñ, etc.):

```bash
# Convierte el archivo a UTF-8
iconv -f ISO-8859-1 -t UTF-8 input.csv > input_utf8.csv
python3 scripts/convert_pois.py input_utf8.csv output.json
```

---

## Contribuir

Si encuentras un bug o quieres mejorar el script:

1. Reporta el issue en GitHub
2. Fork el proyecto
3. Crea un pull request con tus mejoras

---

## Licencia

Este script es parte del plugin `flutter_geo_ar` y está bajo la misma licencia.

---

¿Tienes preguntas? Abre un issue en [GitHub](https://github.com/afroufeq/flutter_geo_ar/issues).
