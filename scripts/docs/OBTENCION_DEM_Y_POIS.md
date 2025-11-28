# Guía Completa: Obtención de Archivos DEM y POIs

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [¿Por qué son necesarios estos archivos?](#por-qué-son-necesarios-estos-archivos)
3. [Archivos DEM (Digital Elevation Model)](#archivos-dem-digital-elevation-model)
   - [¿Qué es un DEM?](#qué-es-un-dem)
   - [Fuentes de Descarga](#fuentes-de-descarga-de-dem)
   - [Descarga y Procesamiento](#descarga-y-procesamiento)
   - [Conversión a COG](#conversión-a-cog)
4. [Archivos POIs (Points of Interest)](#archivos-pois-points-of-interest)
   - [¿Qué son los POIs?](#qué-son-los-pois)
   - [Obtención desde OpenStreetMap](#obtención-desde-openstreetmap)
   - [Procesamiento de POIs](#procesamiento-de-pois)
   - [POIs Personalizados](#pois-personalizados)
5. [Scripts Incluidos](#scripts-incluidos)
6. [Workflow Completo](#workflow-completo)
7. [Troubleshooting](#troubleshooting)

---

## Introducción

Este documento explica cómo obtener y preparar los dos tipos de archivos **fundamentales** para el funcionamiento del plugin `flutter_geo_ar`:

- **Archivos DEM** (.tif): Modelos de elevación del terreno
- **Archivos POIs** (.json): Puntos de interés georreferenciados

⚠️ **IMPORTANTE**: El plugin **NO funcionará correctamente** sin estos archivos. Son necesarios para:
- Calcular la altitud de POIs y del usuario
- Proyectar correctamente los POIs en pantalla según el terreno
- Mostrar información relevante al usuario

---

## ¿Por qué son necesarios estos archivos?

### Sin DEM

```
❌ Problemas:
- POIs flotan en el aire o se hunden bajo tierra
- Información de desnivel incorrecta
- Proyección 3D imprecisa
- Overlay de senderismo no funciona
```

### Sin POIs

```
❌ Problemas:
- Pantalla AR vacía (no hay nada que mostrar)
- Sin información de montañas, picos, monumentos
- La funcionalidad AR no tiene sentido
```

### Con ambos archivos

```
✅ Funcionalidad completa:
- POIs correctamente posicionados en 3D
- Información precisa de altitudes y distancias
- Cálculo correcto de desniveles
- Experiencia AR completa y útil
```

---

## Archivos DEM (Digital Elevation Model)

### ¿Qué es un DEM?

Un **DEM** (Modelo Digital de Elevación) es un archivo ráster que contiene datos de altitud del terreno. Cada píxel representa la elevación en metros sobre el nivel del mar para una coordenada geográfica específica.

**Ejemplo visual:**
```
Coordenadas → Altitud
28.123°N, -16.456°W → 1250m
28.124°N, -16.456°W → 1255m
28.125°N, -16.456°W → 1260m
...
```

### Formato Requerido

- **Formato**: GeoTIFF (preferiblemente COG - Cloud Optimized GeoTIFF)
- **Proyección**: WGS84 (EPSG:4326)
- **Tipo de datos**: Float32 o Int16
- **Compresión**: DEFLATE (recomendado) o LZW
- **Resolución recomendada**: ≤30 metros/píxel

### Fuentes de Descarga de DEM

#### 1. **Copernicus Digital Elevation Model (Recomendado)**

**Resolución**: 30 metros (GLO-30) | **Cobertura**: Global | **Calidad**: Excelente

📍 **URL**: https://copernicus-dem-30m.s3.amazonaws.com/

**Ventajas:**
- ✅ Resolución de 30m (suficiente para la mayoría de casos)
- ✅ Cobertura global completa
- ✅ Datos recientes (2021)
- ✅ Acceso gratuito sin registro
- ✅ Formato COG nativo (optimizado)

**Cómo descargar:**

```bash
# Ejemplo: Descargar tile para Tenerife
# Formato: Copernicus_DSM_COG_10_{LATITUD_NORTE}{LONGITUD}_00_{LATITUD_SUR}{LONGITUD}_00_DEM.tif

# Tile N28W017 (cubre parte de Tenerife)
wget https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_N28_00_W017_00_DEM/Copernicus_DSM_COG_10_N28_00_W017_00_DEM.tif

# Tile N28W016 (cubre otra parte de Tenerife)
wget https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_N28_00_W016_00_DEM/Copernicus_DSM_COG_10_N28_00_W016_00_DEM.tif
```

**Encontrar tu tile:**
1. Ir a https://portal.opentopography.org/raster?opentopoID=OTSDEM.032021.4326.3
2. Hacer clic en tu región de interés
3. Copiar las coordenadas de la tile
4. Construir la URL según el formato

**Alternativa con script:**

```bash
#!/bin/bash
# download_copernicus_dem.sh

REGION_NAME="tenerife"
MIN_LAT=28
MAX_LAT=29
MIN_LON=-17
MAX_LON=-16

mkdir -p dem_tiles

for lat in $(seq $MIN_LAT $MAX_LAT); do
  for lon in $(seq $MIN_LON $MAX_LON); do
    # Convertir a formato de tile
    lat_str=$(printf "N%02d" $lat)
    lon_abs=$(echo $lon | tr -d -)
    lon_str=$(printf "W%03d" $lon_abs)
    
    url="https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_${lat_str}_00_${lon_str}_00_DEM/Copernicus_DSM_COG_10_${lat_str}_00_${lon_str}_00_DEM.tif"
    
    echo "Descargando tile ${lat_str}${lon_str}..."
    wget -q -O "dem_tiles/${REGION_NAME}_${lat_str}${lon_str}.tif" "$url"
  done
done

echo "✅ Descarga completa"
```

#### 2. **SRTM (Shuttle Radar Topography Mission)**

**Resolución**: 30 metros (SRTM1) o 90 metros (SRTM3) | **Cobertura**: 60°N - 56°S

📍 **URL**: https://dwtkns.com/srtm30m/

**Ventajas:**
- ✅ Buena cobertura entre latitudes 60°N y 56°S
- ✅ Interfaz web fácil de usar
- ✅ Descarga por tiles individuales

**Desventajas:**
- ❌ No cubre latitudes extremas (>60°N o <56°S)
- ❌ Datos de 2000 (más antiguos que Copernicus)

**Cómo descargar:**
1. Visitar https://dwtkns.com/srtm30m/
2. Hacer clic en la región de interés en el mapa
3. Descargar el archivo .hgt
4. Convertir a GeoTIFF (ver sección de procesamiento)

#### 3. **ALOS World 3D (AW3D30)**

**Resolución**: 30 metros | **Cobertura**: Global

📍 **URL**: https://www.eorc.jaxa.jp/ALOS/en/aw3d30/

**Ventajas:**
- ✅ Excelente calidad en zonas montañosas
- ✅ Resolución de 30m

**Desventajas:**
- ❌ Requiere registro gratuito
- ❌ Interfaz menos intuitiva

#### 4. **ASTER GDEM**

**Resolución**: 30 metros | **Cobertura**: 83°N - 83°S

📍 **URL**: https://asterweb.jpl.nasa.gov/gdem.asp

**Ventajas:**
- ✅ Buena cobertura global
- ✅ Gratuito

**Desventajas:**
- ❌ Calidad inferior a Copernicus y ALOS
- ❌ Artefactos en algunas regiones

---

### Descarga y Procesamiento

#### Opción 1: Usando el script fetch_dem.sh (Manual)

El script `scripts/fetch_dem.sh` es un **placeholder** que requiere configuración:

```bash
#!/bin/bash
# scripts/fetch_dem.sh
# Este script debe ser personalizado con tus fuentes de datos

set -e
DATA_DIR="assets/data/dem"
mkdir -p "$DATA_DIR"

echo "==> Descargando DEM para tu región..."

# EJEMPLO: Descargar de Copernicus
# Reemplaza con tus coordenadas
REGION="gran_canaria"
TILE_URL="https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_N28_00_W016_00_DEM/Copernicus_DSM_COG_10_N28_00_W016_00_DEM.tif"

wget -O "$DATA_DIR/${REGION}_raw.tif" "$TILE_URL"

echo "✅ DEM descargado: $DATA_DIR/${REGION}_raw.tif"
echo "⚠️  Recuerda optimizar con: scripts/preprocess_dem.sh"
```

**Uso:**
```bash
# 1. Editar el script con tus URLs
nano scripts/fetch_dem.sh

# 2. Ejecutar
chmod +x scripts/fetch_dem.sh
./scripts/fetch_dem.sh
```

#### Opción 2: Descarga Manual (Recomendado)

Para **mayor control y flexibilidad**:

```bash
# 1. Crear directorio
mkdir -p assets/data/dem

# 2. Descargar tu región desde Copernicus
# Ejemplo: Isla de Tenerife
wget -O assets/data/dem/tenerife_raw.tif \
  "https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_N28_00_W017_00_DEM/Copernicus_DSM_COG_10_N28_00_W017_00_DEM.tif"

# 3. Si necesitas múltiples tiles, combínalos con GDAL
gdal_merge.py -o assets/data/dem/tenerife_merged.tif \
  tile1.tif tile2.tif tile3.tif

# 4. Recortar al área exacta de interés (opcional)
gdal_translate -projwin <xmin> <ymax> <xmax> <ymin> \
  assets/data/dem/tenerife_merged.tif \
  assets/data/dem/tenerife_cropped.tif
```

---

### Conversión a COG

Una vez descargado el DEM, **es imperativo** convertirlo a formato COG para rendimiento óptimo.

#### ¿Por qué COG?

- ✅ **Acceso aleatorio rápido**: Lee solo los datos necesarios
- ✅ **Tiles internos**: Optimizado para lecturas por bloques
- ✅ **Overviews**: Permite zoom rápido
- ✅ **Compresión**: Reduce tamaño sin pérdida de precisión

#### 📚 Tutorial Completo de Conversión

**🎯 RECOMENDADO**: Para un tutorial paso a paso detallado con ejemplos para SRTM, Copernicus, ASTER y ALOS, consulta:

👉 **[Tutorial Completo: Conversión de GeoTIFF a COG](TUTORIAL_CONVERSION_GEOTIFF.md)**

El tutorial incluye:
- ✅ Instalación de GDAL para todas las plataformas
- ✅ Ejemplos prácticos con capturas de las 4 fuentes principales
- ✅ Troubleshooting detallado
- ✅ Optimizaciones avanzadas
- ✅ Preguntas frecuentes

#### Scripts de Conversión

El plugin incluye **dos scripts** para conversión:

**1. Script mejorado con validación (RECOMENDADO):**

```bash
# convert_dem_to_cog.sh - Script con validación completa
# - Verifica GDAL instalado
# - Valida archivo de entrada
# - Reproyecta automáticamente a WGS84
# - Optimiza según tamaño
# - Muestra estadísticas detalladas

chmod +x scripts/convert_dem_to_cog.sh
./scripts/convert_dem_to_cog.sh input.tif output_cog.tif
```

**2. Script simple:**

```bash
# preprocess_dem.sh - Script básico sin validación
chmod +x scripts/preprocess_dem.sh
./scripts/preprocess_dem.sh input.tif output_cog.tif
```

#### Uso Rápido (Script Mejorado)

```bash
# 1. Asegurarte de tener GDAL instalado
# macOS:
brew install gdal

# Linux (Ubuntu/Debian):
sudo apt-get install gdal-bin

# Windows: Ver tutorial completo

# 2. Convertir con el script mejorado
./scripts/convert_dem_to_cog.sh \
  assets/data/dem/tenerife_raw.tif \
  assets/data/dem/tenerife_cog.tif

# El script automáticamente:
# - Valida el archivo de entrada
# - Reproyecta a WGS84 si es necesario
# - Optimiza compresión según tamaño
# - Muestra estadísticas del terreno
```

#### Ejemplo de Salida del Script Mejorado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🗺️  CONVERSIÓN DEM A COG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Entrada:      tenerife_raw.tif
📁 Salida:       tenerife_cog.tif
📊 Tamaño:       45M
📐 Dimensiones:  3601, 3601
🌍 Proyección:   4326

✅ Conversión completada en 8s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 RESULTADOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Archivo generado: tenerife_cog.tif
📊 Tamaño original:  45M
📊 Tamaño COG:       13M
📉 Ratio compresión: 3.5x

🏔️  Altitud mínima:  0m
⛰️  Altitud máxima:  3718m
📊 Altitud media:    856m
```

#### Verificación de Calidad

```bash
# Verificar que es un COG válido
gdalinfo assets/data/dem/tenerife_cog.tif | grep -i "driver\|layout"

# Debería mostrar:
# Driver: COG/Cloud Optimized GeoTIFF
# LAYOUT=COG
```

---

## Archivos POIs (Points of Interest)

### ¿Qué son los POIs?

Los **POIs** (Points of Interest) son puntos georreferenciados que representan lugares de interés: montañas, monumentos, miradores, iglesias, etc.

### Formato JSON Requerido

```json
[
  {
    "id": "unique_identifier",
    "name": "Nombre del POI",
    "lat": 28.123456,
    "lon": -16.654321,
    "elevation": 1200.5,
    "category": "natural",
    "subtype": "peak",
    "importance": 5,
    "type": "mountain"
  }
]
```

**Campos obligatorios:**
- `id`: Identificador único (string)
- `name`: Nombre descriptivo (string)
- `lat`: Latitud (float, WGS84)
- `lon`: Longitud (float, WGS84)

**Campos opcionales pero recomendados:**
- `elevation`: Altitud en metros (float) - si no se proporciona, se obtiene del DEM
- `category`: Categoría general (string): "natural", "tourism", "historic", etc.
- `subtype`: Subtipo específico (string): "peak", "viewpoint", "monument", etc.
- `importance`: Relevancia para decluttering (int, 1-10)
- `type`: Alias de category para compatibilidad

---

### Obtención desde OpenStreetMap

#### Script: fetch_pois_overpass.py

El plugin incluye un script para descargar POIs desde OpenStreetMap/Overpass API:

```python
#!/usr/bin/env python3
# scripts/fetch_pois_overpass.py

import requests
import json
import argparse

def fetch(bbox, out):
    minLon, minLat, maxLon, maxLat = map(str.strip, bbox.split(","))
    
    # Query Overpass para picos y montañas
    query = f"""[out:json][timeout:25];
    (
      node["natural"="peak"]({minLat},{minLon},{maxLat},{maxLon});
      node["natural"="volcano"]({minLat},{minLon},{maxLat},{maxLon});
      node["tourism"="viewpoint"]({minLat},{minLon},{maxLat},{maxLon});
    );
    out;"""
    
    r = requests.post("https://overpass-api.de/api/interpreter", 
                      data={'data': query})
    data = r.json()
    
    pois = []
    for el in data.get('elements', []):
        pois.append({
            'id': str(el.get('id')),
            'name': el.get('tags', {}).get('name', 'Unknown'),
            'lat': el.get('lat'),
            'lon': el.get('lon'),
            'category': 'natural',
            'subtype': el.get('tags', {}).get('natural', 'peak'),
            'importance': 3 if 'volcano' in el.get('tags', {}).values() else 1
        })
    
    with open(out, 'w') as f:
        json.dump(pois, f, indent=2)
    
    print(f"✅ {len(pois)} POIs descargados a {out}")

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--bbox', required=True,
                   help='Bounding box: minLon,minLat,maxLon,maxLat')
    p.add_argument('--out', required=True,
                   help='Archivo JSON de salida')
    args = p.parse_args()
    fetch(args.bbox, args.out)
```

**Uso básico:**

```bash
# 1. Instalar dependencias
pip3 install requests

# 2. Encontrar tu bounding box
# Ir a https://boundingbox.klokantech.com/
# Seleccionar tu región
# Copiar coordenadas en formato: CSV

# 3. Descargar POIs
python3 scripts/fetch_pois_overpass.py \
  --bbox="-16.95,28.0,-16.1,28.6" \
  --out="assets/data/pois/tenerife_pois_raw.json"
```

#### Personalizar la Query

Para obtener diferentes tipos de POIs, modifica la query:

```python
# POIs turísticos
query = f"""[out:json][timeout:25];
(
  node["tourism"="museum"]({minLat},{minLon},{maxLat},{maxLon});
  node["tourism"="attraction"]({minLat},{minLon},{maxLat},{maxLon});
  node["historic"]({minLat},{minLon},{maxLat},{maxLon});
);
out;"""

# POIs urbanos
query = f"""[out:json][timeout:25];
(
  node["amenity"="restaurant"]({minLat},{minLon},{maxLat},{maxLon});
  node["amenity"="cafe"]({minLat},{minLon},{maxLat},{maxLon});
  node["shop"]({minLat},{minLon},{maxLat},{maxLon});
);
out;"""

# Combinar múltiples tipos
query = f"""[out:json][timeout:25];
(
  node["natural"="peak"]({minLat},{minLon},{maxLat},{maxLon});
  node["tourism"="viewpoint"]({minLat},{minLon},{maxLat},{maxLon});
  node["historic"="monument"]({minLat},{minLon},{maxLat},{maxLon});
  node["amenity"="place_of_worship"]({minLat},{minLon},{maxLat},{maxLon});
);
out;"""
```

---

### Procesamiento de POIs

#### Script: preprocess_pois.py

Convierte el JSON de Overpass a formato optimizado:

```python
#!/usr/bin/env python3
# scripts/preprocess_pois.py

import json
import sys

def convert(input_file, output_file):
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: Fichero {input_file} no encontrado.")
        sys.exit(1)

    out_pois = []
    # Overpass devuelve lista directa o objeto con 'elements'
    elements = data.get('elements', data) if isinstance(data, dict) else data
    
    for el in elements:
        # Ignorar nodos sin geometría
        if 'lat' not in el or 'lon' not in el:
            continue

        tags = el.get('tags', {})
        
        # Detectar tipo y categoría
        category = tags.get('natural', 
                   tags.get('tourism', 
                   tags.get('amenity',
                   tags.get('historic', 'generic'))))
        
        subtype = tags.get('peak', 
                  tags.get('viewpoint', 'default'))
        
        # Calcular importancia basada en etiquetas
        importance = 1
        if 'peak' in str(tags.values()).lower():
            importance = 3
        if 'volcano' in str(tags.values()).lower():
            importance = 5
        if tags.get('wikipedia') or tags.get('wikidata'):
            importance += 2  # POIs con Wikipedia son más importantes

        poi = {
            'id': str(el.get('id')),
            'name': tags.get('name', tags.get('ref', 'Desconocido')),
            'lat': el.get('lat'),
            'lon': el.get('lon'),
            'elevation': tags.get('ele'),  # Puede ser None
            'category': category,
            'subtype': subtype,
            'importance': min(importance, 10),  # Máximo 10
            'type': category  # Alias para compatibilidad
        }
        
        # Añadir campos opcionales si existen
        if tags.get('wikipedia'):
            poi['wikipedia'] = tags['wikipedia']
        if tags.get('website'):
            poi['website'] = tags['website']
            
        out_pois.append(poi)

    # Ordenar por importancia (descendente)
    out_pois.sort(key=lambda x: x['importance'], reverse=True)

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(out_pois, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Procesados {len(out_pois)} POIs. Guardado en {output_file}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python3 preprocess_pois.py <input.json> <output.json>")
        sys.exit(1)
    
    convert(sys.argv[1], sys.argv[2])
```

**Uso:**

```bash
# Procesar POIs descargados de Overpass
python3 scripts/preprocess_pois.py \
  assets/data/pois/tenerife_pois_raw.json \
  assets/data/pois/tenerife_pois.json

# Verificar resultado
cat assets/data/pois/tenerife_pois.json | jq '. | length'
# Debería mostrar el número de POIs
```

---

### POIs Personalizados

Puedes añadir tus propios POIs manualmente editando el archivo JSON:

#### Método 1: Edición Directa

```json
[
  {
    "id": "custom_001",
    "name": "Mi Mirador Favorito",
    "lat": 28.123456,
    "lon": -16.654321,
    "elevation": 850.0,
    "category": "tourism",
    "subtype": "viewpoint",
    "importance": 7,
    "type": "custom",
    "description": "Vista espectacular del valle",
    "custom_data": {
      "added_by": "user@example.com",
      "date_added": "2024-11-24",
      "photo_url": "https://..."
    }
  },
  {
    "id": "custom_002",
    "name": "Fuente del Camino",
    "lat": 28.234567,
    "lon": -16.543210,
    "category": "amenity",
    "subtype": "fountain",
    "importance": 4,
    "type": "water_source"
  }
]
```

#### Método 2: Script de Importación

Para importar POIs desde un CSV:

```python
# import_custom_pois.py
import csv
import json

def csv_to_pois(csv_file, output_json):
    pois = []
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            poi = {
                'id': f"custom_{row['id']}",
                'name': row['name'],
                'lat': float(row['latitude']),
                'lon': float(row['longitude']),
                'elevation': float(row['elevation']) if row.get('elevation') else None,
                'category': row.get('category', 'generic'),
                'subtype': row.get('subtype', 'default'),
                'importance': int(row.get('importance', 5)),
                'type': row.get('type', 'custom')
            }
            pois.append(poi)
    
    with open(output_json, 'w') as f:
        json.dump(pois, f, indent=2)
    
    print(f"✅ {len(pois)} POIs importados")

# Uso:
# python3 import_custom_pois.py mis_pois.csv custom_pois.json
```

**Formato CSV esperado:**
```csv
id,name,latitude,longitude,elevation,category,subtype,importance,type
1,Punto A,28.123,-16.456,1200,natural,peak,8,mountain
2,Punto B,28.234,-16.567,850,tourism,viewpoint,6,viewpoint
```

#### Método 3: Combinar Múltiples Fuentes

```bash
# Combinar POIs de OpenStreetMap con POIs personalizados
python3 -c "
import json

# Cargar POIs de OSM
with open('osm_pois.json') as f:
    osm = json.load(f)

# Cargar POIs personalizados
with open('custom_pois.json') as f:
    custom = json.load(f)

# Combinar eliminando duplicados por ID
combined = {poi['id']: poi for poi in osm + custom}

# Guardar
with open('combined_pois.json', 'w') as f:
    json.dump(list(combined.values()), f, indent=2)

print(f'✅ {len(combined)} POIs totales')
"
```

---

## Scripts Incluidos

### Resumen de Scripts

| Script | Propósito | Entrada | Salida |
|--------|-----------|---------|--------|
| `fetch_dem.sh` | Descarga DEM (requiere configuración) | URLs configuradas | `.tif` raw |
| `fetch_pois_overpass.py` | Descarga POIs de OpenStreetMap | Bounding box | `.json` raw |
| `preprocess_dem.sh` | Convierte DEM a COG optimizado | `.tif` raw | `.tif` COG |
| `preprocess_pois.py` | Procesa y optimiza POIs | `.json` raw | `.json` final |

### Optimizaciones Recomendadas para los Scripts

#### fetch_pois_overpass.py - Mejoras

```python
# Versión mejorada con más opciones

import requests
import json
import argparse
import time

def fetch_pois(bbox, categories, out, timeout=60, retry=3):
    """
    Descarga POIs de Overpass API con reintentos y timeout configurable
    """
    minLon, minLat, maxLon, maxLat = map(str.strip, bbox.split(","))
    
    # Construir query dinámica según categorías
    category_queries = {
        'natural': f'node["natural"]({minLat},{minLon},{maxLat},{maxLon});',
        'tourism': f'node["tourism"]({minLat},{minLon},{maxLat},{maxLon});',
        'historic': f'node["historic"]({minLat},{minLon},{maxLat},{maxLon});',
        'amenity': f'node["amenity"]({minLat},{minLon},{maxLat},{maxLon});',
    }
    
    selected = [category_queries[c] for c in categories if c in category_queries]
    
    query = f"""[out:json][timeout:{timeout}];
    ({' '.join(selected)});
    out;"""
    
    for attempt in range(retry):
        try:
            print(f"Descargando POIs (intento {attempt + 1}/{retry})...")
            r = requests.post(
                "https://overpass-api.de/api/interpreter",
                data={'data': query},
                timeout=timeout
            )
            r.raise_for_status()
            
            data = r.json()
            pois = []
            
            for el in data.get('elements', []):
                tags = el.get('tags', {})
                pois.append({
                    'id': str(el.get('id')),
                    'name': tags.get('name', 'Unknown'),
                    'lat': el.get('lat'),
                    'lon': el.get('lon'),
                    'category': next((tags.get(c) for c in ['natural', 'tourism', 'historic', 'amenity'] if tags.get(c)), 'generic'),
                    'subtype': tags.get('natural', tags.get('tourism', 'default')),
                    'importance': 1
                })
            
            with open(out, 'w') as f:
                json.dump(pois, f, indent=2)
            
            print(f"✅ {len(pois)} POIs descargados a {out}")
            return
            
        except Exception as e:
            print(f"❌ Error en intento {attempt + 1}: {e}")
            if attempt < retry - 1:
                time.sleep(5)
            else:
                raise

# Uso:
# python3 fetch_pois_overpass.py --bbox="-16.95,28.0,-16.1,28.6" \
#   --out="pois.json" --categories natural tourism --timeout 60
```

---

## Workflow Completo

### Ejemplo: Preparar datos para Isla de Gran Canaria

```bash
#!/bin/bash
# prepare_gran_canaria.sh - Script completo de preparación

set -e

REGION="gran_canaria"
BBOX="-15.9,27.7,-15.3,28.2"

echo "📍 Preparando datos para $REGION"

# 1. Crear directorios
mkdir -p assets/data/dem
mkdir -p assets/data/pois

# 2. Descargar DEM de Copernicus
echo "⬇️  Descargando DEM..."
wget -O assets/data/dem/${REGION}_raw.tif \
  "https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_N28_00_W016_00_DEM/Copernicus_DSM_COG_10_N28_00_W016_00_DEM.tif"

# 3. Optimizar DEM a COG
echo "🔄 Optimizando DEM a COG..."
./scripts/preprocess_dem.sh \
  assets/data/dem/${REGION}_raw.tif \
  assets/data/dem/${REGION}_cog.tif

# 4. Descargar POIs de OpenStreetMap
echo "⬇️  Descargando POIs..."
python3 scripts/fetch_pois_overpass.py \
  --bbox="${BBOX}" \
  --out="assets/data/pois/${REGION}_pois_raw.json"

# 5. Procesar POIs
echo "🔄 Procesando POIs..."
python3 scripts/preprocess_pois.py \
  assets/data/pois/${REGION}_pois_raw.json \
  assets/data/pois/${REGION}_pois.json

# 6. Limpiar archivos temporales
echo "🧹 Limpiando..."
rm assets/data/dem/${REGION}_raw.tif
rm assets/data/pois/${REGION}_pois_raw.json

# 7. Verificar resultados
echo "✅ Verificando resultados..."
gdalinfo assets/data/dem/${REGION}_cog.tif | grep "Size is"
cat assets/data/pois/${REGION}_pois.json | jq '. | length'

echo "✅ Preparación completa para $REGION"
echo "📁 DEM: assets/data/dem/${REGION}_cog.tif"
echo "📁 POIs: assets/data/pois/${REGION}_pois.json"
```

### Checklist de Verificación

Antes de usar los archivos en tu app:

- [ ] **DEM verificado**
  ```bash
  gdalinfo assets/data/dem/region_cog.tif
  # Verificar: Driver: COG, Size correcto, WGS84
  ```

- [ ] **DEM tiene datos válidos**
  ```bash
  gdalinfo -stats assets/data/dem/region_cog.tif | grep "STATISTICS_"
  # Min/Max deben ser razonables (-500m a 5000m típicamente)
  ```

- [ ] **POIs tienen el formato correcto**
  ```bash
  cat assets/data/pois/region_pois.json | jq '.[0]'
  # Verificar que tiene id, name, lat, lon
  ```

- [ ] **POIs tienen coordenadas válidas**
  ```bash
  cat assets/data/pois/region_pois.json | jq '.[].lat' | sort -n
  # Verificar rango de latitudes es correcto
  ```

- [ ] **Archivos declarados en pubspec.yaml**
  ```yaml
  flutter:
    assets:
      - assets/data/dem/region_cog.tif
      - assets/data/pois/region_pois.json
  ```

- [ ] **Tamaño de archivos razonable**
  ```bash
  ls -lh assets/data/dem/*.tif
  # DEM: <50MB ideal, <100MB aceptable
  
  ls -lh assets/data/pois/*.json
  # POIs: <5MB ideal, <10MB aceptable
  ```

---

## Troubleshooting

### Problema: "Failed to load DEM"

**Causa**: Archivo no encontrado o formato incorrecto

**Solución**:
```bash
# Verificar que el archivo existe
ls -l assets/data/dem/region_cog.tif

# Verificar formato
gdalinfo assets/data/dem/region_cog.tif

# Si el error persiste, reconvertir
./scripts/preprocess_dem.sh input.tif output.tif
```

### Problema: "No POIs visible"

**Causa**: POIs fuera del rango de distancia o coordenadas incorrectas

**Solución**:
```bash
# Verificar coordenadas de POIs
cat assets/data/pois/region_pois.json | jq '.[0] | {lat, lon}'

# Verificar que están en la región correcta
# Comparar con tu ubicación GPS

# Verificar número de POIs
cat assets/data/pois/region_pois.json | jq '. | length'
# Si es 0, descargar de nuevo
```

### Problema: Overpass API timeout

**Causa**: Región muy grande o API sobrecargada

**Solución**:
```bash
# Dividir bbox en regiones más pequeñas
# O aumentar timeout
python3 scripts/fetch_pois_overpass.py \
  --bbox="..." \
  --out="pois.json" \
  --timeout=120  # Aumentar a 2 minutos
```

### Problema: DEM muy grande (>200MB)

**Causa**: Resolución muy alta o área muy grande

**Solución**:
```bash
# Opción 1: Reducir resolución
gdalwarp -tr 60 60 -r bilinear \
  input.tif output_lowres.tif

# Opción 2: Recortar área
gdal_translate -projwin <xmin> <ymax> <xmax> <ymin> \
  input.tif output_cropped.tif

# Opción 3: Aumentar compresión
gdal_translate -of COG -co COMPRESS=ZSTD -co LEVEL=9 \
  input.tif output_compressed.tif
```

### Problema: GDAL no instalado

**Solución por plataforma**:

```bash
# macOS
brew install gdal

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install gdal-bin python3-gdal

# Fedora/RHEL
sudo dnf install gdal gdal-python3

# Windows
# Descargar desde: https://gdal.org/download.html
# O usar OSGeo4W: https://trac.osgeo.org/osgeo4w/
```

### Problema: POIs sin nombres

**Causa**: OpenStreetMap no tiene nombres para algunos POIs

**Solución**:
```python
# Modificar preprocess_pois.py para usar coordenadas como fallback
name = tags.get('name') or \
       tags.get('ref') or \
       f"POI_{el.get('lat'):.3f}_{el.get('lon'):.3f}"
```

---

## Conclusión

Los archivos DEM y POIs son **fundamentales** para el correcto funcionamiento de `flutter_geo_ar`. Este documento ha cubierto:

✅ **Dónde obtener datos**: Copernicus (DEM), OpenStreetMap (POIs)  
✅ **Cómo procesarlos**: Scripts incluidos en el plugin  
✅ **Cómo optimizarlos**: Conversión a COG, filtrado de POIs  
✅ **Cómo personalizarlos**: Añadir POIs propios  
✅ **Cómo verificarlos**: Checklists y herramientas  

### Próximos Pasos

1. Descargar DEM de tu región desde Copernicus
2. Convertirlo a COG con `preprocess_dem.sh`
3. Descargar POIs con `fetch_pois_overpass.py`
4. Procesar POIs con `preprocess_pois.py`
5. Añadir archivos a `assets/` y `pubspec.yaml`
6. Probar con `GeoArView`

### Recursos Adicionales

- **Copernicus DEM**: https://copernicus-dem-30m.s3.amazonaws.com/
- **OpenStreetMap Overpass**: https://overpass-turbo.eu/
- **GDAL Documentation**: https://gdal.org/
- **Bounding Box Tool**: https://boundingbox.klokantech.com/


