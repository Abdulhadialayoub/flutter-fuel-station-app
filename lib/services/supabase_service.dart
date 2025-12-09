import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'exceptions.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Fetch all stations from the database
  Future<List<Station>> fetchStations() async {
    try {
      final response = await _client
          .from('stations')
          .select('*, services(*)')
          .timeout(const Duration(seconds: 10));

      final List<dynamic> data = response;
      return data.map((json) => Station.fromJson(json as Map<String, dynamic>)).toList();
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on PostgrestException catch (e) {
      throw DatabaseException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw DatabaseException('حدث خطأ غير متوقع: $e');
    }
  }

  /// Fetch a single station by ID
  Future<Station> fetchStationById(String id) async {
    try {
      final response = await _client
          .from('stations')
          .select('*, services(*)')
          .eq('id', id)
          .single()
          .timeout(const Duration(seconds: 10));

      return Station.fromJson(response);
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on PostgrestException catch (e) {
      throw DatabaseException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw DatabaseException('حدث خطأ غير متوقع: $e');
    }
  }

  /// Search stations by name (case-insensitive)
  Future<List<Station>> searchStations(String query) async {
    try {
      final response = await _client
          .from('stations')
          .select('*, services(*)')
          .ilike('name', '%$query%')
          .timeout(const Duration(seconds: 10));

      final List<dynamic> data = response;
      return data.map((json) => Station.fromJson(json as Map<String, dynamic>)).toList();
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on PostgrestException catch (e) {
      throw DatabaseException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw DatabaseException('حدث خطأ غير متوقع: $e');
    }
  }

  /// Search stations by service name
  Future<List<Station>> searchStationsByService(String serviceName) async {
    try {
      final response = await _client
          .from('stations')
          .select('*, services!inner(*)')
          .ilike('services.name', '%$serviceName%')
          .timeout(const Duration(seconds: 10));

      final List<dynamic> data = response;
      return data.map((json) => Station.fromJson(json as Map<String, dynamic>)).toList();
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on PostgrestException catch (e) {
      throw DatabaseException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw DatabaseException('حدث خطأ غير متوقع: $e');
    }
  }

  // ==================== Fuel Type Operations ====================

  /// Fetch all fuel types with current prices
  Future<List<FuelType>> fetchFuelTypes() async {
    try {
      final response = await _client
          .from('fuel_types')
          .select()
          .timeout(const Duration(seconds: 10));

      final List<dynamic> data = response;
      return data.map((json) => FuelType.fromJson(json as Map<String, dynamic>)).toList();
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on PostgrestException catch (e) {
      throw DatabaseException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw DatabaseException('حدث خطأ غير متوقع: $e');
    }
  }

  /// Fetch a single fuel type by ID
  Future<FuelType> fetchFuelTypeById(String id) async {
    try {
      final response = await _client
          .from('fuel_types')
          .select()
          .eq('id', id)
          .single()
          .timeout(const Duration(seconds: 10));

      return FuelType.fromJson(response);
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on PostgrestException catch (e) {
      throw DatabaseException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw DatabaseException('حدث خطأ غير متوقع: $e');
    }
  }

  // ==================== Review Operations ====================

  /// Fetch all reviews for a specific station
  Future<List<Review>> fetchReviewsForStation(String stationId) async {
    try {
      final response = await _client
          .from('reviews')
          .select()
          .eq('station_id', stationId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      final List<dynamic> data = response;
      return data.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on PostgrestException catch (e) {
      throw DatabaseException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw DatabaseException('حدث خطأ غير متوقع: $e');
    }
  }

  /// Submit a new review for a station
  Future<void> submitReview(Review review) async {
    try {
      await _client
          .from('reviews')
          .insert(review.toJson())
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on PostgrestException catch (e) {
      throw DatabaseException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw DatabaseException('حدث خطأ غير متوقع: $e');
    }
  }

  /// Calculate the average rating for a station
  Future<double> calculateAverageRating(String stationId) async {
    try {
      final response = await _client
          .from('reviews')
          .select('rating')
          .eq('station_id', stationId)
          .timeout(const Duration(seconds: 10));

      final List<dynamic> data = response;
      
      if (data.isEmpty) {
        return 0.0;
      }

      final ratings = data.map((json) => (json['rating'] as int).toDouble()).toList();
      
      if (ratings.isEmpty) {
        return 0.0;
      }

      final sum = ratings.reduce((a, b) => a + b);
      return sum / ratings.length;
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on PostgrestException catch (e) {
      throw DatabaseException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw DatabaseException('حدث خطأ غير متوقع: $e');
    }
  }

  // ==================== Service Operations ====================

  /// Fetch all services for a specific station
  Future<List<Service>> fetchServicesForStation(String stationId) async {
    try {
      final response = await _client
          .from('services')
          .select()
          .eq('station_id', stationId)
          .timeout(const Duration(seconds: 10));

      final List<dynamic> data = response;
      return data.map((json) => Service.fromJson(json as Map<String, dynamic>)).toList();
    } on SocketException {
      throw NetworkException('لا يوجد اتصال بالإنترنت');
    } on TimeoutException {
      throw NetworkException('انتهت مهلة الاتصال');
    } on PostgrestException catch (e) {
      throw DatabaseException('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      throw DatabaseException('حدث خطأ غير متوقع: $e');
    }
  }
}
