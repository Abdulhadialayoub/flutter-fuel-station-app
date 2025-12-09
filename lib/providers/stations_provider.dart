import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../utils/retry_helper.dart';

/// Provider for managing stations data and search/filter state
/// 
/// Handles:
/// - Loading stations from Supabase
/// - Caching stations data locally
/// - Automatic retry on network restoration
/// - Searching stations by name
/// - Filtering stations by service
/// - Managing loading and error states
class StationsProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final CacheService _cacheService;
  final ConnectivityService? _connectivityService;

  List<Station> _stations = [];
  List<Station> _filteredStations = [];
  bool _isLoading = false;
  String? _error;
  String _currentSearchQuery = '';
  String _currentServiceFilter = '';
  bool _isUsingCachedData = false;
  bool _hasFailedRequest = false;

  StationsProvider(
    this._supabaseService,
    this._cacheService, {
    ConnectivityService? connectivityService,
  }) : _connectivityService = connectivityService {
    // Register callback for network restoration
    _connectivityService?.onConnected(_onNetworkRestored);
  }

  // Getters
  List<Station> get stations => _filteredStations;
  List<Station> get allStations => _stations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentSearchQuery => _currentSearchQuery;
  String get currentServiceFilter => _currentServiceFilter;
  bool get hasActiveFilter => _currentSearchQuery.isNotEmpty || _currentServiceFilter.isNotEmpty;
  bool get isUsingCachedData => _isUsingCachedData;

  /// Load all stations from Supabase with retry logic and caching
  Future<void> loadStations() async {
    _isLoading = true;
    _error = null;
    _isUsingCachedData = false;
    _hasFailedRequest = false;
    notifyListeners();

    try {
      // Try to fetch fresh data from Supabase
      _stations = await RetryHelper.retry(
        fn: () => _supabaseService.fetchStations(),
        maxAttempts: 3,
      );
      
      // Cache the fresh data
      await _cacheService.cacheStations(_stations);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      _hasFailedRequest = true;
      
      // Try to load from cache if fetch failed
      final cachedStations = await _cacheService.getCachedStations();
      if (cachedStations != null && cachedStations.isNotEmpty) {
        _stations = cachedStations;
        _isUsingCachedData = true;
        _applyFilters();
        // Update error message to indicate using cached data
        _error = 'يتم عرض البيانات المحفوظة. $_error';
      } else {
        _filteredStations = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called when network is restored - retry failed requests
  void _onNetworkRestored() {
    if (_hasFailedRequest && !_isLoading) {
      loadStations();
    }
  }

  /// Search stations by name (case-insensitive)
  /// 
  /// Filters the loaded stations list to only show stations
  /// whose names contain the search query
  void searchStations(String query) {
    _currentSearchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  /// Filter stations by service name
  /// 
  /// Shows only stations that offer the specified service
  void filterByService(String serviceName) {
    _currentServiceFilter = serviceName.trim();
    _applyFilters();
    notifyListeners();
  }

  /// Clear all active filters and show all stations
  void clearFilters() {
    _currentSearchQuery = '';
    _currentServiceFilter = '';
    _applyFilters();
    notifyListeners();
  }

  /// Apply current search and filter criteria to stations list
  void _applyFilters() {
    List<Station> result = List.from(_stations);

    // Apply name search filter
    if (_currentSearchQuery.isNotEmpty) {
      result = result.where((station) {
        return station.name.toLowerCase().contains(_currentSearchQuery.toLowerCase());
      }).toList();
    }

    // Apply service filter
    if (_currentServiceFilter.isNotEmpty) {
      result = result.where((station) {
        return station.services.any((service) {
          return service.name.toLowerCase().contains(_currentServiceFilter.toLowerCase());
        });
      }).toList();
    }

    _filteredStations = result;
  }

  /// Refresh stations data
  Future<void> refresh() async {
    await loadStations();
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get a station by ID from the loaded stations
  Station? getStationById(String id) {
    try {
      return _stations.firstWhere((station) => station.id == id);
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
