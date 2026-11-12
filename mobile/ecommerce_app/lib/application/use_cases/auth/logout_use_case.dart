import '../../../domain/repositories/i_auth_repository.dart';

class LogoutUseCase {
  final IAuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<void> execute() async {
    await _repository.logout();
  }
}

