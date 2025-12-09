import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fuel_prices_provider.dart';
import '../models/models.dart';
import '../utils/arabic_formatter.dart';
import '../widgets/loading_skeleton.dart';

/// Screen displaying current fuel prices
/// 
/// Features:
/// - ListView of fuel price cards
/// - Pull-to-refresh functionality
/// - Loading indicator
/// - Error handling with retry
class FuelPricesScreen extends StatefulWidget {
  const FuelPricesScreen({super.key});

  @override
  State<FuelPricesScreen> createState() => _FuelPricesScreenState();
}

class _FuelPricesScreenState extends State<FuelPricesScreen> {
  @override
  void initState() {
    super.initState();
    // Load fuel prices when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FuelPricesProvider>().loadFuelPrices();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<FuelPricesProvider>().refresh();
  }

  void _handleRetry() {
    context.read<FuelPricesProvider>().loadFuelPrices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسعار الوقود'),
        centerTitle: true,
      ),
      body: Consumer<FuelPricesProvider>(
        builder: (context, provider, child) {
          // Show skeleton loaders while loading
          if (provider.isLoading && provider.fuelTypes.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: 5, // Show 5 skeleton cards
              itemBuilder: (context, index) {
                return const FuelPriceCardSkeleton();
              },
            );
          }

          // Show error message with retry button
          if (provider.error != null && provider.fuelTypes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'فشل تحميل الأسعار',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error ?? 'حدث خطأ غير متوقع',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _handleRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show empty state
          if (provider.fuelTypes.isEmpty) {
            return const Center(
              child: Text('لا توجد أسعار متاحة'),
            );
          }

          // Show fuel prices list with pull-to-refresh
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.fuelTypes.length + (provider.isUsingCachedData ? 1 : 0),
              itemBuilder: (context, index) {
                // Show stale data indicator as first item
                if (provider.isUsingCachedData && index == 0) {
                  return Card(
                    color: Colors.amber.shade100,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'يتم عرض بيانات محفوظة. اسحب للأسفل للتحديث.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Adjust index if stale data indicator is shown
                final fuelTypeIndex = provider.isUsingCachedData ? index - 1 : index;
                final fuelType = provider.fuelTypes[fuelTypeIndex];
                return FuelPriceCard(fuelType: fuelType);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Card widget displaying a single fuel type's price information
/// 
/// Displays:
/// - Fuel name
/// - Price with currency
/// - Last updated timestamp
/// - Formatted with Arabic locale
class FuelPriceCard extends StatelessWidget {
  final FuelType fuelType;

  const FuelPriceCard({
    super.key,
    required this.fuelType,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fuel name
            Row(
              children: [
                Icon(
                  Icons.local_gas_station,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fuelType.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Price with currency
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'السعر:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                Text(
                  ArabicFormatter.formatCurrency(
                    fuelType.price,
                    fuelType.currency,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Last updated timestamp
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'آخر تحديث: ${ArabicFormatter.formatDateTime(fuelType.lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
