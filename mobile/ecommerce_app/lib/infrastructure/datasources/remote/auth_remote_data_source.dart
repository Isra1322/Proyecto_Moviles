import 'package:ecommerce_app/core/constants/api_constants.dart';
import 'package:ecommerce_app/infrastructure/http/api_client.dart';
import 'package:ecommerce_app/infrastructure/models/login_models.dart';

class AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSource(this._client);

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final data = await _client.post(
      ApiConstants.login,
      body: request.toJson(),
    );

    if (data is Map<String, dynamic>) {
      final responseModel = LoginResponseModel.fromJson(data);
      if (responseModel.accessToken != null) {
        _client.setAuthToken(responseModel.accessToken);
      }
      return responseModel;
    }
    throw const FormatException('Respuesta inválida recibida desde el endpoint de autenticación.');
  }

  Future<RegisterResponseModel> register(RegisterRequestModel request) async {
    final data = await _client.post(
      ApiConstants.register,
      body: request.toJson(),
    );

    if (data is Map<String, dynamic>) {
      final responseModel = RegisterResponseModel.fromJson(data);
      if (responseModel.accessToken != null) {
        _client.setAuthToken(responseModel.accessToken);
      }
      return responseModel;
    }
    throw const FormatException('Respuesta inválida recibida desde el endpoint de registro.');
  }
}
