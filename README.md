# 🚗 Fuel Station App

A comprehensive mobile application for finding fuel stations and calculating trip costs in Syria, built with Flutter.

---

## 📱 Features

### 🗺️ Interactive Map
- Display fuel stations on Google Maps
- Automatic current location detection
- Search for nearby stations
- View station details on tap

### ⛽ Fuel Prices
- Display updated fuel prices
- Support for multiple fuel types (Gasoline 95, Gasoline 90, Diesel, Gas)
- Price updates from database

### 🧮 Trip Calculator
- Calculate trip cost based on:
  - Distance
  - Fuel consumption rate
  - Fuel price
- Select destination from map
- Select fuel station as destination
- Display route on map

### ⭐ Reviews & Ratings
- Rate fuel stations (1-5 stars)
- Write comments
- Display average ratings

### 🌐 Offline Support
- Local data storage
- Work without internet connection
- Automatic sync when connection available

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Application development framework
- **Dart** - Programming language
- **Provider** - State management
- **Google Maps Flutter** - Map display

### Backend
- **Supabase** - Database and authentication
- **PostgreSQL** - Database
- **OSRM API** - Route calculation (free)

### Main Packages
```yaml
dependencies:
  flutter_localizations: # Arabic language support
  supabase_flutter: ^2.8.0
  google_maps_flutter: ^2.9.0
  geolocator: ^13.0.2
  provider: ^6.1.2
  dio: ^5.7.0
  shared_preferences: ^2.3.3
  connectivity_plus: ^6.1.2
  flutter_dotenv: ^5.2.1
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or newer)
- Android Studio or Xcode
- Supabase account
- Google Maps API Key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd fuel_station_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Then edit the `.env` file and add your API keys:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_key
   GOOGLE_MAPS_API_KEY=your_google_maps_key
   ```

4. **Setup database**
   - Open Supabase Dashboard
   - Execute scripts in `database/` folder:
     - `schema.sql` - Create tables
     - `sample_data.sql` - Sample data
     - `verify_setup.sql` - Verify setup

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```
lib/
├── config/              # Configuration files
│   ├── theme.dart       # App theme
│   ├── routes.dart      # Routes
│   ├── supabase_config.dart
│   └── maps_config.dart
├── models/              # Data models
│   ├── station.dart
│   ├── review.dart
│   └── fuel_type.dart
├── services/            # Services
│   ├── supabase_service.dart
│   ├── location_service.dart
│   ├── osrm_service.dart
│   ├── cache_service.dart
│   └── connectivity_service.dart
├── providers/           # State management
│   ├── stations_provider.dart
│   ├── location_provider.dart
│   ├── fuel_prices_provider.dart
│   └── trip_calculator_provider.dart
├── screens/             # Screens
│   ├── map_screen.dart
│   ├── fuel_prices_screen.dart
│   ├── trip_calculator_screen.dart
│   ├── station_details_screen.dart
│   └── review_form_screen.dart
├── widgets/             # Reusable components
│   ├── loading_skeleton.dart
│   ├── page_transitions.dart
│   └── station_details_bottom_sheet.dart
└── utils/               # Utilities
    ├── arabic_formatter.dart
    └── map_utils.dart
```

---

## 📖 Documentation

- **[SETUP.md](SETUP.md)** - Complete setup guide
- **[ENV_SETUP.md](ENV_SETUP.md)** - Environment variables setup
- **[GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md)** - Google Maps setup
- **[KULLANIM_KILAVUZU.md](KULLANIM_KILAVUZU.md)** - User guide (Arabic)
- **[database/README.md](database/README.md)** - Database guide

---

## 🗄️ Database Schema

### Main Tables

#### stations
```sql
- id (UUID)
- name (TEXT)
- latitude (DOUBLE)
- longitude (DOUBLE)
- address (TEXT)
- phone (TEXT)
- open_time (TIME)
- close_time (TIME)
- average_rating (DECIMAL)
```

#### fuel_types
```sql
- id (UUID)
- name (TEXT)
- price (DECIMAL)
- currency (TEXT)
- last_updated (TIMESTAMP)
```

#### reviews
```sql
- id (UUID)
- station_id (UUID)
- user_id (TEXT)
- rating (INTEGER 1-5)
- comment (TEXT)
- created_at (TIMESTAMP)
```

#### services
```sql
- id (UUID)
- station_id (UUID)
- name (TEXT)
- icon (TEXT)
```

---

## 🎨 UI/UX

- **Language**: Arabic (RTL)
- **Theme**: Material Design 3
- **Colors**: 
  - Primary: Blue (#2196F3)
  - Secondary: Orange (#FF9800)
  - Success: Green (#4CAF50)
- **Fonts**: Clear Arabic fonts
- **Animations**: Smooth transitions and loading effects

---

## 🔒 Security

- API keys stored in `.env` file (not uploaded to Git)
- Row Level Security (RLS) in Supabase
- Permission verification at database level
- Encrypted connections via HTTPS

---

## 🧪 Testing

```bash
# Run tests
flutter test

# Test OSRM service
flutter test test/services/osrm_service_test.dart
```

---

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- ⚠️ Web (limited - no location services)
- ⚠️ Windows/Linux/macOS (limited)

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the project
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## 📄 License

This project is licensed under the [MIT License](LICENSE)

---

## 📞 Support

For help or inquiries:
- Open an Issue on GitHub
- Review documentation in project folder

---

## 🙏 Acknowledgments

- **Flutter Team** - Amazing framework
- **Supabase** - Backend as a Service
- **Google Maps** - Maps services
- **OSRM** - Free routing service
- **Arab Community** - Support and contributions

---

**Made with ❤️ in Syria**
