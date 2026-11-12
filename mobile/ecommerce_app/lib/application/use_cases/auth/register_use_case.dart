import '../../../domain/entities/user.dart';
import '../../../domain/repositories/i_auth_repository.dart';

class RegisterUseCase {
  final IAuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<User> execute({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('El nombre completo es obligatorio.');
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      throw ArgumentError('Ingresa un correo electrónico válido.');
    }
    if (password.length < 6) {
      throw ArgumentError('La contraseña debe tener al menos 6 caracteres.');
    }

    return await _repository.register(name, email, password, phone: phone);
  }
}
