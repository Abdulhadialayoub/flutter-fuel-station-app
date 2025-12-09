/// OSRM API Configuration
/// 
/// OSRM (Open Source Routing Machine) is used for route calculation
/// instead of Google Directions API to save costs.
/// 
/// Public server is free but may have rate limits.
/// For production, consider self-hosting OSRM server.
class OSRMConfig {
  /// Base URL for OSRM API
  /// Public server: https://router.project-osrm.org
  /// Self-hosted: https://your-domain.com
  static const String baseUrl = 'https://router.project-osrm.org';
  
  /// OSRM API version
  static const String apiVersion = 'v1';
  
  /// Routing profile (driving, walking, cycling)
  static const String profile = 'driving';
  
  /// Request timeout in seconds
  static const int timeoutSeconds = 30;
  
  /// Whether to include full route geometry
  /// Set to 'full' to get complete polyline
  static const String overview = 'full';
  
  /// Geometry format
  /// Options: polyline, polyline6, geojson
  /// polyline6 provides better precision (6 decimal places)
  static const String geometries = 'polyline6';
  
  /// Whether to include alternative routes
  static const bool alternatives = false;
  
  /// Whether to include step-by-step instructions
  static const bool steps = false;
  
  /// Build complete OSRM route URL
  static String buildRouteUrl({
    required double originLng,
    required double originLat,
    required double destLng,
    required double destLat,
  }) {
    // OSRM uses longitude,latitude order (opposite of Google Maps)
    final coordinates = '$originLng,$originLat;$destLng,$destLat';
    
    final params = [
      'overview=$overview',
      'geometries=$geometries',
      if (alternatives) 'alternatives=true',
      if (steps) 'steps=true',
    ].join('&');
    
    return '$baseUrl/route/$apiVersion/$profile/$coordinates?$params';
  }
}
