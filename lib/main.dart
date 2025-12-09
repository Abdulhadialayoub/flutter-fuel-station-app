import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'services/services.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  // Initialize SharedPreferences for caching
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final supabaseService = SupabaseService(Supabase.instance.client);
    final locationService = LocationService();
    final osrmService = OSRMService();
    final cacheService = CacheService(prefs);
    final connectivityService = ConnectivityService();
    
    // Start monitoring connectivity
    connectivityService.startMonitoring();

    return MultiProvider(
      providers: [
        // Services (not ChangeNotifier, just for dependency injection)
        Provider<SupabaseService>.value(value: supabaseService),
        Provider<LocationService>.value(value: locationService),
        Provider<OSRMService>.value(value: osrmService),
        Provider<CacheService>.value(value: cacheService),
        Provider<ConnectivityService>.value(value: connectivityService),
        
        // Providers (ChangeNotifier)
        ChangeNotifierProvider(
          create: (_) => LocationProvider(locationService, cacheService),
        ),
        ChangeNotifierProvider(
          create: (_) => StationsProvider(
            supabaseService,
            cacheService,
            connectivityService: connectivityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FuelPricesProvider(
            supabaseService,
            cacheService,
            connectivityService: connectivityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TripCalculatorProvider(
            osrmService,
            connectivityService: connectivityService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'محطات الوقود',
        // Configure Arabic locale
        locale: const Locale('ar', 'SY'), // Arabic (Syria)
        supportedLocales: const [
          Locale('ar', 'SY'), // Arabic (Syria)
          Locale('ar', ''), // Arabic (generic)
        ],
        // Add localization delegates
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Apply custom theme
        theme: AppTheme.lightTheme,
        // Set RTL as default text direction
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        // Configure named routes
        initialRoute: AppRoutes.home,
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
