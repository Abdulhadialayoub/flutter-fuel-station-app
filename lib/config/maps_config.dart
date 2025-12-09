import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google Maps API configuration
class MapsConfig {
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
}
