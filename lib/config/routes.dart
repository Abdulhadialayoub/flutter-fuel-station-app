import 'package:flutter/material.dart';
import '../screens/screens.dart';
import '../models/models.dart';
import '../widgets/page_transitions.dart';

/// Route names for the application
class AppRoutes {
  // Main navigation routes
  static const String home = '/';
  static const String map = '/map';
  static const String tripCalculator = '/trip-calculator';
  static const String fuelPrices = '/fuel-prices';
  
  // Detail routes
  static const String stationDetails = '/station-details';
  static const String reviewForm = '/review-form';
}

/// Route generator for the application
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );
        
      case AppRoutes.map:
        return MaterialPageRoute(
          builder: (_) => const MapScreen(),
        );
        
      case AppRoutes.tripCalculator:
        return MaterialPageRoute(
          builder: (_) => const TripCalculatorScreen(),
        );
        
      case AppRoutes.fuelPrices:
        return MaterialPageRoute(
          builder: (_) => const FuelPricesScreen(),
        );
        
      case AppRoutes.stationDetails:
        final station = settings.arguments as Station?;
        if (station == null) {
          return _errorRoute('Station data is required');
        }
        return SlideFadePageRoute(
          page: StationDetailsScreen(station: station),
        );
        
      case AppRoutes.reviewForm:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || !args.containsKey('stationId')) {
          return _errorRoute('Station ID is required');
        }
        return SlideFadePageRoute(
          page: ReviewFormScreen(
            stationId: args['stationId'] as String,
            stationName: args['stationName'] as String? ?? '',
          ),
        );
        
      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }
  
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('خطأ'),
        ),
        body: Center(
          child: Text(
            message,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens = [
    const MapScreen(),
    TripCalculatorScreen(key: ValueKey(_currentIndex)),
    const FuelPricesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'الخريطة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'حاسبة الرحلات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'الأسعار',
          ),
        ],
      ),
    );
  }
}
