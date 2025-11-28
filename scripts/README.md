# 🛠️ Scripts de Utilidades para flutter_geo_ar

Este directorio contiene scripts para preparar y procesar los datos necesarios para el plugin `flutter_geo_ar`: archivos DEM (Modelos Digitales de Elevación) y POIs (Puntos de Interés).

## 📋 Índice

- [Resumen de Scripts](#resumen-de-scripts)
- [Scripts de DEM](#scripts-de-dem)
- [Scripts de POIs](#scripts-de-pois)
- [Documentación de Referencia](#documentación-de-referencia)
- [Workflow Recomendado](#workflow-recomendado)
- [Troubleshooting](#troubleshooting)

---

## Resumen de Scripts

| Script | Propósito | Entrada | Salida | Documentación |
|--------|-----------|---------|--------|---------------|
| `convert_dem_to_cog.sh` | Convierte DEM a COG optimizado (con validación) | `.tif` | `.tif` COG | [Tutorial](#convert_dem_to_cogsh) |
| `preprocess_dem.sh` | Convierte DEM a COG (versión simple) | `.tif` | `.tif` COG | [Tutorial](#preprocess_demsh) |
| `convert_geotiff_to_binary_dem.sh` | Convierte GeoTIFF a binario personalizado | `.tif` | `.bin` | [Tutorial](#convert_geotiff_to_binary_demsh) |
| `convert_geotiff_to_binary.py` | Convierte GeoTIFF a binario (versión Python) | `.tif` | `.bin` | [Tutorial](#convert_geotiff_to_binarypy) |
| `fetch_dem.sh` | Descarga DEMs (requiere configuración) | URLs | `.tif` | [Tutorial](#fetch_demsh) |
| `convert_pois.py` | Convierte POIs desde múltiples formatos | GeoJSON/KML/CSV/GPX | `.json` | [Docs POIs](docs/CONVERSION_POIS.md) |
| `fetch_pois_overpass.py` | Descarga POIs desde OpenStreetMap | Bounding box | `.json` | [Docs Obtención](docs/OBTENCION_DEM_Y_POIS.md#obtención-desde-openstreetmap) |
| `preprocess_pois.py` | Procesa JSON de Overpass | `.json` raw | `.json` optimizado | [Tutorial](#preprocess_poispy) |

---

## Scripts de DEM

Los archivos DEM (Digital Elevation Model) son modelos de elevación del terreno necesarios para calcular altitudes y proyectar correctamente los POIs en 3D.

### convert_dem_to_cog.sh

**🌟 RECOMENDADO** - Script mejorado con validación completa y feedback detallado.

#### ¿Qué hace?

Convierte cualquier archivo GeoTIFF a formato COG (Cloud Optimized GeoTIFF) optimizado para acceso rápido en dispositivos móviles. Incluye:

- ✅ Validación de GDAL instalado
- ✅ Verificación del archivo de entrada
- ✅ Reproyección automática a WGS84 si es necesario
- ✅ Optimización de parámetros según tamaño del archivo
- ✅ Estadísticas detalladas del terreno
- ✅ Verificación del COG generado

#### Requisitos

- GDAL instalado (ver [Tutorial de Conversión GeoTIFF](docs/TUTORIAL_CONVERSION_GEOTIFF.md#instalación-de-gdal))

#### Uso

```bash
# Hacer ejecutable (solo primera vez)
chmod +x scripts/convert_dem_to_cog.sh

# Convertir un DEM
./scripts/convert_dem_to_cog.sh input.tif output_cog.tif
```

#### Ejemplo de salida

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🗺️  CONVERSIÓN DEM A COG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Entrada:      srtm_raw.tif
📁 Salida:       srtm_cog.tif
📊 Tamaño:       45M
📐 Dimensiones:  3601, 3601
🌍 Proyección:   4326

✅ Conversión completada en 8s

📊 Tamaño COG:       13M
📉 Ratio compresión: 3.5x
⛰️  Altitud máxima:  3718m
```

#### Documentación detallada

📚 **[Tutorial Completo de Conversión GeoTIFF](docs/TUTORIAL_CONVERSION_GEOTIFF.md)** - Incluye ejemplos para SRTM, Copernicus, ASTER y ALOS.

---

### preprocess_dem.sh

Script simple para conversión básica de DEM a COG sin validación adicional.

#### ¿Qué hace?

Convierte un GeoTIFF estándar a formato COG usando parámetros predeterminados.

#### Uso

```bash
chmod +x scripts/preprocess_dem.sh
./scripts/preprocess_dem.sh input.tif output_cog.tif
```

#### Cuándo usar este script

- ✅ Para conversión rápida sin validaciones
- ✅ Si ya verificaste que el archivo es válido
- ❌ Para archivos grandes o complejos (usa `convert_dem_to_cog.sh`)

---

### convert_geotiff_to_binary_dem.sh

Convierte un archivo GeoTIFF al formato binario personalizado para `DemService`.

#### ¿Qué hace?

Crea un archivo binario con formato específico:
- **Header (32 bytes)**: Metadatos (ancho, alto, coordenadas)
- **Datos**: Valores de elevación en Float32

#### Requisitos

- GDAL instalado
- Python 3

#### Uso

```bash
chmod +x scripts/convert_geotiff_to_binary_dem.sh
./scripts/convert_geotiff_to_binary_dem.sh input_cog.tif output.bin
```

#### Ejemplo

```bash
# Convertir un COG a formato binario
./scripts/convert_geotiff_to_binary_dem.sh gran_canaria_cog.tif gran_canaria.bin
```

⚠️ **Nota**: Este formato binario es específico del plugin. Para la mayoría de casos, usar directamente archivos COG (.tif) es más conveniente.

---

### convert_geotiff_to_binary.py

Versión Python del conversor a formato binario.

#### ¿Qué hace?

Igual que `convert_geotiff_to_binary_dem.sh` pero implementado en Python usando GDAL Python bindings.

#### Requisitos

```bash
# macOS
brew install gdal
pip3 install gdal

# Ubuntu/Debian
sudo apt-get install python3-gdal
```

#### Uso

```bash
python3 scripts/convert_geotiff_to_binary.py input.tif output.bin
```

#### Ventajas sobre la versión shell

- ✅ Más portable entre plataformas
- ✅ Manejo más preciso de tipos de datos
- ✅ Mejor control de errores

---

### fetch_dem.sh

Script placeholder para descargar archivos DEM.

#### ¿Qué hace?

Este es un **script de ejemplo** que requiere configuración con URLs específicas de tu región.

#### Uso

```bash
# 1. Editar el script con tus URLs
nano scripts/fetch_dem.sh

# 2. Configurar URLs de descarga (ejemplo: Copernicus)
# wget -O "$DATA_DIR/region.tif" "https://copernicus-dem-30m.s3.amazonaws.com/..."

# 3. Ejecutar
chmod +x scripts/fetch_dem.sh
./scripts/fetch_dem.sh
```

#### Alternativa recomendada

En lugar de usar este script, se recomienda descargar manualmente desde las fuentes:

- **Copernicus DEM**: https://copernicus-dem-30m.s3.amazonaws.com/
- **SRTM**: https://dwtkns.com/srtm30m/

📚 Ver [Guía de Obtención de DEM](docs/OBTENCION_DEM_Y_POIS.md#fuentes-de-descarga-de-dem) para detalles completos.

---

## Scripts de POIs

Los POIs (Points of Interest) son puntos georreferenciados que representan lugares de interés: montañas, miradores, monumentos, etc.

### convert_pois.py

**🌟 SCRIPT PRINCIPAL** - Convierte POIs desde múltiples formatos al formato JSON optimizado del plugin.

#### ¿Qué hace?

Convierte POIs desde diferentes formatos a un JSON optimizado:

- ✅ **GeoJSON** (.geojson, .json)
- ✅ **KML** (.kml) - Google Earth
- ✅ **CSV** (.csv, .txt) - Hojas de cálculo
- ✅ **GPX** (.gpx) - Waypoints GPS

Incluye:
- Detección automática de formato por extensión
- Inferencia inteligente de categorías e importancia
- Filtrado por importancia mínima
- Validación de datos

#### Requisitos

- Python 3.6+ (sin dependencias externas)

#### Uso básico

```bash
python3 scripts/convert_pois.py <entrada> <salida> [--min-importance N]
```

#### Ejemplos

```bash
# Convertir desde GeoJSON
python3 scripts/convert_pois.py tenerife.geojson tenerife_pois.json

# Convertir desde KML con filtro de importancia
python3 scripts/convert_pois.py miradores.kml miradores_pois.json --min-importance 7

# Convertir desde CSV
python3 scripts/convert_pois.py puntos.csv puntos_pois.json

# Convertir waypoints desde GPX
python3 scripts/convert_pois.py ruta.gpx waypoints.json
```

#### Formatos de entrada soportados

##### GeoJSON
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
        "name": "Pico del Teide",
        "category": "natural:peak",
        "importance": 10
      }
    }
  ]
}
```

##### CSV
```csv
lat,lon,name,elevation,category,importance
28.2723,-16.6429,Pico del Teide,3718.0,natural:peak,10
28.0997,-16.8831,Mirador de La Fortaleza,1243.0,tourism:viewpoint,7
```

##### KML, GPX
Ver ejemplos en [Documentación de Conversión de POIs](docs/CONVERSION_POIS.md#formatos-soportados).

#### Formato de salida

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
  }
]
```

#### Documentación completa

📚 **[Guía de Conversión de POIs](docs/CONVERSION_POIS.md)** - Documentación completa con todos los formatos y ejemplos.

---

### fetch_pois_overpass.py

Descarga POIs desde OpenStreetMap usando la API Overpass.

#### ¿Qué hace?

Consulta la base de datos de OpenStreetMap y descarga POIs (picos, miradores, monumentos, etc.) de una región específica.

#### Requisitos

```bash
pip3 install requests
```

#### Uso

```bash
python3 scripts/fetch_pois_overpass.py \
  --bbox="minLon,minLat,maxLon,maxLat" \
  --out="output.json"
```

#### Ejemplo

```bash
# Descargar POIs de Tenerife
python3 scripts/fetch_pois_overpass.py \
  --bbox="-16.95,28.0,-16.1,28.6" \
  --out="tenerife_pois_raw.json"
```

#### Encontrar tu bounding box

1. Visitar https://boundingbox.klokantech.com/
2. Seleccionar tu región
3. Copiar coordenadas en formato CSV

#### Personalizar la query

Edita el script para cambiar qué tipos de POIs descargar:

```python
# Por defecto: picos
query = f"""[out:json][timeout:25];
(
  node["natural"="peak"]({minLat},{minLon},{maxLat},{maxLon});
);
out;"""

# Personalizado: múltiples tipos
query = f"""[out:json][timeout:25];
(
  node["natural"="peak"]({minLat},{minLon},{maxLat},{maxLon});
  node["tourism"="viewpoint"]({minLat},{minLon},{maxLat},{maxLon});
  node["historic"="monument"]({minLat},{minLon},{maxLat},{maxLon});
);
out;"""
```

📚 Ver más en [Guía de Obtención de POIs](docs/OBTENCION_DEM_Y_POIS.md#obtención-desde-openstreetmap).

---

### preprocess_pois.py

Procesa el JSON raw de Overpass y lo convierte a formato optimizado del plugin.

#### ¿Qué hace?

- Normaliza la estructura JSON de Overpass
- Calcula importancia basada en etiquetas
- Detecta categorías automáticamente
- Elimina datos innecesarios

#### Uso

```bash
python3 scripts/preprocess_pois.py <entrada.json> <salida.json>
```

#### Ejemplo

```bash
# 1. Descargar desde Overpass
python3 scripts/fetch_pois_overpass.py \
  --bbox="-16.95,28.0,-16.1,28.6" \
  --out="tenerife_raw.json"

# 2. Procesar
python3 scripts/preprocess_pois.py \
  tenerife_raw.json \
  tenerife_pois.json
```

#### ⚠️ Nota importante

Para la mayoría de casos, se recomienda usar **`convert_pois.py`** en lugar de este script, ya que:
- Soporta más formatos de entrada
- Tiene mejor inferencia de categorías
- Incluye validación más completa

Este script es útil principalmente cuando ya tienes datos específicos de Overpass y solo necesitas normalizarlos.

---

## Documentación de Referencia

En el directorio `/scripts/docs` encontrarás documentación detallada:

### 📚 [OBTENCION_DEM_Y_POIS.md](docs/OBTENCION_DEM_Y_POIS.md)

**Guía completa** de obtención de archivos DEM y POIs:

- ¿Por qué son necesarios estos archivos?
- Fuentes de descarga de DEM (Copernicus, SRTM, ASTER, ALOS)
- Obtención de POIs desde OpenStreetMap
- POIs personalizados
- Workflow completo
- Troubleshooting

### 📚 [TUTORIAL_CONVERSION_GEOTIFF.md](docs/TUTORIAL_CONVERSION_GEOTIFF.md)

**Tutorial paso a paso** de conversión de GeoTIFF a COG:

- ¿Por qué COG?
- Instalación de GDAL en todas las plataformas
- Ejemplos prácticos con SRTM, Copernicus, ASTER y ALOS
- Troubleshooting detallado
- Preguntas frecuentes
- Optimizaciones avanzadas

### 📚 [CONVERSION_POIS.md](docs/CONVERSION_POIS.md)

**Guía de conversión de POIs**:

- Formatos soportados (GeoJSON, KML, CSV, GPX)
- Ejemplos de uso
- Fuentes de POIs (OpenStreetMap, Google Earth, Wikiloc, etc.)
- Crear POIs personalizados
- Solución de problemas

---

## Workflow Recomendado

### Workflow para DEM

```bash
# 1. Descargar DEM de tu región (ejemplo: Copernicus)
wget -O raw_dem.tif \
  "https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_N28_00_W017_00_DEM/Copernicus_DSM_COG_10_N28_00_W017_00_DEM.tif"

# 2. Convertir a COG optimizado
./scripts/convert_dem_to_cog.sh raw_dem.tif region_cog.tif

# 3. Mover a tu proyecto Flutter
mv region_cog.tif /path/to/tu_app/assets/data/dem/

# 4. Añadir a pubspec.yaml
# flutter:
#   assets:
#     - assets/data/dem/region_cog.tif
```

### Workflow para POIs

```bash
# OPCIÓN A: Desde OpenStreetMap
# 1. Descargar desde Overpass
python3 scripts/fetch_pois_overpass.py \
  --bbox="-16.95,28.0,-16.1,28.6" \
  --out="pois_raw.json"

# 2. Procesar (opcional, o usar convert_pois.py)
python3 scripts/preprocess_pois.py pois_raw.json pois.json

# OPCIÓN B: Desde otros formatos
# Convertir directamente con convert_pois.py
python3 scripts/convert_pois.py input.geojson pois.json
python3 scripts/convert_pois.py input.kml pois.json
python3 scripts/convert_pois.py input.csv pois.json

# 3. Mover a tu proyecto
mv pois.json /path/to/tu_app/assets/data/pois/

# 4. Añadir a pubspec.yaml
# flutter:
#   assets:
#     - assets/data/pois/pois.json
```

### Workflow Completo (DEM + POIs)

```bash
#!/bin/bash
# Script completo para preparar datos de una región

REGION="mi_region"
BBOX="-16.95,28.0,-16.1,28.6"

# Crear estructura
mkdir -p assets/data/{dem,pois}

# 1. DEM
echo "📥 Procesando DEM..."
wget -O raw_dem.tif "URL_DE_TU_DEM"
./scripts/convert_dem_to_cog.sh raw_dem.tif assets/data/dem/${REGION}_cog.tif

# 2. POIs
echo "📥 Descargando POIs..."
python3 scripts/fetch_pois_overpass.py \
  --bbox="${BBOX}" \
  --out="pois_raw.json"

python3 scripts/convert_pois.py \
  pois_raw.json \
  assets/data/pois/${REGION}_pois.json

# 3. Limpiar temporales
rm raw_dem.tif pois_raw.json

echo "✅ Datos preparados para ${REGION}"
```

---

## Troubleshooting

### GDAL no instalado

```bash
# macOS
brew install gdal

# Ubuntu/Debian
sudo apt-get install gdal-bin

# Verificar
gdalinfo --version
```

### Script sin permisos de ejecución

```bash
chmod +x scripts/convert_dem_to_cog.sh
chmod +x scripts/preprocess_dem.sh
chmod +x scripts/convert_geotiff_to_binary_dem.sh
chmod +x scripts/fetch_dem.sh
```

### Python: requests no instalado

```bash
pip3 install requests
```

### Archivo DEM muy grande

Ver [Tutorial de Conversión GeoTIFF](docs/TUTORIAL_CONVERSION_GEOTIFF.md#problema-archivo-muy-grande-conversión-lenta) para técnicas de optimización.

### No se encuentran POIs

Verificar:
1. El bounding box es correcto
2. La región tiene datos en OpenStreetMap
3. La query de Overpass incluye los tipos deseados

Ver [Guía de Obtención](docs/OBTENCION_DEM_Y_POIS.md#troubleshooting) para más detalles.

---

## Recursos Adicionales

- **Plugin flutter_geo_ar**: https://github.com/afroufeq/flutter_geo_ar
- **Copernicus DEM**: https://copernicus-dem-30m.s3.amazonaws.com/
- **SRTM Tiles**: https://dwtkns.com/srtm30m/
- **OpenStreetMap Overpass**: https://overpass-turbo.eu/
- **GDAL Documentation**: https://gdal.org/
- **Bounding Box Tool**: https://boundingbox.klokantech.com/

---

## Contribuir

Si encuentras bugs o tienes sugerencias para mejorar estos scripts:

1. Reporta el issue en GitHub
2. Fork el proyecto
3. Crea un pull request con tus mejoras

---

## Licencia

Estos scripts son parte del plugin `flutter_geo_ar` y están bajo la misma licencia MIT.

