import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/arabic_formatter.dart';

/// Trip calculator screen with route display
/// 
/// Features:
/// - Google Map with origin and destination markers
/// - Fuel type selection dropdown
/// - Consumption rate input
/// - Destination input (coordinates for now, can be enhanced with autocomplete)
/// - Route display on map
/// - Trip cost calculation results
class TripCalculatorScreen extends StatefulWidget {
  const TripCalculatorScreen({super.key});

  @override
  State<TripCalculatorScreen> createState() => _TripCalculatorScreenState();
}

class _TripCalculatorScreenState extends State<TripCalculatorScreen> {
  GoogleMapController? _mapController;
  
  // Default location (Damascus, Syria)
  static const LatLng _defaultLocation = LatLng(33.5138, 36.2765);
  
  // Form controllers
  final TextEditingController _consumptionRateController = TextEditingController();
  
  // Selected fuel type
  FuelType? _selectedFuelType;
  
  // Origin and destination
  LatLng? _origin;
  LatLng? _destination;
  
  // Selection mode
  bool _isSelectingDestination = false;
  Station? _selectedStation;
  
  @override
  void initState() {
    super.initState();
    
    // Load fuel prices when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fuelPricesProvider = context.read<FuelPricesProvider>();
      if (fuelPricesProvider.fuelTypes.isEmpty) {
        fuelPricesProvider.loadFuelPrices();
      }
      
      // Set origin to user's current location if available
      final locationProvider = context.read<LocationProvider>();
      if (locationProvider.currentLatLng != null) {
        setState(() {
          _origin = locationProvider.currentLatLng;
        });
      } else {
        // Use default location
        setState(() {
          _origin = _defaultLocation;
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _consumptionRateController.dispose();
    super.dispose();
  }

  /// Handle map creation
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  /// Handle map tap to select destination
  void _onMapTap(LatLng position) {
    if (_isSelectingDestination) {
      setState(() {
        _destination = position;
        _selectedStation = null;
        _isSelectingDestination = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديد الوجهة على الخريطة'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Build markers for origin and destination
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    // Origin marker (green)
    if (_origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: _origin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'نقطة البداية'),
        ),
      );
    }
    
    // Destination marker (red)
    if (_destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'الوجهة'),
        ),
      );
    }
    
    return markers;
  }

  /// Build polylines for route display
  Set<Polyline> _buildPolylines(TripCalculatorProvider tripProvider) {
    final polylines = <Polyline>{};
    
    // Display route if available
    if (tripProvider.routeCoordinates != null && 
        tripProvider.routeCoordinates!.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: tripProvider.routeCoordinates!,
          color: Colors.blue,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }
    
    return polylines;
  }

