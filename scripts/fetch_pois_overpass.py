import requests, json, argparse

def fetch(bbox, out):
    minLon, minLat, maxLon, maxLat = map(str.strip, bbox.split(","))
    query = f"""[out:json][timeout:25];(node["natural"="peak"]({minLat},{minLon},{maxLat},{maxLon}););out;"""
    r = requests.post("https://overpass-api.de/api/interpreter", data={'data': query})
    data = r.json()
    pois = []
    for el in data.get('elements', []):
        pois.append({
            'id': str(el.get('id')),
            'name': el.get('tags', {}).get('name', 'Unknown'),
            'lat': el.get('lat'), 'lon': el.get('lon'),
            'category': 'natural', 'subtype': 'peak', 'importance': 1
        })
    with open(out, 'w') as f: json.dump(pois, f, indent=2)

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--bbox', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    fetch(args.bbox, args.out)