#!/usr/bin/env python3
"""
Script para preprocesar JSON de Overpass a formato plano Sembast.
Uso: python3 preprocess_pois.py input.json output.json
"""
import json
import sys

def convert(input_file, output_file):
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Fichero {input_file} no encontrado.")
        sys.exit(1)

    out_pois = []
    # Overpass puede devolver una lista directa o un objeto con key 'elements'
    elements = data.get('elements', data) if isinstance(data, dict) else data
    
    for el in elements:
        # Ignorar nodos sin geometría
        if 'lat' not in el or 'lon' not in el:
            continue

        tags = el.get('tags', {})
        
        # Detectar tipo
        category = tags.get('natural', tags.get('tourism', tags.get('amenity', tags.get('historic', 'generic'))))
        subtype = tags.get('peak', tags.get('viewpoint', 'default'))
        
        # Calcular importancia simple basada en etiquetas
        importance = 1
        if 'peak' in subtype: importance = 3
        if 'volcano' in tags.get('volcano:type', ''): importance = 5

        poi = {
            'id': str(el.get('id')),
            'name': tags.get('name', tags.get('ref', 'Desconocido')),
            'lat': el.get('lat'),
            'lon': el.get('lon'),
            'elevation': None, # Se rellenará en la app con DEM
            'category': category,
            'subtype': subtype,
            'importance': importance
        }
        out_pois.append(poi)

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(out_pois, f, indent=2, ensure_ascii=False)
    print(f"✅ Procesados {len(out_pois)} POIs. Guardado en {output_file}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python3 preprocess_pois.py <input> <output>")
    else:
        convert(sys.argv[1], sys.argv[2])