import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_station_app/services/osrm_service.dart';

void main() {
  group('OSRMService', () {
    late OSRMService osrmService;

    setUp(() {
      osrmService = OSRMService();
    });

    test('decodePolyline should decode empty string to empty list', () {
      final result = osrmService.decodePolyline('');
      expect(result, isEmpty);
    });

    test('decodePolyline should decode valid polyline6 string', () {
      // Sample polyline6 encoded string (represents a simple path)
      // This is a known test case for polyline6 encoding
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      
      final result = osrmService.decodePolyline(encoded);
      
      expect(result, isNotEmpty);
      expect(result.length, greaterThan(0));
      
      // Verify all coordinates are valid
      for (final coord in result) {
        expect(coord.latitude, inInclusiveRange(-90, 90));
        expect(coord.longitude, inInclusiveRange(-180, 180));
      }
    });

    test('extractDistance should return distance in kilometers', () {
      final result = OSRMRouteResult(
        distance: 5000, // 5000 meters
        duration: 300,
        geometry: '',
      );

      final distance = osrmService.extractDistance(result);
      expect(distance, equals(5.0)); // 5 km
    });

    test('extractRouteCoordinates should decode geometry from result', () {
      final result = OSRMRouteResult(
        distance: 1000,
        duration: 100,
        geometry: '_p~iF~ps|U_ulLnnqC',
      );

      final coordinates = osrmService.extractRouteCoordinates(result);
      expect(coordinates, isNotEmpty);
    });

    test('OSRMRouteResult.distanceInKm should convert meters to km', () {
      final result = OSRMRouteResult(
        distance: 12345,
        duration: 600,
        geometry: '',
      );

      expect(result.distanceInKm, equals(12.345));
    });

    test('OSRMRouteResult.fromJson should parse JSON correctly', () {
      final json = {
        'distance': 10000.5,
        'duration': 500.25,
        'geometry': 'test_geometry_string',
      };

      final result = OSRMRouteResult.fromJson(json);

      expect(result.distance, equals(10000.5));
      expect(result.duration, equals(500.25));
      expect(result.geometry, equals('test_geometry_string'));
      expect(result.distanceInKm, equals(10.0005));
    });
  });
}
