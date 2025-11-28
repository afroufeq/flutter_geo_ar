#!/bin/bash
# scripts/fetch_dem.sh
# Descarga DEMs de Copernicus o fuente pública.
# Requiere configurar URLs reales.

set -e
DATA_DIR="assets/data/dem"
mkdir -p "$DATA_DIR"

echo "==> Iniciando descarga de DEMs..."

# Ejemplo: Gran Canaria (Sustituir URL con tu fuente real o bucket S3)
# wget -nc -O "$DATA_DIR/gran_canaria.tif" "https://url-to-your-dem/gc.tif"

echo "⚠️  Este script es un placeholder. Configura las URLs de tus COG en el fichero."
echo "DEMs deben guardarse en: $DATA_DIR"