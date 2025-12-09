/// Exception for network-related errors (no internet, timeout, etc.)
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

/// Exception for database-related errors
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
}

/// Exception for OSRM API errors
class OSRMException implements Exception {
  final String message;
  OSRMException(this.message);

  @override
  String toString() => message;
}
