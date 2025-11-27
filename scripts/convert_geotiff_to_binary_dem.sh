#!/bin/bash
# Convierte un archivo GeoTIFF a formato binario personalizado para DemService
# Requiere: GDAL (gdal_translate, gdalinfo)

set -e

INPUT="$1"
OUTPUT="$2"

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
  echo "Uso: ./convert_geotiff_to_binary_dem.sh <input.tif> <output.bin>"
  echo ""
  echo "Ejemplo:"
  echo "  ./convert_geotiff_to_binary_dem.sh gran_canaria_cog.tif gran_canaria.bin"
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "❌ Error: El archivo $INPUT no existe"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🗺️  CONVERSIÓN GEOTIFF A BINARIO PERSONALIZADO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Obtener información del GeoTIFF
echo "📖 Leyendo información del GeoTIFF..."
INFO=$(gdalinfo "$INPUT")

WIDTH=$(echo "$INFO" | grep "Size is" | awk '{print $3}' | tr -d ',')
HEIGHT=$(echo "$INFO" | grep "Size is" | awk '{print $4}')

echo "📐 Dimensiones: ${WIDTH}x${HEIGHT}"

# Obtener coordenadas geográficas
COORDS=$(echo "$INFO" | grep -A4 "Corner Coordinates:" | grep "Upper Left\|Lower Right")
UPPER_LEFT=$(echo "$COORDS" | grep "Upper Left" | sed 's/.*(\(.*\))/\1/')
LOWER_RIGHT=$(echo "$COORDS" | grep "Lower Right" | sed 's/.*(\(.*\))/\1/')

MIN_LON=$(echo "$UPPER_LEFT" | awk -F',' '{print $1}' | tr -d ' ')
MAX_LAT=$(echo "$UPPER_LEFT" | awk -F',' '{print $2}' | tr -d ' ')
MAX_LON=$(echo "$LOWER_RIGHT" | awk -F',' '{print $1}' | tr -d ' ')
MIN_LAT=$(echo "$LOWER_RIGHT" | awk -F',' '{print $2}' | tr -d ' ')

echo "🌍 Coordenadas:"
echo "   Min Lat: $MIN_LAT"
echo "   Max Lat: $MAX_LAT"
echo "   Min Lon: $MIN_LON"
echo "   Max Lon: $MAX_LON"

# Obtener estadísticas
echo ""
echo "📊 Calculando estadísticas de elevación..."
STATS=$(gdalinfo -stats "$INPUT" 2>/dev/null | grep "STATISTICS_" | head -3)
MIN_ELEV=$(echo "$STATS" | grep "MINIMUM" | awk -F'=' '{print $2}')
MAX_ELEV=$(echo "$STATS" | grep "MAXIMUM" | awk -F'=' '{print $2}')
MEAN_ELEV=$(echo "$STATS" | grep "MEAN" | awk -F'=' '{print $2}')

if [ -n "$MIN_ELEV" ]; then
  echo "⛰️  Elevación:"
  echo "   Mínima: ${MIN_ELEV}m"
  echo "   Máxima: ${MAX_ELEV}m"
  echo "   Media:  ${MEAN_ELEV}m"
fi

# Crear directorio temporal
TEMP_DIR=$(mktemp -d)
TEMP_RAW="${TEMP_DIR}/temp_raw.bin"
TEMP_HEADER="${TEMP_DIR}/header.bin"

echo ""
echo "💾 Creando archivo binario..."

# Convertir GeoTIFF a raw Float32
gdal_translate -of ENVI -ot Float32 "$INPUT" "$TEMP_RAW" > /dev/null 2>&1

# Crear el header (32 bytes)
# Usamos Python para crear el header binario correctamente
python3 - <<EOF
import struct

width = $WIDTH
height = $HEIGHT
min_lat = $MIN_LAT
min_lon = $MIN_LON
max_lat = $MAX_LAT

with open('$TEMP_HEADER', 'wb') as f:
    f.write(struct.pack('<i', width))      # 4 bytes: width
    f.write(struct.pack('<i', height))     # 4 bytes: height
    f.write(struct.pack('<d', min_lat))    # 8 bytes: minLat
    f.write(struct.pack('<d', min_lon))    # 8 bytes: minLon
    f.write(struct.pack('<d', max_lat))    # 8 bytes: maxLat
EOF

# Combinar header + datos
cat "$TEMP_HEADER" "${TEMP_RAW}.raw" > "$OUTPUT"

# Limpiar archivos temporales
rm -rf "$TEMP_DIR"

# Verificar archivo creado
FILE_SIZE=$(stat -f%z "$OUTPUT" 2>/dev/null || stat -c%s "$OUTPUT" 2>/dev/null)
EXPECTED_SIZE=$((32 + WIDTH * HEIGHT * 4))

echo ""
if [ "$FILE_SIZE" -eq "$EXPECTED_SIZE" ]; then
  echo "✅ Archivo binario creado correctamente"
  echo "   Tamaño: $(echo "scale=2; $FILE_SIZE / 1048576" | bc)MB"
else
  echo "⚠️  Advertencia: Tamaño de archivo inesperado"
  echo "   Esperado: $EXPECTED_SIZE bytes"
  echo "   Obtenido: $FILE_SIZE bytes"
fi

echo ""
echo "🎉 Conversión completada: $OUTPUT"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
