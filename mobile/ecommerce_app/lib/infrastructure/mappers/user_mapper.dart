import '../../domain/entities/user.dart';
import '../models/login_models.dart';

class UserMapper {
  static User toEntity(LoginResponseModel model) {
    return User(
      uid: model.uid,
      name: model.name,
      username: model.username,
      partnerId: model.partnerId,
      sessionId: model.sessionId,
      accessToken: model.accessToken,
      isAuthenticated: model.isAuthenticated,
    );
  }

  static LoginResponseModel toModel(User entity) {
    return LoginResponseModel(
      uid: entity.uid,
      name: entity.name,
      username: entity.username,
      partnerId: entity.partnerId,
      sessionId: entity.sessionId,
      accessToken: entity.accessToken,
      isAuthenticated: entity.isAuthenticated,
    );
  }

  static User fromRegisterResponse(RegisterResponseModel model) {
    return User(
      uid: model.partnerId,
      name: model.name,
      username: model.email,
      partnerId: model.partnerId,
      accessToken: model.accessToken,
      isAuthenticated: model.success,
    );
  }
}
