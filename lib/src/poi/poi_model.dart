class Poi {
  final String id;
  final String name;
  final double lat;
  final double lon;
  double? elevation;
  final int importance;
  final String category;
  final String subtype;

  Poi({
    required this.id, required this.name, required this.lat, required this.lon,
    this.elevation, this.importance = 1, this.category = 'generic', this.subtype = 'default',
  });

  String get key => '$category:$subtype';

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'lat': lat, 'lon': lon, 
    'elevation': elevation, 'importance': importance, 'category': category, 'subtype': subtype
  };

  factory Poi.fromMap(Map<String, dynamic> map) {
    return Poi(
      id: map['id'], name: map['name'],
      lat: (map['lat'] as num).toDouble(), lon: (map['lon'] as num).toDouble(),
      elevation: map['elevation']?.toDouble(),
      importance: map['importance'], category: map['category'], subtype: map['subtype'],
    );
  }
}