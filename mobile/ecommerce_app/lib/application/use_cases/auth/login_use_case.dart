import '../../../domain/entities/user.dart';
import '../../../domain/repositories/i_auth_repository.dart';

class LoginUseCase {
  final IAuthRepository _repository;

  LoginUseCase(this._repository);

  Future<User> execute(String username, String password) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty) {
      throw ArgumentError('El correo o nombre de usuario es obligatorio.');
    }

    if (cleanPassword.isEmpty) {
      throw ArgumentError('La contraseña es obligatoria.');
    }

    return await _repository.login(cleanUsername, cleanPassword);
  }
}

