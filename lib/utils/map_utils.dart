import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';

/// Utility class for map-related operations
class MapUtils {
  /// Calculate distance between two coordinates in meters
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    
    final lat1 = point1.latitude * math.pi / 180;
    final lat2 = point2.latitude * math.pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * math.pi / 180;
    
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Check if a point is within the visible bounds
  static bool isPointInBounds(LatLng point, LatLngBounds bounds) {
    return point.latitude >= bounds.southwest.latitude &&
        point.latitude <= bounds.northeast.latitude &&
        point.longitude >= bounds.southwest.longitude &&
        point.longitude <= bounds.northeast.longitude;
  }
  
  /// Filter stations within visible bounds
  static List<Station> filterStationsInBounds(
    List<Station> stations,
    LatLngBounds bounds,
  ) {
    return stations.where((station) {
      final stationLatLng = LatLng(station.latitude, station.longitude);
      return isPointInBounds(stationLatLng, bounds);
    }).toList();
  }
  
  /// Simple marker clustering based on distance
  /// Groups nearby stations into clusters
  static List<MarkerCluster> clusterMarkers(
    List<Station> stations,
    double clusterRadius, // in meters
  ) {
    final clusters = <MarkerCluster>[];
    final processed = <String>{};
    
    for (final station in stations) {
      if (processed.contains(station.id)) continue;
      
      final stationLatLng = LatLng(station.latitude, station.longitude);
      final cluster = MarkerCluster(
        center: stationLatLng,
        stations: [station],
      );
      
      processed.add(station.id);
      
      // Find nearby stations to add to this cluster
      for (final otherStation in stations) {
        if (processed.contains(otherStation.id)) continue;
        
        final otherLatLng = LatLng(otherStation.latitude, otherStation.longitude);
        final distance = calculateDistance(stationLatLng, otherLatLng);
        
        if (distance <= clusterRadius) {
          cluster.stations.add(otherStation);
          processed.add(otherStation.id);
        }
      }
      
      clusters.add(cluster);
    }
    
    return clusters;
  }
  
  /// Calculate cluster center from multiple stations
  static LatLng calculateClusterCenter(List<Station> stations) {
    if (stations.isEmpty) {
      return const LatLng(0, 0);
    }
    
    double totalLat = 0;
    double totalLng = 0;
    
    for (final station in stations) {
      totalLat += station.latitude;
      totalLng += station.longitude;
    }
    
    return LatLng(
      totalLat / stations.length,
      totalLng / stations.length,
    );
  }
  
  /// Determine if clustering should be enabled based on zoom level
  static bool shouldCluster(double zoomLevel) {
    // Enable clustering when zoomed out (zoom < 13)
    return zoomLevel < 13.0;
  }
  
  /// Calculate appropriate cluster radius based on zoom level
  static double getClusterRadius(double zoomLevel) {
    // Larger radius when zoomed out, smaller when zoomed in
    if (zoomLevel < 10) {
      return 5000; // 5km
    } else if (zoomLevel < 12) {
      return 2000; // 2km
    } else if (zoomLevel < 13) {
      return 1000; // 1km
    } else {
      return 500; // 500m (no clustering)
    }
  }
}

/// Represents a cluster of markers
class MarkerCluster {
  final LatLng center;
  final List<Station> stations;
  
  MarkerCluster({
    required this.center,
    required this.stations,
  });
  
  bool get isSingleStation => stations.length == 1;
  
  Station get singleStation => stations.first;
  
  int get count => stations.length;
}
