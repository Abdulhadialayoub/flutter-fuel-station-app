import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/osrm_service.dart';
import '../providers/location_provider.dart';
import '../utils/arabic_formatter.dart';
import '../config/routes.dart';

/// Screen displaying detailed information about a fuel station
/// 
/// Shows:
/// - Station name, coordinates, and operating hours
/// - Services grid with icons
/// - Reviews list with average rating
/// - Get directions button
/// - Add review button
class StationDetailsScreen extends StatefulWidget {
  final Station station;

  const StationDetailsScreen({
    super.key,
    required this.station,
  });

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  String? _reviewsError;
  double? _averageRating;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  /// Load reviews for this station
  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
      _reviewsError = null;
    });

    try {
      final supabaseService = context.read<SupabaseService>();
      final reviews = await supabaseService.fetchReviewsForStation(widget.station.id);
      final avgRating = await supabaseService.calculateAverageRating(widget.station.id);
      
      setState(() {
        _reviews = reviews;
        _averageRating = avgRating;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() {
        _reviewsError = e.toString();
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Information Card
            _buildStationInfoCard(),
            
            const Divider(height: 1),
            
            // Services Section
            if (widget.station.services.isNotEmpty) ...[
              _buildServicesSection(),
              const Divider(height: 1),
            ],
            
            // Reviews Section
            _buildReviewsSection(),
          ],
        ),
      ),
      // Get Directions Button (Fixed at bottom)
      bottomNavigationBar: _buildGetDirectionsButton(),
    );
  }

  /// Build station information card
  Widget _buildStationInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Name
            Text(
              widget.station.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Operating Hours
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'ساعات العمل',
              value: widget.station.operatingHours,
            ),
            const SizedBox(height: 12),
            
            // Location Coordinates
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'الموقع',
              value: '${ArabicFormatter.formatNumber(widget.station.latitude, decimalDigits: 6)}, ${ArabicFormatter.formatNumber(widget.station.longitude, decimalDigits: 6)}',
            ),
            
            // Average Rating
            if (_averageRating != null && _averageRating! > 0) ...[
              const SizedBox(height: 12),
              _buildRatingRow(_averageRating!),
            ],
          ],
        ),
      ),
    );
  }

  /// Build info row with icon, label, and value
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build rating row with stars
  Widget _buildRatingRow(double rating) {
    return Row(
      children: [
        const Icon(Icons.star, size: 20, color: Colors.amber),
        const SizedBox(width: 8),
        Text(
          'التقييم: ${ArabicFormatter.formatNumber(rating, decimalDigits: 1)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return const Icon(Icons.star, size: 16, color: Colors.amber);
          } else if (index < rating) {
            return const Icon(Icons.star_half, size: 16, color: Colors.amber);
          } else {
            return Icon(Icons.star_border, size: 16, color: Colors.grey[400]);
          }
        }),
      ],
    );
  }

  /// Build services section
  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الخدمات المتوفرة',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: widget.station.services.length,
            itemBuilder: (context, index) {
              final service = widget.station.services[index];
              return _buildServiceCard(service);
            },
          ),
        ],
      ),
    );
  }

  /// Build individual service card
  Widget _buildServiceCard(Service service) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getServiceIcon(service.icon),
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              service.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Get icon data for service icon string
  IconData _getServiceIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'car_wash':
      case 'wash':
        return Icons.local_car_wash;
      case 'market':
      case 'store':
        return Icons.store;
      case 'tire':
      case 'tire_repair':
        return Icons.tire_repair;
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'atm':
        return Icons.atm;
      case 'wifi':
        return Icons.wifi;
      case 'parking':
        return Icons.local_parking;
      default:
        return Icons.check_circle;
    }
  }

  /// Build reviews section
  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقييمات',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _onAddReview,
                icon: const Icon(Icons.add),
                label: const Text('إضافة تقييم'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Loading state
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          
          // Error state
          else if (_reviewsError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'فشل تحميل التقييمات',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadReviews,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          
          // Empty state
          else if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.rate_review, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد تقييمات بعد',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'كن أول من يقيّم هذه المحطة',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          
          // Reviews list
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                return _buildReviewCard(_reviews[index]);
              },
            ),
        ],
      ),
    );
  }

  /// Build individual review card
  Widget _buildReviewCard(Review review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating stars
        Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                size: 16,
                color: Colors.amber,
              );
            }),
            const SizedBox(width: 8),
            Text(
              ArabicFormatter.formatDate(review.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Comment
        if (review.comment.isNotEmpty)
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
      ],
    );
  }

  /// Build get directions button
  Widget _buildGetDirectionsButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _onGetDirections,
          icon: const Icon(Icons.directions),
          label: const Text('احصل على الاتجاهات'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }

  /// Handle get directions button tap
  void _onGetDirections() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildDirectionsBottomSheet(),
    );
  }

  /// Build directions options bottom sheet
  Widget _buildDirectionsBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'احصل على الاتجاهات',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Show route on map option
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showRouteOnMap();
            },
            icon: const Icon(Icons.map),
            label: const Text('عرض المسار على الخريطة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          
          // Open in Google Maps option
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openInGoogleMaps();
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('فتح في خرائط جوجل'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  /// Show route on map using OSRM
  Future<void> _showRouteOnMap() async {
    final locationProvider = context.read<LocationProvider>();
    final osrmService = context.read<OSRMService>();
    
    // Check if user location is available
    if (locationProvider.currentLatLng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الموقع الحالي غير متاح'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري حساب المسار...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      // Calculate route using OSRM
      final origin = locationProvider.currentLatLng!;
      final destination = LatLng(widget.station.latitude, widget.station.longitude);
      
      final routeResult = await osrmService.getRoute(
        origin: origin,
        destination: destination,
      );
      
      // Extract route coordinates
      final routeCoordinates = osrmService.extractRouteCoordinates(routeResult);
      final distance = osrmService.extractDistance(routeResult);
      
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);
      
      // Navigate to map view with route
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _RouteMapScreen(
            origin: origin,
            destination: destination,
            routeCoordinates: routeCoordinates,
            distance: distance,
            stationName: widget.station.name,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حساب المسار: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'إعادة المحاولة',
            textColor: Colors.white,
            onPressed: _showRouteOnMap,
          ),
        ),
      );
    }
  }

  /// Open station location in Google Maps app
  Future<void> _openInGoogleMaps() async {
    final lat = widget.station.latitude;
    final lng = widget.station.longitude;
    final name = Uri.encodeComponent(widget.station.name);
    
    // Try Google Maps app first, then fallback to web
    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng');
    final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name');
    
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'لا يمكن فتح خرائط جوجل';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل فتح خرائط جوجل: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handle add review button tap
  Future<void> _onAddReview() async {
    // Navigate to review form screen
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.reviewForm,
      arguments: {
        'stationId': widget.station.id,
        'stationName': widget.station.name,
      },
    );

    // If review was submitted successfully, refresh reviews
    if (result == true) {
      _loadReviews();
    }
  }
}


