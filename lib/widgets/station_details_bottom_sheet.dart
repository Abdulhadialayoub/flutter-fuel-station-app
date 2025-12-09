import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/arabic_formatter.dart';

/// Bottom sheet widget displaying detailed station information
/// 
/// Shows:
/// - Station name
/// - Operating hours
/// - Available services
/// - Get directions button
/// - Rate station button
class StationDetailsBottomSheet extends StatelessWidget {
  final Station station;
  final VoidCallback? onGetDirections;
  final VoidCallback? onRateStation;

  const StationDetailsBottomSheet({
    super.key,
    required this.station,
    this.onGetDirections,
    this.onRateStation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Station name
            Text(
              station.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Operating hours
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'ساعات العمل: ${station.operatingHours}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Location coordinates
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'الموقع: ${ArabicFormatter.formatNumber(station.latitude, decimalDigits: 4)}, ${ArabicFormatter.formatNumber(station.longitude, decimalDigits: 4)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Average rating
            if (station.averageRating != null) ...[
              Row(
                children: [
                  const Icon(Icons.star, size: 20, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'التقييم: ${ArabicFormatter.formatNumber(station.averageRating!, decimalDigits: 1)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Services
            if (station.services.isNotEmpty) ...[
              Text(
                'الخدمات المتوفرة:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: station.services.map((service) {
                  return Chip(
                    label: Text(service.name),
                    avatar: service.icon.isNotEmpty
                        ? Icon(_getServiceIcon(service.icon), size: 18)
                        : null,
                    backgroundColor: Colors.blue.shade50,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            
            // Action buttons
            Row(
              children: [
                // Get directions button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onGetDirections,
                    icon: const Icon(Icons.directions),
                    label: const Text('احصل على الاتجاهات'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Rate station button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRateStation,
                    icon: const Icon(Icons.star_border),
                    label: const Text('قيّم المحطة'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
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
}
