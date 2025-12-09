import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Custom exceptions for location-related errors
class LocationPermissionException implements Exception {
  final String message;
  LocationPermissionException(this.message);
  
  @override
  String toString() => message;
}

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);
  
  @override
  String toString() => message;
}

/// Service for handling GPS location operations
class LocationService {
  /// Check if location permission is granted
  Future<bool> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      throw LocationServiceException('فشل التحقق من صلاحيات الموقع: $e');
    }
  }

  /// Request location permission from the user
  Future<bool> requestPermission() async {
    try {
      // First check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceException('خدمات الموقع غير مفعلة على الجهاز');
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      // If permission is denied forever, we can't request again
      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionException(
          'تم رفض صلاحيات الموقع بشكل دائم. يرجى تفعيلها من إعدادات التطبيق'
        );
      }

      // If permission is denied, request it
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          throw LocationPermissionException('تم رفض صلاحيات الموقع');
        }
        
        if (permission == LocationPermission.deniedForever) {
          throw LocationPermissionException(
            'تم رفض صلاحيات الموقع بشكل دائم. يرجى تفعيلها من إعدادات التطبيق'
          );
        }
      }

      // Permission granted
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      if (e is LocationPermissionException || e is LocationServiceException) {
        rethrow;
      }
      throw LocationServiceException('فشل طلب صلاحيات الموقع: $e');
    }
  }

  /// Get the current GPS position
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if permission is granted
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        throw LocationPermissionException(
          'صلاحيات الموقع غير ممنوحة. يرجى منح الصلاحيات أولاً'
        );
      }

      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceException('خدمات الموقع غير مفعلة على الجهاز');
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw LocationServiceException('انتهت مهلة الحصول على الموقع');
        },
      );

      return position;
    } on LocationPermissionException {
      rethrow;
    } on LocationServiceException {
      rethrow;
    } on TimeoutException {
      throw LocationServiceException('انتهت مهلة الحصول على الموقع');
    } catch (e) {
      throw LocationServiceException('فشل الحصول على الموقع الحالي: $e');
    }
  }

  /// Get a stream of location updates for real-time tracking
  Stream<Position> getLocationStream() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      return Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).handleError((error) {
        throw LocationServiceException('خطأ في تحديثات الموقع: $error');
      });
    } catch (e) {
      throw LocationServiceException('فشل بدء تحديثات الموقع: $e');
    }
  }

  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      throw LocationServiceException('فشل التحقق من خدمات الموقع: $e');
    }
  }
}
