class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = 'No se pudo conectar con el servidor. Revisa tu conexión a internet.'});

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;

  AuthException({required this.message});

  @override
  String toString() => 'AuthException: $message';
}

class CacheException implements Exception {
  final String message;

  CacheException({this.message = 'Error al acceder al almacenamiento local.'});

  @override
  String toString() => 'CacheException: $message';
}

