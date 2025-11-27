class FusedData {
  final double? heading;
  final double? pitch;
  final double? roll;
  final double? lat;
  final double? lon;
  final double? alt;
  final int ts;

  // Campos de precisión de sensores
  final int? magnetometerAccuracy; // Android: 0-3 (0=unreliable, 1=low, 2=medium, 3=high)
  final double? headingAccuracy; // iOS: grados de precisión (negativo=inválido)

  const FusedData({
    this.heading,
    this.pitch,
    this.roll,
    this.lat,
    this.lon,
    this.alt,
    required this.ts,
    this.magnetometerAccuracy,
    this.headingAccuracy,
  });

  Map<String, dynamic> toMap() => {
        'heading': heading,
        'pitch': pitch,
        'roll': roll,
        'lat': lat,
        'lon': lon,
        'alt': alt,
        'ts': ts,
        'magnetometerAccuracy': magnetometerAccuracy,
        'headingAccuracy': headingAccuracy,
      };

  static FusedData fromMap(Map<String, dynamic> map) {
    return FusedData(
      heading: map['heading'],
      pitch: map['pitch'],
      roll: map['roll'],
      lat: map['lat'],
      lon: map['lon'],
      alt: map['alt'],
      ts: map['ts'] ?? 0,
      magnetometerAccuracy: map['magnetometerAccuracy'],
      headingAccuracy: map['headingAccuracy'],
    );
  }
}
