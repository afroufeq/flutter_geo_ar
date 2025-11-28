#!/usr/bin/env python3
"""
Script para convertir POIs de diferentes formatos al formato JSON optimizado del plugin flutter_geo_ar.

Formatos soportados:
- GeoJSON (.geojson, .json)
- KML (.kml)
- CSV (.csv, .txt)
- GPX (.gpx)

Uso:
    python convert_pois.py input_file.geojson output_file.json
    python convert_pois.py input_file.kml output_file.json --min-importance 5
"""

import json
import csv
import xml.etree.ElementTree as ET
import argparse
import sys
from pathlib import Path
from typing import List, Dict, Any, Optional


def infer_importance(category: str) -> int:
    """Infiere la importancia basándose en la categoría."""
    category_lower = category.lower()
    
    if 'peak' in category_lower or 'summit' in category_lower or 'pico' in category_lower:
        return 8
    if 'viewpoint' in category_lower or 'mirador' in category_lower:
        return 7
    if 'city' in category_lower or 'town' in category_lower or 'ciudad' in category_lower:
        return 6
    if 'village' in category_lower or 'hamlet' in category_lower or 'pueblo' in category_lower:
        return 4
    if 'shelter' in category_lower or 'refuge' in category_lower or 'refugio' in category_lower:
        return 5
    
    return 1


def infer_category(text: str) -> str:
    """Infiere la categoría desde texto descriptivo."""
    text_lower = text.lower()
    
    if 'peak' in text_lower or 'pico' in text_lower or 'cumbre' in text_lower:
        return 'natural:peak'
    if 'viewpoint' in text_lower or 'mirador' in text_lower or 'vista' in text_lower:
        return 'tourism:viewpoint'
    if 'shelter' in text_lower or 'refugio' in text_lower or 'refuge' in text_lower:
        return 'amenity:shelter'
    if 'beach' in text_lower or 'playa' in text_lower:
        return 'tourism:beach'
    if 'restaurant' in text_lower or 'restaurante' in text_lower:
        return 'amenity:restaurant'
    if 'hotel' in text_lower:
        return 'tourism:hotel'
    if 'parking' in text_lower or 'aparcamiento' in text_lower:
        return 'amenity:parking'
    if 'monument' in text_lower or 'monumento' in text_lower:
        return 'historic:monument'
    
    return 'generic'


