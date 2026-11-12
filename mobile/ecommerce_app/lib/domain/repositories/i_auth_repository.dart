import '../entities/user.dart';

abstract class IAuthRepository {
  Future<User> login(String username, String password);
  Future<User> register(String name, String email, String password, {String? phone});
  Future<User?> getSavedUser();
  Future<void> logout();
}
