import '../../../domain/entities/user.dart';
import '../../../domain/repositories/i_auth_repository.dart';

class GetSavedUserUseCase {
  final IAuthRepository _repository;

  GetSavedUserUseCase(this._repository);

  Future<User?> execute() async {
    return await _repository.getSavedUser();
  }
}