/// Screen displaying route on map with polyline
class _RouteMapScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> routeCoordinates;
  final double distance;
  final String stationName;

  const _RouteMapScreen({
    required this.origin,
    required this.destination,
    required this.routeCoordinates,
    required this.distance,
    required this.stationName,
  });

  @override
  State<_RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<_RouteMapScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    // Calculate bounds to show entire route
    double minLat = widget.origin.latitude;
    double maxLat = widget.origin.latitude;
    double minLng = widget.origin.longitude;
    double maxLng = widget.origin.longitude;

    for (final coord in widget.routeCoordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('المسار إلى ${widget.stationName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.origin,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // Animate to show full route
              Future.delayed(const Duration(milliseconds: 500), () {
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 100),
                );
              });
            },
            markers: {
              // Origin marker
              Marker(
                markerId: const MarkerId('origin'),
                position: widget.origin,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: const InfoWindow(title: 'موقعك'),
              ),
              // Destination marker
              Marker(
                markerId: const MarkerId('destination'),
                position: widget.destination,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
                infoWindow: InfoWindow(title: widget.stationName),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: widget.routeCoordinates,
                color: Colors.blue,
                width: 5,
                patterns: [PatternItem.dot],
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
          ),
          
          // Distance info card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المسافة',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${ArabicFormatter.formatNumber(widget.distance, decimalDigits: 1)} كم',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
