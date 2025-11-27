// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_geo_ar/flutter_geo_ar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GeoArView widget can be instantiated', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final testPoi = Poi(id: 'test_poi', name: 'Test POI', lat: 28.0, lon: -15.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GeoArView(pois: [testPoi])),
      ),
    );

    // Verify that GeoArView widget is created
    expect(find.byType(GeoArView), findsOneWidget);
  });

  test('Poi can be instantiated', () {
    // Verify that Poi class is accessible
    final poi = Poi(id: 'test_poi', name: 'Test POI', lat: 28.0, lon: -15.0, elevation: 100.0);

    expect(poi.id, 'test_poi');
    expect(poi.name, 'Test POI');
    expect(poi.lat, 28.0);
    expect(poi.lon, -15.0);
    expect(poi.elevation, 100.0);
  });
}
