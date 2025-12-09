import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../utils/retry_helper.dart';

/// Provider for managing fuel prices data
/// 
/// Handles:
/// - Loading fuel types and prices from Supabase
/// - Caching fuel prices data locally
/// - Automatic retry on network restoration
/// - Refreshing price data
/// - Managing loading and error states
class FuelPricesProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final CacheService _cacheService;
  final ConnectivityService? _connectivityService;

  List<FuelType> _fuelTypes = [];
  bool _isLoading = false;
  String? _error;
  bool _isUsingCachedData = false;
  bool _hasFailedRequest = false;

  FuelPricesProvider(
    this._supabaseService,
    this._cacheService, {
    ConnectivityService? connectivityService,
  }) : _connectivityService = connectivityService {
    // Register callback for network restoration
    _connectivityService?.onConnected(_onNetworkRestored);
  }

  // Getters
  List<FuelType> get fuelTypes => _fuelTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUsingCachedData => _isUsingCachedData;

  /// Load all fuel types with current prices from Supabase with retry logic and caching
  Future<void> loadFuelPrices() async {
    _isLoading = true;
    _error = null;
    _isUsingCachedData = false;
    _hasFailedRequest = false;
    notifyListeners();

    try {
      // Try to fetch fresh data from Supabase
      _fuelTypes = await RetryHelper.retry(
        fn: () => _supabaseService.fetchFuelTypes(),
        maxAttempts: 3,
      );
      
      // Cache the fresh data
      await _cacheService.cacheFuelTypes(_fuelTypes);
    } catch (e) {
      _error = e.toString();
      _hasFailedRequest = true;
      
      // Try to load from cache if fetch failed
      final cachedFuelTypes = await _cacheService.getCachedFuelTypes();
      if (cachedFuelTypes != null && cachedFuelTypes.isNotEmpty) {
        _fuelTypes = cachedFuelTypes;
        _isUsingCachedData = true;
        // Update error message to indicate using cached data
        _error = 'يتم عرض البيانات المحفوظة. $_error';
      } else {
        _fuelTypes = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called when network is restored - retry failed requests
  void _onNetworkRestored() {
    if (_hasFailedRequest && !_isLoading) {
      loadFuelPrices();
    }
  }

  /// Refresh fuel prices data
  /// 
  /// Reloads all fuel types and prices from the database
  Future<void> refresh() async {
    await loadFuelPrices();
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get a fuel type by ID from the loaded fuel types
  FuelType? getFuelTypeById(String id) {
    try {
      return _fuelTypes.firstWhere((fuelType) => fuelType.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get a fuel type by name from the loaded fuel types
  FuelType? getFuelTypeByName(String name) {
    try {
      return _fuelTypes.firstWhere(
        (fuelType) => fuelType.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _connectivityService?.removeOnConnected(_onNetworkRestored);
    super.dispose();
  }
}
