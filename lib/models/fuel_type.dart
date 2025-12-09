class FuelType {
  final String id;
  final String name;
  final double price;
  final String currency;
  final DateTime lastUpdated;

  FuelType({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.lastUpdated,
  });

  factory FuelType.fromJson(Map<String, dynamic> json) {
    return FuelType(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'currency': currency,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
