# 📚 Tutorial Completo: Conversión de GeoTIFF a COG

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [¿Por qué COG?](#por-qué-cog)
3. [Instalación de GDAL](#instalación-de-gdal)
4. [Script de Conversión](#script-de-conversión)
5. [Ejemplos Prácticos](#ejemplos-prácticos)
   - [SRTM](#ejemplo-1-srtm)
   - [Copernicus](#ejemplo-2-copernicus)
   - [ASTER GDEM](#ejemplo-3-aster-gdem)
   - [ALOS World 3D](#ejemplo-4-alos-world-3d)
6. [Troubleshooting](#troubleshooting)
7. [Preguntas Frecuentes](#preguntas-frecuentes)

---

## Introducción

Este tutorial te guiará paso a paso en el proceso de convertir archivos GeoTIFF de diferentes fuentes (SRTM, Copernicus, ASTER, ALOS) al formato **COG (Cloud Optimized GeoTIFF)** optimizado para uso en `flutter_geo_ar`.

### ¿Qué lograrás?

- ✅ Convertir cualquier GeoTIFF a formato COG optimizado
- ✅ Reducir el tamaño del archivo (típicamente 50-70% de compresión)
- ✅ Mejorar el rendimiento de lectura en tu app
- ✅ Reproyectar automáticamente a WGS84 (EPSG:4326) si es necesario

### Tiempo estimado

- **Instalación GDAL**: 5-10 minutos
- **Conversión por archivo**: 1-5 minutos (según tamaño)

---

## ¿Por qué COG?

### Formato GeoTIFF estándar

```
❌ Problemas:
- Lectura secuencial (necesita leer todo el archivo)
- No optimizado para acceso aleatorio
- Sin compresión eficiente
- Tamaño de archivo grande
```

### Formato COG (Cloud Optimized GeoTIFF)

```
✅ Ventajas:
- Acceso aleatorio rápido (lee solo lo necesario)
- Tiles internos optimizados (bloques de 512x512 píxeles)
- Overviews para zoom rápido
- Compresión DEFLATE/ZSTD sin pérdida
- Tamaño reducido (50-70% menos)
- Perfecto para apps móviles
```

### Comparación de Rendimiento

| Operación | GeoTIFF Estándar | COG Optimizado |
|-----------|------------------|----------------|
| Lectura completa | 100 ms | 100 ms |
| Lectura de 1 tile | 100 ms | 5 ms |
| Memoria usada | Alta | Baja |
| Tamaño archivo (100km²) | 50 MB | 15 MB |

---

## Instalación de GDAL

GDAL (Geospatial Data Abstraction Library) es la herramienta necesaria para procesar archivos GeoTIFF.

### macOS

```bash
# Opción 1: Homebrew (Recomendado)
brew install gdal

# Verificar instalación
gdalinfo --version
# Debería mostrar: GDAL 3.x.x
```

### Ubuntu / Debian

```bash
# Actualizar repositorios
sudo apt-get update

# Instalar GDAL
sudo apt-get install gdal-bin python3-gdal

# Verificar instalación
gdalinfo --version
```

### Fedora / RHEL / CentOS

```bash
# Instalar GDAL
sudo dnf install gdal gdal-python3

# Verificar instalación
gdalinfo --version
```

### Windows

**Opción 1: OSGeo4W (Recomendado)**

1. Descargar OSGeo4W desde: https://trac.osgeo.org/osgeo4w/
2. Ejecutar instalador
3. Seleccionar "Advanced Install"
4. Buscar y seleccionar "gdal" en la lista de paquetes
5. Completar instalación

**Opción 2: Conda**

```bash
# Si tienes Anaconda/Miniconda instalado
conda install -c conda-forge gdal
```

### Verificar que GDAL funciona correctamente

```bash
# Verificar versión
gdalinfo --version

# Listar formatos soportados (debe incluir COG)
gdalinfo --formats | grep COG
# Debería mostrar: COG -raster- (rw+): Cloud Optimized GeoTIFF
```

---

## Script de Conversión

El plugin incluye un script mejorado `convert_dem_to_cog.sh` que:

- ✅ Valida que GDAL está instalado
- ✅ Verifica que el archivo de entrada existe y es válido
- ✅ Reproyecta automáticamente a WGS84 si es necesario
- ✅ Optimiza parámetros según tamaño del archivo
- ✅ Muestra progreso y estadísticas
- ✅ Valida que el COG generado es correcto

### Ubicación

```bash
flutter_geo_ar/
├── scripts/
│   ├── convert_dem_to_cog.sh  ← Script mejorado
│   └── preprocess_dem.sh      ← Script original (más simple)
```

### Uso básico

```bash
# Hacer el script ejecutable (solo primera vez)
chmod +x scripts/convert_dem_to_cog.sh

# Convertir un archivo
./scripts/convert_dem_to_cog.sh input.tif output_cog.tif
```

### Ejemplo de salida

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🗺️  CONVERSIÓN DEM A COG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Entrada:      srtm_raw.tif
📁 Salida:       srtm_cog.tif
📊 Tamaño:       45M
📐 Dimensiones:  3601, 3601
🌍 Proyección:   4326

ℹ️  Archivo mediano: usando compresión DEFLATE y bloques de 512
🔄 Iniciando conversión...

✅ Conversión completada en 8s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 RESULTADOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Archivo generado: srtm_cog.tif
📊 Tamaño original:  45M
📊 Tamaño COG:       13M
📉 Ratio compresión: 3.5x
⏱️  Tiempo:           8s

✅ COG válido y optimizado

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📈 ESTADÍSTICAS DEL DEM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏔️  Altitud mínima:  0m
⛰️  Altitud máxima:  3718m
📊 Altitud media:    856m
```

---

## Ejemplos Prácticos

### Ejemplo 1: SRTM

**Fuente**: NASA Shuttle Radar Topography Mission  
**Resolución**: 30m (SRTM1) o 90m (SRTM3)  
**Formato descarga**: `.hgt` (formato binario)  
**Descarga desde**: https://dwtkns.com/srtm30m/

#### Paso 1: Descargar archivo SRTM

```bash
# Visitar https://dwtkns.com/srtm30m/
# Hacer clic en tu región de interés
# Descargar archivo .hgt (ejemplo: N28W017.hgt)

# Mover a directorio de trabajo
mkdir -p ~/dem_conversion
mv ~/Downloads/N28W017.hgt ~/dem_conversion/
```

#### Paso 2: Convertir .hgt a GeoTIFF (si es necesario)

```bash
cd ~/dem_conversion

# SRTM .hgt es un formato binario, convertir a GeoTIFF primero
gdal_translate -of GTiff N28W017.hgt srtm_raw.tif
```

#### Paso 3: Optimizar a COG

```bash
# Usando el script mejorado
/ruta/a/flutter_geo_ar/scripts/convert_dem_to_cog.sh \
  srtm_raw.tif \
  srtm_tenerife_cog.tif

# Resultado esperado:
# - Archivo: srtm_tenerife_cog.tif
# - Tamaño: ~13-15MB (vs ~45MB original)
# - Tiempo: 5-10 segundos
```

#### Verificación

```bash
# Ver información del COG
gdalinfo srtm_tenerife_cog.tif | grep -E "Driver|Size|Block|COMPRESS"

# Salida esperada:
# Driver: COG/Cloud Optimized GeoTIFF
# Size is 3601, 3601
# Block=512x512
# COMPRESS=DEFLATE
```

---

### Ejemplo 2: Copernicus

**Fuente**: Copernicus DEM (ESA)  
**Resolución**: 30m (GLO-30)  
**Formato descarga**: `.tif` (ya es GeoTIFF)  
**Ventaja**: Ya viene en formato COG, pero puede optimizarse más  
**Descarga desde**: https://copernicus-dem-30m.s3.amazonaws.com/

#### Paso 1: Descargar tile de Copernicus

```bash
cd ~/dem_conversion

# Ejemplo: Tenerife (tile N28W017)
wget -O copernicus_raw.tif \
  "https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_N28_00_W017_00_DEM/Copernicus_DSM_COG_10_N28_00_W017_00_DEM.tif"

# Múltiples tiles (si tu región es grande)
wget -O tile1.tif "https://copernicus-dem-30m.s3.amazonaws.com/.../N28W017.tif"
wget -O tile2.tif "https://copernicus-dem-30m.s3.amazonaws.com/.../N28W016.tif"

# Fusionar tiles
gdal_merge.py -o copernicus_merged.tif tile1.tif tile2.tif
```

#### Paso 2: Optimizar (aunque ya sea COG)

```bash
# Copernicus ya es COG, pero podemos optimizarlo más
/ruta/a/flutter_geo_ar/scripts/convert_dem_to_cog.sh \
  copernicus_raw.tif \
  copernicus_tenerife_cog.tif

# Beneficios adicionales:
# - Compresión DEFLATE más agresiva
# - Bloques optimizados para acceso móvil
# - Overviews regenerados
```

#### Recortar a área específica (opcional)

```bash
# Si solo necesitas una parte del tile
# Formato: -projwin <lon_min> <lat_max> <lon_max> <lat_min>

gdal_translate -projwin -16.9 28.6 -16.1 28.0 \
  copernicus_raw.tif \
  copernicus_cropped.tif

# Luego optimizar
./scripts/convert_dem_to_cog.sh \
  copernicus_cropped.tif \
  copernicus_final_cog.tif
```

---

### Ejemplo 3: ASTER GDEM

**Fuente**: ASTER Global DEM (NASA/METI)  
**Resolución**: 30m  
**Formato descarga**: `.tif` comprimido en `.zip`  
**Descarga desde**: https://asterweb.jpl.nasa.gov/gdem.asp

#### Paso 1: Descargar y extraer

```bash
cd ~/dem_conversion

# Después de descargar desde el portal (requiere registro)
unzip ASTGTMV003_N28W017.zip

# Esto extrae: ASTGTMV003_N28W017_dem.tif
```

#### Paso 2: Verificar y convertir

```bash
# Ver info del archivo
gdalinfo ASTGTMV003_N28W017_dem.tif

# Convertir a COG optimizado
/ruta/a/flutter_geo_ar/scripts/convert_dem_to_cog.sh \
  ASTGTMV003_N28W017_dem.tif \
  aster_tenerife_cog.tif
```

#### Nota sobre ASTER

⚠️ **Advertencia**: ASTER puede tener artefactos (valores erróneos) en algunas regiones. Recomendamos usar Copernicus o SRTM si están disponibles.

```bash
# Si encuentras valores anómalos, puedes filtrarlos
gdalwarp -dstnodata -9999 \
  -co COMPRESS=DEFLATE \
  ASTGTMV003_N28W017_dem.tif \
  aster_cleaned.tif

# Luego convertir a COG
./scripts/convert_dem_to_cog.sh aster_cleaned.tif aster_cog.tif
```

---

### Ejemplo 4: ALOS World 3D

**Fuente**: ALOS World 3D (JAXA)  
**Resolución**: 30m  
**Formato descarga**: Varios formatos (.tar.gz con .tif dentro)  
**Descarga desde**: https://www.eorc.jaxa.jp/ALOS/en/aw3d30/

#### Paso 1: Descargar y extraer

```bash
cd ~/dem_conversion

# Después de descargar (requiere registro gratuito)
tar -xzf ALPSMLC30_N028W017_DSM.tar.gz

# Esto extrae: N028W017_AVE_DSM.tif
```

#### Paso 2: Convertir a COG

```bash
/ruta/a/flutter_geo_ar/scripts/convert_dem_to_cog.sh \
  N028W017_AVE_DSM.tif \
  alos_tenerife_cog.tif

# ALOS suele tener excelente calidad en zonas montañosas
```

#### Combinar con máscara de agua (opcional)

```bash
# ALOS incluye máscaras de agua y calidad
# Combinar para mejor resultado

gdalwarp -srcnodata -9999 \
  -dstnodata -9999 \
  -co COMPRESS=DEFLATE \
  N028W017_AVE_DSM.tif \
  alos_masked.tif

./scripts/convert_dem_to_cog.sh alos_masked.tif alos_final_cog.tif
```

---

## Troubleshooting

### Problema 1: "GDAL not found"

**Error**:
```
❌ Error: GDAL no está instalado
```

**Solución**:
```bash
# macOS
brew install gdal

# Ubuntu/Debian
sudo apt-get install gdal-bin

# Verificar
which gdalinfo
# Debería mostrar: /usr/local/bin/gdalinfo o similar
```

---

### Problema 2: "Permission denied"

**Error**:
```
bash: ./convert_dem_to_cog.sh: Permission denied
```

**Solución**:
```bash
# Hacer el script ejecutable
chmod +x scripts/convert_dem_to_cog.sh

# Verificar permisos
ls -l scripts/convert_dem_to_cog.sh
# Debería mostrar: -rwxr-xr-x (ejecutable)
```

---

### Problema 3: "Archivo muy grande, conversión lenta"

**Síntomas**:
```
⚠️  Archivo grande (>200MB). La conversión puede tardar varios minutos.
```

**Solución 1: Recortar área**
```bash
# Solo convertir la región que necesitas
gdal_translate -projwin -16.9 28.6 -16.1 28.0 \
  input_grande.tif \
  input_recortado.tif

./scripts/convert_dem_to_cog.sh input_recortado.tif output_cog.tif
```

**Solución 2: Reducir resolución**
```bash
# Si no necesitas 30m, usa 60m o 90m
gdalwarp -tr 60 60 -r bilinear \
  input.tif \
  input_60m.tif

./scripts/convert_dem_to_cog.sh input_60m.tif output_cog.tif
```

**Solución 3: Procesamiento en paralelo**
```bash
# Dividir en tiles y procesar en paralelo
gdal_retile.py -ps 1024 1024 -targetDir tiles/ input.tif

# Procesar cada tile
for tile in tiles/*.tif; do
  ./scripts/convert_dem_to_cog.sh "$tile" "cog_${tile}"
done

# Fusionar tiles COG
gdal_merge.py -o merged_cog.tif cog_tiles/*.tif
```

---

### Problema 4: "Proyección incorrecta"

**Síntomas**:
```
⚠️  El DEM no está en EPSG:4326 (WGS84).
ℹ️  Se reproyectará automáticamente a WGS84...
```

**Qué hace el script**:
```bash
# El script detecta automáticamente y reproyecta
# usando gdalwarp con -t_srs EPSG:4326
```

**Manual (si prefieres controlar el proceso)**:
```bash
# Ver proyección actual
gdalinfo input.tif | grep "AUTHORITY"

# Reproyectar a WGS84
gdalwarp -t_srs EPSG:4326 \
  -r bilinear \
  -co COMPRESS=DEFLATE \
  input.tif \
  input_wgs84.tif

# Luego convertir a COG
./scripts/convert_dem_to_cog.sh input_wgs84.tif output_cog.tif
```

---

### Problema 5: "Valores de elevación fuera de rango"

**Síntomas**:
```
⛰️  Altitud máxima: 32767m  # ¡Esto no es normal!
🏔️  Altitud mínima: -32768m
```

**Diagnóstico**:
```bash
# Ver estadísticas detalladas
gdalinfo -stats input.tif | grep "STATISTICS"

# Ver tipo de datos
gdalinfo input.tif | grep "Type="
```

**Solución**:
```bash
# Filtrar valores anómalos
gdalwarp -srcnodata -9999 \
  -dstnodata -9999 \
  -co COMPRESS=DEFLATE \
  input.tif \
  input_cleaned.tif

# Luego convertir
./scripts/convert_dem_to_cog.sh input_cleaned.tif output_cog.tif
```

---

### Problema 6: "El COG no está optimizado"

**Síntomas**:
```
⚠️  El archivo se generó pero puede no estar completamente optimizado como COG
```

**Verificación**:
```bash
# Validar COG con rio-cogeo (si está instalado)
pip install rio-cogeo
rio cogeo validate output_cog.tif

# O manualmente con gdalinfo
gdalinfo output_cog.tif | grep -i "layout"
# Debería mostrar: LAYOUT=COG
```

**Re-optimizar**:
```bash
# Forzar regeneración completa
gdal_translate -of COG \
  -co COMPRESS=DEFLATE \
  -co BLOCKSIZE=512 \
  -co PREDICTOR=2 \
  -co BIGTIFF=YES \
  -co OVERVIEW_RESAMPLING=BILINEAR \
  input.tif \
  output_cog.tif
```

---

### Problema 7: "Memoria insuficiente"

**Error**:
```
ERROR: Memory allocation failed
```

**Solución**:
```bash
# Procesar en bloques (warped VRT)
gdalwarp -of VRT -wm 500 \
  input.tif \
  temp.vrt

gdal_translate -of COG \
  -co COMPRESS=DEFLATE \
  -co BLOCKSIZE=512 \
  temp.vrt \
  output_cog.tif
```

---

## Preguntas Frecuentes

### ¿Puedo convertir archivos en formato distinto a GeoTIFF?

**Sí**, GDAL soporta muchos formatos. Primero convierte a GeoTIFF, luego a COG:

```bash
# Desde formato XYZ ASCII
gdal_translate -of GTiff input.xyz temp.tif
./scripts/convert_dem_to_cog.sh temp.tif output_cog.tif

# Desde NetCDF
gdal_translate -of GTiff NETCDF:input.nc:elevation temp.tif
./scripts/convert_dem_to_cog.sh temp.tif output_cog.tif

# Desde IMG (ERDAS Imagine)
gdal_translate -of GTiff input.img temp.tif
./scripts/convert_dem_to_cog.sh temp.tif output_cog.tif
```

---

### ¿Qué compresión es mejor: DEFLATE o ZSTD?

**DEFLATE** (predeterminado):
- ✅ Compatible universalmente
- ✅ Buena compresión
- ✅ Velocidad aceptable
- ✅ Recomendado para archivos >20MB

**ZSTD** (para archivos pequeños):
- ✅ Mejor compresión que DEFLATE
- ✅ Más rápido
- ⚠️ Menos compatible (GDAL >3.1 requerido)
- ✅ Recomendado para archivos <20MB

El script automáticamente elige la mejor opción según tamaño.

---

### ¿Cuánto espacio ahorro con COG?

Típicamente:
- **SRTM sin comprimir**: 45MB → 13MB COG (71% reducción)
- **Copernicus**: 38MB → 12MB COG (68% reducción)
- **ASTER**: 52MB → 16MB COG (69% reducción)

---

### ¿Pierdo calidad con la conversión a COG?

**No**. COG usa compresión **sin pérdida** (DEFLATE/ZSTD). Los valores de elevación permanecen exactos.

---

### ¿Puedo usar el mismo COG en web y móvil?

**Sí**. COG es un estándar y funciona igual en:
- ✅ Flutter (iOS/Android)
- ✅ Web (con librerías geoespaciales)
- ✅ Desktop
- ✅ Servidores

---

### ¿Necesito internet para usar el COG?

**No**. El COG se incluye como asset en tu app. Funciona 100% offline.

---

### ¿Cuál es el tamaño máximo recomendado?

Para apps móviles:
- ✅ **Óptimo**: <20MB por región
- ⚠️ **Aceptable**: 20-50MB
- ❌ **Evitar**: >100MB (considera dividir en regiones)

---

### ¿Puedo tener múltiples COG en mi app?

**Sí**. Puedes tener un COG por región/isla:

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/data/dem/tenerife_cog.tif
    - assets/data/dem/gran_canaria_cog.tif
    - assets/data/dem/lanzarote_cog.tif
    # ...
```

Ver: [docs/GESTION_MULTIPLES_REGIONES.md](GESTION_MULTIPLES_REGIONES.md)

---

## Workflow Completo Recomendado

```bash
#!/bin/bash
# workflow_completo.sh - Ejemplo de flujo completo

REGION="mi_region"
BBOX="-16.95,28.0,-16.1,28.6"  # lon_min,lat_min,lon_max,lat_max

# 1. Crear estructura
mkdir -p ~/dem_project/{raw,processed}
cd ~/dem_project

# 2. Descargar DEM (ejemplo: Copernicus)
echo "📥 Descargando DEM..."
wget -O raw/copernicus.tif \
  "https://copernicus-dem-30m.s3.amazonaws.com/..."

# 3. Recortar a región específica
echo "✂️  Recortando a región..."
gdal_translate -projwin ${BBOX//,/ } \
  raw/copernicus.tif \
  raw/${REGION}_cropped.tif

# 4. Convertir a COG optimizado
echo "🔄 Optimizando a COG..."
/ruta/a/flutter_geo_ar/scripts/convert_dem_to_cog.sh \
  raw/${REGION}_cropped.tif \
  processed/${REGION}_cog.tif

# 5. Mover a proyecto Flutter
echo "📁 Moviendo a proyecto..."
cp processed/${REGION}_cog.tif \
  /ruta/a/tu_app/assets/data/dem/

# 6. Verificar resultado
echo "✅ Verificando..."
gdalinfo processed/${REGION}_cog.tif | grep -E "Size|Block|COMPRESS"

echo "🎉 ¡Listo! Archivo: ${REGION}_cog.tif"
```

---

## Recursos Adicionales

- **GDAL Documentation**: https://gdal.org/
- **COG Specification**: https://www.cogeo.org/
- **Copernicus DEM**: https://copernicus-dem-30m.s3.amazonaws.com/
- **SRTM Tiles**: https://dwtkns.com/srtm30m/
- **Bounding Box Tool**: https://boundingbox.klokantech.com/

---

## Conclusión

Siguiendo este tutorial, podrás convertir cualquier GeoTIFF de cualquier fuente al formato COG optimizado en minutos, sin comprometer calidad y mejorando significativamente el rendimiento en tu app.

Recuerda que para usarlo en el Plugin debes convertirlo a binario optimizado usando el script `convert_geotiff_to_binary.sh`

### Checklist final

- [ ] GDAL instalado y funcionando
- [ ] Script `convert_dem_to_cog.sh` ejecutable
- [ ] DEM descargado de tu región
- [ ] Conversión a COG completada exitosamente
- [ ] Archivo COG verificado (<50MB ideal)
- [ ] Archivo movido a `assets/data/dem/`
- [ ] `pubspec.yaml` actualizado
- [ ] Listo para usar en tu app 🚀

---

**¿Problemas?** Consulta la sección [Troubleshooting](#troubleshooting) o abre un issue en el repositorio.
