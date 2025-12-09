import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/osrm_config.dart';
import 'exceptions.dart';

/// Service for route calculation using OSRM API
/// 
/// OSRM (Open Source Routing Machine) is a free, open-source routing service
/// used instead of Google Directions API to save costs.
class OSRMService {
  final Dio _dio;

  OSRMService({
    Dio? dio,
  })  : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = Duration(seconds: OSRMConfig.timeoutSeconds);
    _dio.options.receiveTimeout = Duration(seconds: OSRMConfig.timeoutSeconds);
  }

  /// Get route from origin to destination using OSRM API
  /// 
  /// Returns an OSRMRouteResult containing distance, duration, and encoded geometry
  /// 
  /// Throws:
  /// - [NetworkException] for network-related errors
  /// - [OSRMException] for OSRM API errors
  /// - [TimeoutException] for timeout errors
  Future<OSRMRouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // Build OSRM URL (note: OSRM uses lng,lat order)
      final url = OSRMConfig.buildRouteUrl(
        originLng: origin.longitude,
        originLat: origin.latitude,
        destLng: destination.longitude,
        destLat: destination.latitude,
      );

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Check if OSRM returned an error
        if (data['code'] != 'Ok') {
          throw OSRMException(
            'فشل حساب المسار: ${data['message'] ?? 'خطأ غير معروف'}',
          );
        }

        // Extract first route
        final routes = data['routes'] as List<dynamic>?;
        if (routes == null || routes.isEmpty) {
          throw OSRMException('لم يتم العثور على مسار');
        }

        final route = routes[0] as Map<String, dynamic>;
        return OSRMRouteResult.fromJson(route);
      } else {
        throw OSRMException(
          'فشل الاتصال بخدمة المسارات: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('انتهت مهلة الاتصال');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('لا يوجد اتصال بالإنترنت');
      } else {
        throw OSRMException('حدث خطأ أثناء حساب المسار: ${e.message}');
      }
    } catch (e) {
      if (e is OSRMException || e is NetworkException) {
        rethrow;
      }
      throw OSRMException('حدث خطأ غير متوقع: $e');
    }
  }

  /// Extract distance in kilometers from OSRM result
  double extractDistance(OSRMRouteResult result) {
    return result.distanceInKm;
  }

  /// Extract route coordinates from OSRM result for drawing on map
  List<LatLng> extractRouteCoordinates(OSRMRouteResult result) {
    return decodePolyline(result.geometry);
  }

  /// Decode OSRM polyline6 format into list of LatLng coordinates
  /// 
  /// OSRM uses polyline6 encoding (6 decimal places precision)
  /// This is different from Google's polyline5 encoding
  List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) {
      return [];
    }

    List<LatLng> coordinates = [];
    int index = 0;
    int lat = 0;
    int lng = 0;
    
    // Polyline6 uses precision factor of 1e6 (6 decimal places)
    const int precision = 1000000;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      // Decode latitude
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      // Decode longitude
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      // Convert to double with precision factor
      double latitude = lat / precision;
      double longitude = lng / precision;

      coordinates.add(LatLng(latitude, longitude));
    }

    return coordinates;
  }
}

/// Result from OSRM route API
class OSRMRouteResult {
  final double distance; // in meters
  final double duration; // in seconds
  final String geometry; // encoded polyline

  OSRMRouteResult({
    required this.distance,
    required this.duration,
    required this.geometry,
  });

  factory OSRMRouteResult.fromJson(Map<String, dynamic> json) {
    return OSRMRouteResult(
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      geometry: json['geometry'] as String,
    );
  }

  /// Get distance in kilometers
  double get distanceInKm => distance / 1000;
}