  /// Adjust camera to show full route
  void _adjustCameraToRoute(List<LatLng> routeCoordinates) {
    if (_mapController == null || routeCoordinates.isEmpty) {
      return;
    }
    
    // Calculate bounds from route coordinates
    double minLat = routeCoordinates.first.latitude;
    double maxLat = routeCoordinates.first.latitude;
    double minLng = routeCoordinates.first.longitude;
    double maxLng = routeCoordinates.first.longitude;
    
    for (final coord in routeCoordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  /// Enable destination selection mode
  void _enableDestinationSelection() {
    setState(() {
      _isSelectingDestination = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('اضغط على الخريطة لتحديد الوجهة'),
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  /// Show station selection dialog
  void _showStationSelectionDialog() {
    final stationsProvider = context.read<StationsProvider>();
    final stations = stationsProvider.allStations;
    
    if (stations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد محطات متاحة'),
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_gas_station, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'اختر محطة وقود',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: stations.length,
                    itemBuilder: (context, index) {
                      final station = stations[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.local_gas_station),
                        ),
                        title: Text(
                          station.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(station.operatingHours),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          setState(() {
                            _destination = LatLng(station.latitude, station.longitude);
                            _selectedStation = station;
                            _isSelectingDestination = false;
                          });
                          Navigator.pop(context);
                          
                          // Fit bounds to show route
                          if (_origin != null) {
                            _fitBounds();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Fit camera bounds to show both origin and destination
  void _fitBounds() {
    if (_mapController == null || _origin == null || _destination == null) {
      return;
    }
    
    final bounds = LatLngBounds(
      southwest: LatLng(
        _origin!.latitude < _destination!.latitude ? _origin!.latitude : _destination!.latitude,
        _origin!.longitude < _destination!.longitude ? _origin!.longitude : _destination!.longitude,
      ),
      northeast: LatLng(
        _origin!.latitude > _destination!.latitude ? _origin!.latitude : _destination!.latitude,
        _origin!.longitude > _destination!.longitude ? _origin!.longitude : _destination!.longitude,
      ),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  /// Build results display card
  Widget _buildResultsCard(TripCalculation result) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 8),
                Text(
                  'نتائج الحساب',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Distance
            _buildResultRow(
              icon: Icons.route,
              label: 'المسافة',
              value: '${ArabicFormatter.formatNumber(result.distance, decimalDigits: 2)} كم',
              color: Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            // Fuel needed
            _buildResultRow(
              icon: Icons.local_gas_station,
              label: 'كمية الوقود المطلوبة',
              value: '${ArabicFormatter.formatNumber(result.fuelNeeded, decimalDigits: 2)} لتر',
              color: Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            // Total cost (highlighted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade700, width: 2),
              ),
              child: _buildResultRow(
                icon: Icons.payments,
                label: 'التكلفة الإجمالية',
                value: ArabicFormatter.formatCurrency(
                  result.totalCost,
                  result.currency,
                  decimalDigits: 2,
                ),
                color: Colors.green.shade700,
                isLarge: true,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Fuel type info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'نوع الوقود: ${result.fuelType.name} (${ArabicFormatter.formatCurrency(result.fuelType.price, result.fuelType.currency, decimalDigits: 2)}/لتر)',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single result row
  Widget _buildResultRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLarge = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: isLarge ? 28 : 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isLarge ? 16 : 14,
                  color: Colors.grey.shade700,
                ),
                textDirection: TextDirection.rtl,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isLarge ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة الرحلات'),
      ),
      body: Column(
        children: [
          // Map section (top half)
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Consumer<TripCalculatorProvider>(
                  builder: (context, tripProvider, child) {
                    return GoogleMap(
                      onMapCreated: _onMapCreated,
                      onTap: _onMapTap,
                      initialCameraPosition: CameraPosition(
                        target: _origin ?? _defaultLocation,
                        zoom: 12.0,
                      ),
                      markers: _buildMarkers(),
                      polylines: _buildPolylines(tripProvider),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.normal,
                      zoomControlsEnabled: true,
                    );
                  },
                ),
                
                // Selection mode indicator
                if (_isSelectingDestination)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.blue,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.touch_app, color: Colors.white),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'اضغط على الخريطة لتحديد الوجهة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _isSelectingDestination = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Input section (bottom half)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fuel type dropdown
                  Consumer<FuelPricesProvider>(
                    builder: (context, fuelPricesProvider, child) {
                      if (fuelPricesProvider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      if (fuelPricesProvider.error != null) {
                        return Card(
                          color: Colors.red.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'خطأ في تحميل أنواع الوقود: ${fuelPricesProvider.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }
                      
                      return DropdownButtonFormField<FuelType>(
                        key: ValueKey(_selectedFuelType),
                        initialValue: _selectedFuelType,
                        decoration: const InputDecoration(
                          labelText: 'نوع الوقود',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_gas_station),
                        ),
                        items: fuelPricesProvider.fuelTypes.map((fuelType) {
                          return DropdownMenuItem(
                            value: fuelType,
                            child: Text(
                              '${fuelType.name} - ${fuelType.price} ${fuelType.currency}',
                              textDirection: TextDirection.rtl,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFuelType = value;
                          });
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Consumption rate input
                  TextField(
                    controller: _consumptionRateController,
                    decoration: const InputDecoration(
                      labelText: 'معدل الاستهلاك (لتر/100كم)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed),
                      hintText: 'مثال: 8.5',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    textDirection: TextDirection.ltr,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Destination selection section
                  const Text(
                    'اختر الوجهة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _enableDestinationSelection,
                          icon: const Icon(Icons.map),
                          label: const Text('اختر من الخريطة'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showStationSelectionDialog,
                          icon: const Icon(Icons.local_gas_station),
                          label: const Text('اختر محطة'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Origin info
                  if (_origin != null)
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'نقطة البداية: موقعك الحالي',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Destination info
                  if (_destination != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              _selectedStation != null 
                                  ? Icons.local_gas_station 
                                  : Icons.location_on,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedStation != null
                                    ? 'الوجهة: ${_selectedStation!.name}'
                                    : 'الوجهة: نقطة على الخريطة',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _destination = null;
                                  _selectedStation = null;
                                });
                              },
                              tooltip: 'إلغاء',
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Calculate button
                  Consumer<TripCalculatorProvider>(
                    builder: (context, tripProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: tripProvider.isCalculating
                                ? null
                                : _handleCalculate,
                            icon: tripProvider.isCalculating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.calculate),
                            label: Text(
                              tripProvider.isCalculating
                                  ? 'جاري الحساب...'
                                  : 'احسب التكلفة',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(18),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Error message
                          if (tripProvider.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Card(
                                color: Colors.red.shade100,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          tripProvider.error!,
                                          style: const TextStyle(color: Colors.red),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () {
                                          tripProvider.clearError();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          
                          // Results display card
                          if (tripProvider.result != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: _buildResultsCard(tripProvider.result!),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Handle calculate button press
  void _handleCalculate() async {
    // Validate inputs
    if (_selectedFuelType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار نوع الوقود'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_consumptionRateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال معدل الاستهلاك'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final consumptionRate = double.tryParse(_consumptionRateController.text);
    if (consumptionRate == null || consumptionRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('معدل الاستهلاك يجب أن يكون رقماً موجباً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_origin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نقطة البداية غير محددة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تحديد الوجهة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // All validations passed, calculate trip
    final tripProvider = context.read<TripCalculatorProvider>();
    await tripProvider.calculateTrip(
      origin: _origin!,
      destination: _destination!,
      fuelType: _selectedFuelType!,
      consumptionRate: consumptionRate,
    );
    
    // Adjust camera to show full route if calculation was successful
    if (tripProvider.routeCoordinates != null && 
        tripProvider.routeCoordinates!.isNotEmpty) {
      _adjustCameraToRoute(tripProvider.routeCoordinates!);
    }
  }
}
