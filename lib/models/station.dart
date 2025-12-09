import 'service.dart';

class Station {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String openTime;
  final String closeTime;
  final List<Service> services;
  final double? averageRating;

  Station({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    this.services = const [],
    this.averageRating,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      openTime: json['open_time'] as String,
      closeTime: json['close_time'] as String,
      services: (json['services'] as List<dynamic>?)
              ?.map((service) => Service.fromJson(service as Map<String, dynamic>))
              .toList() ??
          [],
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'open_time': openTime,
      'close_time': closeTime,
      'services': services.map((service) => service.toJson()).toList(),
      'average_rating': averageRating,
    };
  }

  String get operatingHours => '$openTime - $closeTime';
}
