class FusedData {
  final double? heading;
  final double? pitch;
  final double? roll;
  final double? lat;
  final double? lon;
  final double? alt;
  final int ts;

  const FusedData({
    this.heading, this.pitch, this.roll,
    this.lat, this.lon, this.alt,
    required this.ts
  });

  Map<String, dynamic> toMap() => {
    'heading': heading, 'pitch': pitch, 'roll': roll,
    'lat': lat, 'lon': lon, 'alt': alt, 'ts': ts,
  };
  
  static FusedData fromMap(Map<String, dynamic> map) {
    return FusedData(
      heading: map['heading'], pitch: map['pitch'], roll: map['roll'],
      lat: map['lat'], lon: map['lon'], alt: map['alt'], ts: map['ts'] ?? 0,
    );
  }
}