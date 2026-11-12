import 'package:ecommerce_app/core/errors/exceptions.dart';
import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/domain/repositories/i_auth_repository.dart';
import 'package:ecommerce_app/infrastructure/datasources/local/auth_local_data_source.dart';
import 'package:ecommerce_app/infrastructure/datasources/remote/auth_remote_data_source.dart';
import 'package:ecommerce_app/infrastructure/mappers/user_mapper.dart';
import 'package:ecommerce_app/infrastructure/models/login_models.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<User> login(String username, String password) async {
    final request = LoginRequestModel(username: username, password: password);
    final response = await _remoteDataSource.login(request);

    if (!response.isAuthenticated) {
      throw AuthException(message: response.message ?? 'Credenciales incorrectas.');
    }

    final user = UserMapper.toEntity(response);
    await _localDataSource.saveUser(user);
    return user;
  }

  @override
  Future<User> register(String name, String email, String password, {String? phone}) async {
    final request = RegisterRequestModel(name: name, email: email, password: password, phone: phone);
    final response = await _remoteDataSource.register(request);

    if (!response.success) {
      throw AuthException(message: response.message ?? 'Fallo en el registro de cliente.');
    }

    final user = UserMapper.fromRegisterResponse(response);
    await _localDataSource.saveUser(user);
    return user;
  }

  @override
  Future<User?> getSavedUser() async {
    return await _localDataSource.getUser();
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearUser();
  }
}
