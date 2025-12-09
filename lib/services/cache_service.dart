import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Service for caching data locally using SharedPreferences
/// 
/// Caches:
/// - Stations data
/// - Fuel prices data
/// - Last known location
/// 
/// Each cache entry has an expiration time to ensure data freshness
class CacheService {
  static const String _stationsKey = 'cached_stations';
  static const String _stationsTimestampKey = 'cached_stations_timestamp';
  static const String _fuelTypesKey = 'cached_fuel_types';
  static const String _fuelTypesTimestampKey = 'cached_fuel_types_timestamp';
  static const String _lastLocationKey = 'cached_last_location';
  static const String _lastLocationTimestampKey = 'cached_last_location_timestamp';

  // Cache expiration times (in hours)
  static const int _stationsCacheExpiration = 24; // 24 hours
  static const int _fuelTypesCacheExpiration = 6; // 6 hours
  static const int _locationCacheExpiration = 1; // 1 hour

  final SharedPreferences _prefs;

  CacheService(this._prefs);

  // ==================== Stations Cache ====================

  /// Cache stations data
  Future<void> cacheStations(List<Station> stations) async {
    try {
      final jsonList = stations.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_stationsKey, jsonString);
      await _prefs.setInt(_stationsTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silently fail - caching is not critical
      print('Failed to cache stations: $e');
    }
  }

  /// Get cached stations if available and not expired
  Future<List<Station>?> getCachedStations() async {
    try {
      final jsonString = _prefs.getString(_stationsKey);
      final timestamp = _prefs.getInt(_stationsTimestampKey);

      if (jsonString == null || timestamp == null) {
        return null;
      }

      // Check if cache is expired
      if (_isCacheExpired(timestamp, _stationsCacheExpiration)) {
        return null;
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => Station.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Failed to get cached stations: $e');
      return null;
    }
  }

  /// Check if stations cache exists (even if expired)
  bool hasStationsCache() {
    return _prefs.containsKey(_stationsKey);
  }

  /// Check if stations cache is stale (expired)
  bool isStationsCacheStale() {
    final timestamp = _prefs.getInt(_stationsTimestampKey);
    if (timestamp == null) return true;
    return _isCacheExpired(timestamp, _stationsCacheExpiration);
  }

  // ==================== Fuel Types Cache ====================

  /// Cache fuel types data
  Future<void> cacheFuelTypes(List<FuelType> fuelTypes) async {
    try {
      final jsonList = fuelTypes.map((f) => f.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_fuelTypesKey, jsonString);
      await _prefs.setInt(_fuelTypesTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Failed to cache fuel types: $e');
    }
  }

  /// Get cached fuel types if available and not expired
  Future<List<FuelType>?> getCachedFuelTypes() async {
    try {
      final jsonString = _prefs.getString(_fuelTypesKey);
      final timestamp = _prefs.getInt(_fuelTypesTimestampKey);

      if (jsonString == null || timestamp == null) {
        return null;
      }

      // Check if cache is expired
      if (_isCacheExpired(timestamp, _fuelTypesCacheExpiration)) {
        return null;
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => FuelType.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Failed to get cached fuel types: $e');
      return null;
    }
  }

  /// Check if fuel types cache exists (even if expired)
  bool hasFuelTypesCache() {
    return _prefs.containsKey(_fuelTypesKey);
  }

  /// Check if fuel types cache is stale (expired)
  bool isFuelTypesCacheStale() {
    final timestamp = _prefs.getInt(_fuelTypesTimestampKey);
    if (timestamp == null) return true;
    return _isCacheExpired(timestamp, _fuelTypesCacheExpiration);
  }

  // ==================== Location Cache ====================

  /// Cache last known location
  Future<void> cacheLocation(double latitude, double longitude) async {
    try {
      final locationData = {'latitude': latitude, 'longitude': longitude};
      final jsonString = jsonEncode(locationData);
      await _prefs.setString(_lastLocationKey, jsonString);
      await _prefs.setInt(_lastLocationTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Failed to cache location: $e');
    }
  }

  /// Get cached location if available and not expired
  Future<Map<String, double>?> getCachedLocation() async {
    try {
      final jsonString = _prefs.getString(_lastLocationKey);
      final timestamp = _prefs.getInt(_lastLocationTimestampKey);

      if (jsonString == null || timestamp == null) {
        return null;
      }

      // Check if cache is expired
      if (_isCacheExpired(timestamp, _locationCacheExpiration)) {
        return null;
      }

      final locationData = jsonDecode(jsonString) as Map<String, dynamic>;
      return {
        'latitude': locationData['latitude'] as double,
        'longitude': locationData['longitude'] as double,
      };
    } catch (e) {
      print('Failed to get cached location: $e');
      return null;
    }
  }

  /// Check if location cache exists (even if expired)
  bool hasLocationCache() {
    return _prefs.containsKey(_lastLocationKey);
  }

  /// Check if location cache is stale (expired)
  bool isLocationCacheStale() {
    final timestamp = _prefs.getInt(_lastLocationTimestampKey);
    if (timestamp == null) return true;
    return _isCacheExpired(timestamp, _locationCacheExpiration);
  }

  // ==================== Helper Methods ====================

  /// Check if a cache entry is expired based on timestamp and expiration hours
  bool _isCacheExpired(int timestamp, int expirationHours) {
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    return difference.inHours >= expirationHours;
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _prefs.remove(_stationsKey);
    await _prefs.remove(_stationsTimestampKey);
    await _prefs.remove(_fuelTypesKey);
    await _prefs.remove(_fuelTypesTimestampKey);
    await _prefs.remove(_lastLocationKey);
    await _prefs.remove(_lastLocationTimestampKey);
  }

  /// Clear stations cache
  Future<void> clearStationsCache() async {
    await _prefs.remove(_stationsKey);
    await _prefs.remove(_stationsTimestampKey);
  }

  /// Clear fuel types cache
  Future<void> clearFuelTypesCache() async {
    await _prefs.remove(_fuelTypesKey);
    await _prefs.remove(_fuelTypesTimestampKey);
  }

  /// Clear location cache
  Future<void> clearLocationCache() async {
    await _prefs.remove(_lastLocationKey);
    await _prefs.remove(_lastLocationTimestampKey);
  }
}
