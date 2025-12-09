import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';
import '../services/osrm_service.dart';
import '../services/connectivity_service.dart';
import '../utils/retry_helper.dart';

/// Provider for managing trip calculation state
/// 
/// Handles:
/// - Trip cost calculation using OSRM for distance
/// - Formula: (distance / 100) * consumption rate * fuel price
/// - Automatic retry on network restoration
/// - Storing route coordinates for map display
/// - Input validation
/// - Calculation state management
class TripCalculatorProvider extends ChangeNotifier {
  final OSRMService _osrmService;
  final ConnectivityService? _connectivityService;

  FuelType? _selectedFuelType;
  double? _consumptionRate;
  LatLng? _origin;
  LatLng? _destination;
  TripCalculation? _result;
  List<LatLng>? _routeCoordinates;
  bool _isCalculating = false;
  String? _error;
  bool _hasFailedRequest = false;

  TripCalculatorProvider(
    this._osrmService, {
    ConnectivityService? connectivityService,
  }) : _connectivityService = connectivityService {
    // Register callback for network restoration
    _connectivityService?.onConnected(_onNetworkRestored);
  }

  // Getters
  FuelType? get selectedFuelType => _selectedFuelType;
  double? get consumptionRate => _consumptionRate;
  LatLng? get origin => _origin;
  LatLng? get destination => _destination;
  TripCalculation? get result => _result;
  List<LatLng>? get routeCoordinates => _routeCoordinates;
  bool get isCalculating => _isCalculating;
  String? get error => _error;
  bool get hasResult => _result != null;

  /// Set the selected fuel type
  void setFuelType(FuelType fuelType) {
    _selectedFuelType = fuelType;
    notifyListeners();
  }

  /// Set the consumption rate (liters per 100 km)
  void setConsumptionRate(double rate) {
    _consumptionRate = rate;
    notifyListeners();
  }

  /// Set the origin location
  void setOrigin(LatLng location) {
    _origin = location;
    notifyListeners();
  }

  /// Set the destination location
  void setDestination(LatLng location) {
    _destination = location;
    notifyListeners();
  }

  /// Calculate trip cost and fuel needed
  /// 
  /// Formula: (distance / 100) * consumption rate * fuel price
  /// 
  /// Validates:
  /// - Consumption rate must be positive
  /// - All required inputs must be provided
  /// 
  /// Uses OSRM API to calculate distance and get route coordinates
  Future<void> calculateTrip({
    required LatLng origin,
    required LatLng destination,
    required FuelType fuelType,
    required double consumptionRate,
  }) async {
    // Validate consumption rate
    if (consumptionRate <= 0) {
      _error = 'معدل الاستهلاك يجب أن يكون أكبر من صفر';
      _result = null;
      _routeCoordinates = null;
      notifyListeners();
      return;
    }

    _isCalculating = true;
    _error = null;
    _origin = origin;
    _destination = destination;
    _selectedFuelType = fuelType;
    _consumptionRate = consumptionRate;
    notifyListeners();

    try {
      // Get route from OSRM API with retry logic
      final routeResult = await RetryHelper.retry(
        fn: () => _osrmService.getRoute(
          origin: origin,
          destination: destination,
        ),
        maxAttempts: 3,
      );

      // Extract distance in kilometers
      final distance = _osrmService.extractDistance(routeResult);

      // Extract route coordinates for map display
      final coordinates = _osrmService.extractRouteCoordinates(routeResult);

      // Calculate fuel needed: (distance / 100) * consumption rate
      final fuelNeeded = (distance / 100) * consumptionRate;

      // Calculate total cost: fuel needed * fuel price
      final totalCost = fuelNeeded * fuelType.price;

      // Create result
      _result = TripCalculation(
        distance: distance,
        fuelNeeded: fuelNeeded,
        totalCost: totalCost,
        currency: fuelType.currency,
        fuelType: fuelType,
        routeCoordinates: coordinates,
      );

      _routeCoordinates = coordinates;
      _hasFailedRequest = false;
    } catch (e) {
      _error = e.toString();
      _result = null;
      _routeCoordinates = null;
      _hasFailedRequest = true;
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  /// Reset all calculation data
  void reset() {
    _selectedFuelType = null;
    _consumptionRate = null;
    _origin = null;
    _destination = null;
    _result = null;
    _routeCoordinates = null;
    _error = null;
    _isCalculating = false;
    notifyListeners();
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Called when network is restored - retry failed requests
  void _onNetworkRestored() {
    if (_hasFailedRequest && 
        !_isCalculating && 
        _origin != null && 
        _destination != null && 
        _selectedFuelType != null && 
        _consumptionRate != null) {
      calculateTrip(
        origin: _origin!,
        destination: _destination!,
        fuelType: _selectedFuelType!,
        consumptionRate: _consumptionRate!,
      );
    }
  }

  @override
  void dispose() {
    _connectivityService?.removeOnConnected(_onNetworkRestored);
    super.dispose();
  }
}
