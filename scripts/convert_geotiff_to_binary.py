#!/usr/bin/env python3
"""
Convierte un archivo GeoTIFF a formato binario personalizado para DemService.

Formato de salida:
- Primeros 32 bytes: Metadatos
  * 0-3:   width (Int32, little endian)
  * 4-7:   height (Int32, little endian)
  * 8-15:  minLat (Float64, little endian)
  * 16-23: minLon (Float64, little endian)
  * 24-31: maxLat (Float64, little endian)
- Resto: Datos de elevación (Float32, little endian, row-major order)

Uso:
    python convert_geotiff_to_binary.py input.tif output.bin
"""

import sys
import struct
import numpy as np
from osgeo import gdal


def convert_geotiff_to_binary(input_path, output_path):
    """
    Convierte un archivo GeoTIFF al formato binario personalizado.
    
    Args:
        input_path: Ruta al archivo GeoTIFF de entrada
        output_path: Ruta al archivo binario de salida
    """
    print(f"📖 Leyendo GeoTIFF: {input_path}")
    
    # Abrir el archivo GeoTIFF
    dataset = gdal.Open(input_path, gdal.GA_ReadOnly)
    if dataset is None:
        print(f"❌ Error: No se pudo abrir el archivo {input_path}")
        sys.exit(1)
    
    # Obtener dimensiones
    width = dataset.RasterXSize
    height = dataset.RasterYSize
    
    print(f"📐 Dimensiones: {width} x {height}")
    
    # Obtener transformación geográfica
    # [0] = x origin (top left corner)
    # [1] = pixel width
    # [2] = rotation (0 for north-up)
    # [3] = y origin (top left corner)
    # [4] = rotation (0 for north-up)
    # [5] = pixel height (negative value)
    geotransform = dataset.GetGeoTransform()
    
    # Calcular coordenadas geográficas
    minLon = geotransform[0]
    maxLat = geotransform[3]
    pixelWidth = geotransform[1]
    pixelHeight = abs(geotransform[5])
    
    maxLon = minLon + (width * pixelWidth)
    minLat = maxLat - (height * pixelHeight)
    
    print(f"🌍 Coordenadas:")
    print(f"   Min Lat: {minLat:.6f}")
    print(f"   Max Lat: {maxLat:.6f}")
    print(f"   Min Lon: {minLon:.6f}")
    print(f"   Max Lon: {maxLon:.6f}")
    
    # Leer datos de elevación
    print("📊 Leyendo datos de elevación...")
    band = dataset.GetRasterBand(1)
    elevation_data = band.ReadAsArray()
    
    # Obtener estadísticas
    nodata = band.GetNoDataValue()
    if nodata is not None:
        valid_data = elevation_data[elevation_data != nodata]
    else:
        valid_data = elevation_data.flatten()
    
    if len(valid_data) > 0:
        min_elev = np.min(valid_data)
        max_elev = np.max(valid_data)
        mean_elev = np.mean(valid_data)
        
        print(f"⛰️  Elevación:")
        print(f"   Mínima: {min_elev:.1f}m")
        print(f"   Máxima: {max_elev:.1f}m")
        print(f"   Media:  {mean_elev:.1f}m")
    
    # Reemplazar valores NoData con 0
    if nodata is not None:
        elevation_data[elevation_data == nodata] = 0
    
    # Convertir a Float32
    elevation_data = elevation_data.astype(np.float32)
    
    # Crear archivo binario
    print(f"💾 Escribiendo archivo binario: {output_path}")
    
    with open(output_path, 'wb') as f:
        # Escribir metadatos (32 bytes)
        # width (Int32)
        f.write(struct.pack('<i', width))
        # height (Int32)
        f.write(struct.pack('<i', height))
        # minLat (Float64)
        f.write(struct.pack('<d', minLat))
        # minLon (Float64)
        f.write(struct.pack('<d', minLon))
        # maxLat (Float64)
        f.write(struct.pack('<d', maxLat))
        
        # Escribir datos de elevación (Float32, row-major order)
        elevation_data.tofile(f)
    
    # Verificar tamaño del archivo
    import os
    file_size = os.path.getsize(output_path)
    expected_size = 32 + (width * height * 4)  # 4 bytes por Float32
    
    if file_size == expected_size:
        print(f"✅ Archivo creado correctamente")
        print(f"   Tamaño: {file_size / (1024*1024):.2f} MB")
    else:
        print(f"⚠️  Advertencia: Tamaño de archivo inesperado")
        print(f"   Esperado: {expected_size} bytes")
        print(f"   Obtenido: {file_size} bytes")
    
    # Cerrar dataset
    dataset = None
    
    print("🎉 Conversión completada!")


def main():
    if len(sys.argv) != 3:
        print("Uso: python convert_geotiff_to_binary.py <input.tif> <output.bin>")
        print()
        print("Ejemplo:")
        print("  python convert_geotiff_to_binary.py gran_canaria_cog.tif gran_canaria.bin")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    
    try:
        convert_geotiff_to_binary(input_path, output_path)
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
