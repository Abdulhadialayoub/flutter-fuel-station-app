import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/cache_service.dart';

/// Provider for managing location state and GPS updates
/// 
/// Handles:
/// - Location permission requests
/// - Current location tracking
/// - Caching last known location
/// - Real-time location updates
/// - Lifecycle management (background/foreground)
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;
  final CacheService _cacheService;

  Position? _currentPosition;
  bool _permissionGranted = false;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _locationSubscription;
  bool _isTrackingLocation = false;

  LocationProvider(this._locationService, this._cacheService);

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get permissionGranted => _permissionGranted;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTrackingLocation => _isTrackingLocation;

  /// Get current location as LatLng for Google Maps
  LatLng? get currentLatLng => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;

  /// Request location permission from the user
  Future<void> requestPermission() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _permissionGranted = await _locationService.requestPermission();
      
      // If permission granted, get initial location
      if (_permissionGranted) {
        await getCurrentLocation();
      }
    } catch (e) {
      _error = e.toString();
      _permissionGranted = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get the current GPS location and cache it
  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      _currentPosition = position;
      _permissionGranted = true;
      
      // Cache the location
      if (position != null) {
        await _cacheService.cacheLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      _error = e.toString();
      
      // Try to load cached location if GPS fails
      final cachedLocation = await _cacheService.getCachedLocation();
      if (cachedLocation != null) {
        // Create a Position object from cached data
        _currentPosition = Position(
          latitude: cachedLocation['latitude']!,
          longitude: cachedLocation['longitude']!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _error = 'يتم عرض الموقع المحفوظ. $_error';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start receiving real-time location updates
  /// 
  /// Updates the current position whenever the user moves
  /// Should be called when app is in foreground
  void startLocationUpdates() {
    if (_isTrackingLocation) {
      return; // Already tracking
    }

    try {
      _locationSubscription = _locationService.getLocationStream().listen(
        (Position position) {
          _currentPosition = position;
          // Cache location updates
          _cacheService.cacheLocation(position.latitude, position.longitude);
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          notifyListeners();
        },
      );
      
      _isTrackingLocation = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Stop receiving location updates
  /// 
  /// Should be called when app goes to background to conserve battery
  void stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTrackingLocation = false;
    notifyListeners();
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}
