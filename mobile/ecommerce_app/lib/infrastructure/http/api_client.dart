import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';

class ApiClient {
  final http.Client _client;
  final String baseUrl;
  String? _authToken;

  ApiClient({
    http.Client? client,
    this.baseUrl = ApiConstants.baseUrl,
  }) : _client = client ?? http.Client();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams?.map((key, value) => MapEntry(key, value)),
    );
    return _send(() => _client.get(uri, headers: _headers));
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return _send(() => _client.post(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        ));
  }

  Future<dynamic> _send(Future<http.Response> Function() action) async {
    try {
      final response = await action().timeout(ApiConstants.timeout);
      final bodyString = utf8.decode(response.bodyBytes);
      final json = bodyString.isNotEmpty ? jsonDecode(bodyString) : null;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Soporte del envelope ApiResponse<T> de .NET: { success, message, data }
        if (json is Map<String, dynamic> && json.containsKey('success')) {
          final isSuccess = json['success'] as bool? ?? false;
          if (!isSuccess) {
            throw ServerException(
              message: json['message']?.toString() ?? 'Error en la respuesta del servidor.',
              statusCode: response.statusCode,
            );
          }
          return json['data'];
        }
        return json;
      } else if (response.statusCode == 401) {
        final message = json is Map<String, dynamic> ? json['message']?.toString() : null;
        throw AuthException(message: message ?? 'Credenciales no autorizadas o sesión expirada.');
      } else if (response.statusCode == 404) {
        final message = json is Map<String, dynamic> ? json['message']?.toString() : null;
        throw ServerException(
          message: message ?? 'El recurso solicitado no fue encontrado (404).',
          statusCode: 404,
        );
      } else {
        final message = json is Map<String, dynamic> ? json['message']?.toString() : null;
        throw ServerException(
          message: message ?? 'Error en el servidor con código ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException();
    } on http.ClientException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException(message: 'Tiempo de espera agotado al conectar con el servidor.');
    } on FormatException {
      throw ServerException(message: 'La respuesta del servidor no tiene un formato JSON válido.');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw ServerException(message: 'Error inesperado de comunicación: $e');
    }
  }
}
