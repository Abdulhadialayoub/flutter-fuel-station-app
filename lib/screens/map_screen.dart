import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../widgets/station_details_bottom_sheet.dart';
import '../config/routes.dart';
import '../utils/map_utils.dart';

/// Main map screen displaying fuel stations and user location
/// 
/// Features:
/// - Interactive Google Map
/// - User location marker
/// - Station markers
/// - Search and filter functionality
/// - Station details bottom sheet
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  
  // Default location (Damascus, Syria)
  static const LatLng _defaultLocation = LatLng(33.5138, 36.2765);
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  
  // Available services for filtering (will be populated from stations)
  List<String> _availableServices = [];
  
  // Map state for optimization
  LatLngBounds? _currentBounds;
  double _currentZoom = 14.0;
  bool _useClusteringCache = false;
  List<MarkerCluster>? _cachedClusters;
  
  // Cached marker icons for better performance
  BitmapDescriptor? _stationMarkerIcon;
  BitmapDescriptor? _clusterMarkerIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize marker icons
    _initializeMarkerIcons();
    
    // Initialize location and stations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }
  
  /// Initialize and cache marker icons
  Future<void> _initializeMarkerIcons() async {
    _stationMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    _clusterMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final locationProvider = context.read<LocationProvider>();
    
    // Stop GPS updates when app goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      locationProvider.stopLocationUpdates();
    } 
    // Resume GPS updates when app comes to foreground
    else if (state == AppLifecycleState.resumed) {
      locationProvider.startLocationUpdates();
    }
  }

  /// Initialize location and stations data
  Future<void> _initializeData() async {
    final locationProvider = context.read<LocationProvider>();
    final stationsProvider = context.read<StationsProvider>();
    
    // Request location permission and get current location
    await locationProvider.requestPermission();
    
    // Start location updates
    locationProvider.startLocationUpdates();
    
    // Load stations
    await stationsProvider.loadStations();
    
    // Extract available services from stations
    _extractAvailableServices(stationsProvider.allStations);
    
    // Move camera to user location if available
    if (locationProvider.currentLatLng != null) {
      _moveCamera(locationProvider.currentLatLng!);
    }
  }

  /// Extract unique services from all stations
  void _extractAvailableServices(List<Station> stations) {
    final services = <String>{};
    for (final station in stations) {
      for (final service in station.services) {
        services.add(service.name);
      }
    }
    setState(() {
      _availableServices = services.toList()..sort();
    });
  }

  /// Move camera to specified location
  Future<void> _moveCamera(LatLng location) async {
    final controller = await _controllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 14.0,
        ),
      ),
    );
  }

  /// Handle map creation
  void _onMapCreated(GoogleMapController controller) {
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }
    _mapController = controller;
  }
  
  /// Handle camera movement to update visible bounds
  void _onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;
  }
  
  /// Handle camera idle to update markers based on visible bounds
  Future<void> _onCameraIdle() async {
    if (_mapController == null) return;
    
    try {
      final bounds = await _mapController!.getVisibleRegion();
      setState(() {
        _currentBounds = bounds;
        _cachedClusters = null; // Invalidate cache when bounds change
      });
    } catch (e) {
      // Ignore errors getting visible region
    }
  }

  /// Build markers from stations list with optimization
  Set<Marker> _buildMarkers(List<Station> stations) {
    // Filter stations within visible bounds if available
    List<Station> visibleStations = stations;
    if (_currentBounds != null) {
      visibleStations = MapUtils.filterStationsInBounds(stations, _currentBounds!);
    }
    
    // Determine if clustering should be used
    final shouldCluster = MapUtils.shouldCluster(_currentZoom);
    
    if (shouldCluster && visibleStations.length > 10) {
      // Use clustering for better performance
      return _buildClusteredMarkers(visibleStations);
    } else {
      // Show individual markers
      return _buildIndividualMarkers(visibleStations);
    }
  }
  
  /// Build individual markers
  Set<Marker> _buildIndividualMarkers(List<Station> stations) {
    return stations.map((station) {
      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.latitude, station.longitude),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: station.operatingHours,
        ),
        icon: _stationMarkerIcon ?? BitmapDescriptor.defaultMarker,
        onTap: () {
          _onMarkerTapped(station);
        },
      );
    }).toSet();
  }
  
  /// Build clustered markers
  Set<Marker> _buildClusteredMarkers(List<Station> stations) {
    // Use cached clusters if available
    List<MarkerCluster> clusters;
    if (_cachedClusters != null && _useClusteringCache) {
      clusters = _cachedClusters!;
    } else {
      final clusterRadius = MapUtils.getClusterRadius(_currentZoom);
      clusters = MapUtils.clusterMarkers(stations, clusterRadius);
      _cachedClusters = clusters;
      _useClusteringCache = true;
    }
    
    final markers = <Marker>{};
    
    for (final cluster in clusters) {
      if (cluster.isSingleStation) {
        // Single station - show normal marker
        final station = cluster.singleStation;
        markers.add(
          Marker(
            markerId: MarkerId(station.id),
            position: LatLng(station.latitude, station.longitude),
            infoWindow: InfoWindow(
              title: station.name,
              snippet: station.operatingHours,
            ),
            icon: _stationMarkerIcon ?? BitmapDescriptor.defaultMarker,
            onTap: () {
              _onMarkerTapped(station);
            },
          ),
        );
      } else {
        // Multiple stations - show cluster marker
        markers.add(
          Marker(
            markerId: MarkerId('cluster_${cluster.center.latitude}_${cluster.center.longitude}'),
            position: cluster.center,
            icon: _clusterMarkerIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: '${cluster.count} محطات',
              snippet: 'اضغط للتكبير',
            ),
            onTap: () {
              _onClusterTapped(cluster);
            },
          ),
        );
      }
    }
    
    return markers;
  }
  
  /// Handle cluster tap - zoom in to show individual stations
  void _onClusterTapped(MarkerCluster cluster) {
    if (_mapController == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: cluster.center,
          zoom: _currentZoom + 2, // Zoom in by 2 levels
        ),
      ),
    );
  }

  /// Handle marker tap
  void _onMarkerTapped(Station station) {
    _showStationDetails(station);
  }

  /// Show station details bottom sheet
  void _showStationDetails(Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StationDetailsBottomSheet(
          station: station,
          onGetDirections: () {
            Navigator.pop(context);
            _handleGetDirections(station);
          },
          onRateStation: () {
            Navigator.pop(context);
            _navigateToStationDetails(station);
          },
        );
      },
    );
  }

  /// Navigate to full station details screen
  void _navigateToStationDetails(Station station) {
    Navigator.pushNamed(
      context,
      AppRoutes.stationDetails,
      arguments: station,
    );
  }

  /// Handle get directions button
  void _handleGetDirections(Station station) {
    // This will be implemented when we add navigation functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('الحصول على الاتجاهات إلى ${station.name}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محطات الوقود'),
      ),
      body: Consumer2<LocationProvider, StationsProvider>(
        builder: (context, locationProvider, stationsProvider, child) {
          // Determine initial camera position
          final initialPosition = CameraPosition(
            target: locationProvider.currentLatLng ?? _defaultLocation,
            zoom: 14.0,
          );

          return Stack(
            children: [
              // Google Map
              GoogleMap(
                onMapCreated: _onMapCreated,
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                initialCameraPosition: initialPosition,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                compassEnabled: true,
                markers: _buildMarkers(stationsProvider.stations),
                // Optimize map rendering
                liteModeEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
              ),
              
              // Search bar
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'ابحث عن محطة...',
                              border: InputBorder.none,
                            ),
                            textDirection: TextDirection.rtl,
                            onChanged: (value) {
                              stationsProvider.searchStations(value);
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty ||
                            stationsProvider.hasActiveFilter)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              stationsProvider.clearFilters();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Stale data indicator
              if (stationsProvider.isUsingCachedData && !stationsProvider.isLoading)
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.amber.shade100,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, 
                            color: Colors.amber.shade900, 
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'يتم عرض بيانات محفوظة',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Service filter chips
              if (_availableServices.isNotEmpty)
                Positioned(
                  top: stationsProvider.isUsingCachedData ? 130 : 80,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _availableServices.length,
                      itemBuilder: (context, index) {
                        final service = _availableServices[index];
                        final isSelected =
                            stationsProvider.currentServiceFilter == service;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(service),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                stationsProvider.filterByService(service);
                              } else {
                                stationsProvider.clearFilters();
                              }
                            },
                            backgroundColor: Colors.white,
                            selectedColor: Colors.blue.shade100,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              
              // Results count
              if (stationsProvider.hasActiveFilter)
                Positioned(
                  top: stationsProvider.isUsingCachedData ? 190 : 140,
                  left: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        'النتائج: ${stationsProvider.stations.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              
              // No results message
              if (stationsProvider.hasActiveFilter &&
                  stationsProvider.stations.isEmpty &&
                  !stationsProvider.isLoading)
                Positioned(
                  top: stationsProvider.isUsingCachedData ? 190 : 140,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.orange.shade100,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'لا توجد محطات تطابق معايير البحث',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Loading indicator
              if (stationsProvider.isLoading || locationProvider.isLoading)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 16),
                            Text(
                              stationsProvider.isLoading
                                  ? 'جاري تحميل المحطات...'
                                  : 'جاري تحديد الموقع...',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Error messages
              if (stationsProvider.error != null)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.red.shade100,
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'خطأ في تحميل المحطات',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stationsProvider.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              stationsProvider.clearError();
                              stationsProvider.loadStations();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Location error message
              if (locationProvider.error != null && !locationProvider.isLoading)
                Positioned(
                  bottom: 180,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.orange.shade100,
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تعذر تحديد الموقع',
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              locationProvider.clearError();
                              locationProvider.requestPermission();
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      // Floating action button to center on user location
      floatingActionButton: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return FloatingActionButton(
            onPressed: () {
              if (locationProvider.currentLatLng != null) {
                _moveCamera(locationProvider.currentLatLng!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الموقع غير متاح'),
                  ),
                );
              }
            },
            child: const Icon(Icons.my_location),
          );
        },
      ),
    );
  }
}