def parse_geojson(file_path: str) -> List[Dict[str, Any]]:
    """Parsea un archivo GeoJSON y retorna lista de POIs."""
    print(f"📍 Parseando GeoJSON: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if data.get('type') != 'FeatureCollection':
        raise ValueError('GeoJSON inválido: se esperaba un FeatureCollection')
    
    features = data.get('features', [])
    pois = []
    
    for i, feature in enumerate(features):
        if feature.get('type') != 'Feature':
            continue
        
        geometry = feature.get('geometry', {})
        if geometry.get('type') != 'Point':
            continue
        
        coordinates = geometry.get('coordinates', [])
        if len(coordinates) < 2:
            continue
        
        lon, lat = coordinates[0], coordinates[1]
        elevation = coordinates[2] if len(coordinates) > 2 else None
        
        properties = feature.get('properties', {})
        name = properties.get('name') or properties.get('title') or f'POI {i+1}'
        poi_id = properties.get('id') or f'geojson_{i+1}'
        category = properties.get('category') or properties.get('type') or 'generic'
        subtype = properties.get('subtype') or 'default'
        
        importance = properties.get('importance')
        if importance is None:
            importance = infer_importance(category)
        
        pois.append({
            'id': str(poi_id),
            'name': name,
            'lat': float(lat),
            'lon': float(lon),
            'elevation': float(elevation) if elevation is not None else None,
            'importance': int(importance),
            'category': category,
            'subtype': subtype
        })
    
    print(f"✅ {len(pois)} POIs parseados desde GeoJSON")
    return pois


def parse_kml(file_path: str) -> List[Dict[str, Any]]:
    """Parsea un archivo KML y retorna lista de POIs."""
    print(f"📍 Parseando KML: {file_path}")
    
    tree = ET.parse(file_path)
    root = tree.getroot()
    
    # Manejar namespace de KML
    ns = {'kml': 'http://www.opengis.net/kml/2.2'}
    if root.tag.startswith('{'):
        ns['kml'] = root.tag.split('}')[0].strip('{')
    
    pois = []
    placemarks = root.findall('.//kml:Placemark', ns) or root.findall('.//Placemark')
    
    for i, placemark in enumerate(placemarks):
        # Buscar Point
        point = placemark.find('.//kml:Point', ns) or placemark.find('.//Point')
        if point is None:
            continue
        
        # Extraer coordenadas
        coords_elem = point.find('.//kml:coordinates', ns) or point.find('.//coordinates')
        if coords_elem is None:
            continue
        
        coords_text = coords_elem.text.strip()
        coords_parts = coords_text.split(',')
        
        if len(coords_parts) < 2:
            continue
        
        try:
            lon = float(coords_parts[0])
            lat = float(coords_parts[1])
            elevation = float(coords_parts[2]) if len(coords_parts) > 2 else None
        except (ValueError, IndexError):
            continue
        
        # Extraer nombre
        name_elem = placemark.find('.//kml:name', ns) or placemark.find('.//name')
        name = name_elem.text.strip() if name_elem is not None and name_elem.text else f'POI {i+1}'
        
        # Extraer descripción
        desc_elem = placemark.find('.//kml:description', ns) or placemark.find('.//description')
        description = desc_elem.text if desc_elem is not None and desc_elem.text else ''
        
        # Extraer styleUrl
        style_elem = placemark.find('.//kml:styleUrl', ns) or placemark.find('.//styleUrl')
        style_url = style_elem.text if style_elem is not None and style_elem.text else ''
        
        # Inferir categoría
        text = f'{name} {description} {style_url}'
        category = infer_category(text)
        importance = infer_importance(category)
        
        pois.append({
            'id': f'kml_{i+1}',
            'name': name,
            'lat': lat,
            'lon': lon,
            'elevation': elevation,
            'importance': importance,
            'category': category,
            'subtype': 'default'
        })
    
    print(f"✅ {len(pois)} POIs parseados desde KML")
    return pois


def parse_csv(file_path: str) -> List[Dict[str, Any]]:
    """Parsea un archivo CSV y retorna lista de POIs."""
    print(f"📍 Parseando CSV: {file_path}")
    
    pois = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        # Detectar si tiene header
        sample = f.read(1024)
        f.seek(0)
        
        sniffer = csv.Sniffer()
        has_header = sniffer.has_header(sample)
        
        reader = csv.DictReader(f) if has_header else csv.reader(f)
        
        for i, row in enumerate(reader):
            if has_header:
                # Con header: mapear columnas
                lat = row.get('lat') or row.get('latitude') or row.get('Lat') or row.get('Latitude')
                lon = row.get('lon') or row.get('longitude') or row.get('lng') or row.get('Lon') or row.get('Longitude')
                name = row.get('name') or row.get('nombre') or row.get('title') or row.get('Name') or f'POI {i+1}'
                elevation = row.get('elevation') or row.get('alt') or row.get('altitude')
                category = row.get('category') or row.get('type') or row.get('Category') or 'generic'
                importance = row.get('importance') or row.get('Importance')
            else:
                # Sin header: orden estándar (lat, lon, name, elevation, category, importance)
                if len(row) < 3:
                    continue
                lat = row[0]
                lon = row[1]
                name = row[2] if len(row) > 2 else f'POI {i+1}'
                elevation = row[3] if len(row) > 3 else None
                category = row[4] if len(row) > 4 else 'generic'
                importance = row[5] if len(row) > 5 else None
            
            if not lat or not lon:
                continue
            
            try:
                lat = float(lat)
                lon = float(lon)
                elevation = float(elevation) if elevation and elevation.strip() else None
                importance = int(importance) if importance and str(importance).strip() else None
            except (ValueError, AttributeError):
                continue
            
            if importance is None:
                importance = infer_importance(category)
            
            pois.append({
                'id': f'csv_{i+1}',
                'name': name,
                'lat': lat,
                'lon': lon,
                'elevation': elevation,
                'importance': importance,
                'category': category,
                'subtype': 'default'
            })
    
    print(f"✅ {len(pois)} POIs parseados desde CSV")
    return pois


def parse_gpx(file_path: str) -> List[Dict[str, Any]]:
    """Parsea un archivo GPX y retorna lista de POIs (waypoints)."""
    print(f"📍 Parseando GPX: {file_path}")
    
    tree = ET.parse(file_path)
    root = tree.getroot()
    
    # Manejar namespace de GPX
    ns = {'gpx': 'http://www.topografix.com/GPX/1/1'}
    if root.tag.startswith('{'):
        ns['gpx'] = root.tag.split('}')[0].strip('{')
    
    pois = []
    waypoints = root.findall('.//gpx:wpt', ns) or root.findall('.//wpt')
    
    for i, wpt in enumerate(waypoints):
        lat = wpt.get('lat')
        lon = wpt.get('lon')
        
        if not lat or not lon:
            continue
        
        try:
            lat = float(lat)
            lon = float(lon)
        except ValueError:
            continue
        
        # Extraer elevación
        ele_elem = wpt.find('.//gpx:ele', ns) or wpt.find('.//ele')
        elevation = float(ele_elem.text) if ele_elem is not None and ele_elem.text else None
        
        # Extraer nombre
        name_elem = wpt.find('.//gpx:name', ns) or wpt.find('.//name')
        name = name_elem.text.strip() if name_elem is not None and name_elem.text else f'POI {i+1}'
        
        # Extraer tipo
        type_elem = wpt.find('.//gpx:type', ns) or wpt.find('.//type')
        category = type_elem.text.strip() if type_elem is not None and type_elem.text else 'generic'
        
        # Extraer descripción
        desc_elem = wpt.find('.//gpx:desc', ns) or wpt.find('.//desc')
        description = desc_elem.text if desc_elem is not None and desc_elem.text else ''
        
        # Si la categoría no está clara, inferir desde nombre/descripción
        if category == 'generic' or not category:
            category = infer_category(f'{name} {description}')
        
        importance = infer_importance(category)
        
        pois.append({
            'id': f'gpx_{i+1}',
            'name': name,
            'lat': lat,
            'lon': lon,
            'elevation': elevation,
            'importance': importance,
            'category': category,
            'subtype': 'default'
        })
    
    print(f"✅ {len(pois)} POIs parseados desde GPX")
    return pois


def filter_pois(pois: List[Dict[str, Any]], min_importance: Optional[int] = None) -> List[Dict[str, Any]]:
    """Filtra POIs por importancia mínima."""
    if min_importance is None:
        return pois
    
    filtered = [poi for poi in pois if poi.get('importance', 0) >= min_importance]
    print(f"🔍 Filtrados {len(pois) - len(filtered)} POIs por importancia mínima {min_importance}")
    return filtered


def save_pois(pois: List[Dict[str, Any]], output_path: str):
    """Guarda POIs en formato JSON optimizado del plugin."""
    print(f"💾 Guardando {len(pois)} POIs en: {output_path}")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(pois, f, ensure_ascii=False, indent=2)
    
    print(f"✅ POIs guardados exitosamente")


def main():
    parser = argparse.ArgumentParser(
        description='Convierte POIs de diferentes formatos al formato JSON del plugin flutter_geo_ar',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  python convert_pois.py input.geojson output.json
  python convert_pois.py input.kml output.json --min-importance 5
  python convert_pois.py input.csv output.json
  python convert_pois.py waypoints.gpx output.json
        """
    )
    
    parser.add_argument('input', help='Archivo de entrada (GeoJSON, KML, CSV, GPX)')
    parser.add_argument('output', help='Archivo de salida (JSON)')
    parser.add_argument('--min-importance', type=int, help='Importancia mínima para incluir POIs (1-10)')
    
    args = parser.parse_args()
    
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"❌ Error: El archivo {args.input} no existe")
        sys.exit(1)
    
    # Detectar formato por extensión
    extension = input_path.suffix.lower()
    
    try:
        if extension in ['.geojson', '.json']:
            pois = parse_geojson(str(input_path))
        elif extension == '.kml':
            pois = parse_kml(str(input_path))
        elif extension in ['.csv', '.txt']:
            pois = parse_csv(str(input_path))
        elif extension == '.gpx':
            pois = parse_gpx(str(input_path))
        else:
            print(f"❌ Error: Formato no soportado: {extension}")
            print("Formatos soportados: .geojson, .json, .kml, .csv, .txt, .gpx")
            sys.exit(1)
        
        # Filtrar por importancia si se especifica
        pois = filter_pois(pois, args.min_importance)
        
        if not pois:
            print("⚠️  Advertencia: No se encontraron POIs para guardar")
            sys.exit(0)
        
        # Guardar resultado
        save_pois(pois, args.output)
        
        print(f"\n🎉 Conversión completada exitosamente!")
        print(f"📊 Total de POIs: {len(pois)}")
        
    except Exception as e:
        print(f"❌ Error durante la conversión: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
