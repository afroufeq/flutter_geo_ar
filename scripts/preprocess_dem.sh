#!/bin/bash
# Convierte un GeoTIFF estándar a COG (Cloud Optimized GeoTIFF) optimizado
# Requiere GDAL instalado (gdal_translate)

set -e

INPUT=$1
OUTPUT=$2

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
  echo "Uso: ./preprocess_dem.sh <input.tif> <output_cog.tif>"
  exit 1
fi

echo "🔄 Optimizando DEM: $INPUT -> $OUTPUT"

# -of COG: Formato Cloud Optimized
# -co COMPRESS=DEFLATE: Compresión sin pérdidas eficiente
# -co BLOCKSIZE=512: Bloques para acceso rápido aleatorio
# -co OVERVIEWS=IGNORE_EXISTING: Regenerar vistas previas si es necesario

gdal_translate "$INPUT" "$OUTPUT" \
  -of COG \
  -co COMPRESS=DEFLATE \
  -co BLOCKSIZE=512 \
  -co PREDICTOR=2 \
  -co OVERVIEWS=IGNORE_EXISTING

echo "✅ DEM COG generado correctamente."