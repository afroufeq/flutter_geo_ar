#!/bin/bash
# convert_dem_to_cog.sh - Script mejorado para conversión DEM a COG
# Convierte cualquier GeoTIFF a formato COG optimizado con validación y feedback

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_error() {
    echo -e "${RED}❌ Error:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Validar que GDAL está instalado
if ! command -v gdalinfo &> /dev/null; then
    print_error "GDAL no está instalado"
    echo ""
    echo "📦 Instalar GDAL:"
    echo "   macOS:        brew install gdal"
    echo "   Ubuntu/Debian: sudo apt-get install gdal-bin"
    echo "   Fedora:       sudo dnf install gdal"
    echo "   Windows:      Descargar desde https://gdal.org/download.html"
    exit 1
fi

# Validar parámetros
INPUT_DEM=$1
OUTPUT_COG=$2

if [ -z "$INPUT_DEM" ] || [ -z "$OUTPUT_COG" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📖 Uso: $0 <input.tif> <output_cog.tif>"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Ejemplos:"
    echo "  $0 srtm_raw.tif srtm_cog.tif"
    echo "  $0 copernicus.tif region_optimized.tif"
    echo "  $0 aster_dem.tif aster_cog.tif"
    echo ""
    exit 1
fi

# Validar que el archivo de entrada existe
if [ ! -f "$INPUT_DEM" ]; then
    print_error "Archivo no encontrado: $INPUT_DEM"
    exit 1
fi

# Validar que es un archivo GeoTIFF válido
print_info "Validando archivo de entrada..."
if ! gdalinfo "$INPUT_DEM" &> /dev/null; then
    print_error "El archivo no es un GeoTIFF válido o está corrupto"
    exit 1
fi

# Obtener información del archivo de entrada
FILE_SIZE=$(du -h "$INPUT_DEM" | cut -f1)
DIMENSIONS=$(gdalinfo "$INPUT_DEM" | grep "Size is" | sed 's/Size is //')
PROJECTION=$(gdalinfo "$INPUT_DEM" | grep "AUTHORITY" | head -1 | sed 's/.*AUTHORITY\["\(.*\)"\].*/\1/' || echo "Unknown")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🗺️  CONVERSIÓN DEM A COG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Entrada:      $INPUT_DEM"
echo "📁 Salida:       $OUTPUT_COG"
echo "📊 Tamaño:       $FILE_SIZE"
echo "📐 Dimensiones:  $DIMENSIONS"
echo "🌍 Proyección:   $PROJECTION"
echo ""

# Advertir si el archivo es muy grande
FILE_SIZE_BYTES=$(stat -f%z "$INPUT_DEM" 2>/dev/null || stat -c%s "$INPUT_DEM" 2>/dev/null)
if [ "$FILE_SIZE_BYTES" -gt 209715200 ]; then  # 200MB
    print_warning "Archivo grande (>200MB). La conversión puede tardar varios minutos."
fi

# Advertir si no está en WGS84
if [[ "$PROJECTION" != *"4326"* ]]; then
    print_warning "El DEM no está en EPSG:4326 (WGS84)."
    print_info "Se reproyectará automáticamente a WGS84..."
    NEEDS_REPROJECTION=true
else
    NEEDS_REPROJECTION=false
fi

echo "🔄 Iniciando conversión..."
echo ""

# Configurar parámetros según tamaño del archivo
if [ "$FILE_SIZE_BYTES" -lt 20971520 ]; then  # <20MB
    BLOCKSIZE=256
    COMPRESS=ZSTD
    print_info "Archivo pequeño: usando compresión ZSTD y bloques de 256"
elif [ "$FILE_SIZE_BYTES" -lt 104857600 ]; then  # <100MB
    BLOCKSIZE=512
    COMPRESS=DEFLATE
    print_info "Archivo mediano: usando compresión DEFLATE y bloques de 512"
else  # >100MB
    BLOCKSIZE=1024
    COMPRESS=DEFLATE
    print_info "Archivo grande: usando compresión DEFLATE y bloques de 1024"
fi

# Ejecutar conversión con manejo de errores
START_TIME=$(date +%s)

if [ "$NEEDS_REPROJECTION" = true ]; then
    # Reproyectar y convertir en un solo paso
    if gdalwarp -of COG \
        -co COMPRESS=$COMPRESS \
        -co PREDICTOR=2 \
        -co BIGTIFF=YES \
        -co BLOCKSIZE=$BLOCKSIZE \
        -t_srs EPSG:4326 \
        "$INPUT_DEM" "$OUTPUT_COG" 2>&1 | while IFS= read -r line; do
            if [[ $line == *"ERROR"* ]]; then
                print_error "$line"
            elif [[ $line =~ [0-9]+\.\.[0-9]+ ]]; then
                echo -ne "\r⏳ Progreso: $line"
            fi
        done; then
        echo ""  # Nueva línea después del progreso
    else
        echo ""
        print_error "Fallo en la conversión con reproyección"
        exit 1
    fi
else
    # Solo convertir (sin reproyección)
    if gdal_translate "$INPUT_DEM" "$OUTPUT_COG" \
        -of COG \
        -co COMPRESS=$COMPRESS \
        -co BLOCKSIZE=$BLOCKSIZE \
        -co PREDICTOR=2 \
        -co BIGTIFF=YES \
        -co OVERVIEWS=IGNORE_EXISTING 2>&1 | while IFS= read -r line; do
            if [[ $line == *"ERROR"* ]]; then
                print_error "$line"
            elif [[ $line =~ [0-9]+\.\.[0-9]+ ]]; then
                echo -ne "\r⏳ Progreso: $line"
            fi
        done; then
        echo ""  # Nueva línea después del progreso
    else
        echo ""
        print_error "Fallo en la conversión"
        exit 1
    fi
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Verificar que el archivo de salida se creó correctamente
if [ ! -f "$OUTPUT_COG" ]; then
    print_error "El archivo de salida no se generó"
    exit 1
fi

OUTPUT_SIZE=$(du -h "$OUTPUT_COG" | cut -f1)
COMPRESSION_RATIO=$(echo "scale=1; $(stat -f%z "$INPUT_DEM" 2>/dev/null || stat -c%s "$INPUT_DEM") / $(stat -f%z "$OUTPUT_COG" 2>/dev/null || stat -c%s "$OUTPUT_COG")" | bc)

echo ""
print_success "Conversión completada en ${DURATION}s"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 RESULTADOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Archivo generado: $OUTPUT_COG"
echo "📊 Tamaño original:  $FILE_SIZE"
echo "📊 Tamaño COG:       $OUTPUT_SIZE"
echo "📉 Ratio compresión: ${COMPRESSION_RATIO}x"
echo "⏱️  Tiempo:           ${DURATION}s"
echo ""

# Verificar validez del COG
print_info "Verificando COG..."
if gdalinfo "$OUTPUT_COG" | grep -q "LAYOUT=COG"; then
    print_success "COG válido y optimizado"
else
    print_warning "El archivo se generó pero puede no estar completamente optimizado como COG"
fi

# Mostrar estadísticas del DEM
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📈 ESTADÍSTICAS DEL DEM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Calcular estadísticas si no las tiene
if ! gdalinfo -stats "$OUTPUT_COG" | grep -q "STATISTICS_MINIMUM"; then
    print_info "Calculando estadísticas del terreno..."
    gdalinfo -stats "$OUTPUT_COG" > /dev/null 2>&1
fi

# Mostrar información relevante
gdalinfo "$OUTPUT_COG" | grep -E "Size|Origin|Pixel Size|STATISTICS_" | while read -r line; do
    if [[ $line == *"STATISTICS_MINIMUM"* ]]; then
        MIN_ELEV=$(echo "$line" | sed 's/.*=//')
        echo "🏔️  Altitud mínima:  ${MIN_ELEV}m"
    elif [[ $line == *"STATISTICS_MAXIMUM"* ]]; then
        MAX_ELEV=$(echo "$line" | sed 's/.*=//')
        echo "⛰️  Altitud máxima:  ${MAX_ELEV}m"
    elif [[ $line == *"STATISTICS_MEAN"* ]]; then
        MEAN_ELEV=$(echo "$line" | sed 's/.*=//' | cut -d'.' -f1)
        echo "📊 Altitud media:    ${MEAN_ELEV}m"
    elif [[ $line == *"Size is"* ]]; then
        echo "📐 $line"
    elif [[ $line == *"Pixel Size"* ]]; then
        echo "🔬 $line"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "¡Listo! Tu DEM está optimizado y listo para usar"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "Próximos pasos:"
echo "  1. Mover a assets: mv $OUTPUT_COG assets/data/dem/"
echo "  2. Añadir a pubspec.yaml en la sección flutter/assets"
echo "  3. Usar en tu app con GeoArView"
echo ""
