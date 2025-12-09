import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'fuel_type.dart';

class TripCalculation {
  final double distance; // in kilometers
  final double fuelNeeded; // in liters
  final double totalCost;
  final String currency;
  final FuelType fuelType;
  final List<LatLng> routeCoordinates;

  TripCalculation({
    required this.distance,
    required this.fuelNeeded,
    required this.totalCost,
    required this.currency,
    required this.fuelType,
    required this.routeCoordinates,
  });
}
