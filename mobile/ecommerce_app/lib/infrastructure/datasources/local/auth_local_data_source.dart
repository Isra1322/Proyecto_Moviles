import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/infrastructure/mappers/user_mapper.dart';
import 'package:ecommerce_app/infrastructure/models/login_models.dart';

class AuthLocalDataSource {
  static const String _userKey = 'cached_user_session';
  final SharedPreferences _prefs;

  AuthLocalDataSource(this._prefs);

  Future<void> saveUser(User user) async {
    final model = UserMapper.toModel(user);
    final jsonString = jsonEncode(model.toJson());
    await _prefs.setString(_userKey, jsonString);
  }

  Future<User?> getUser() async {
    final jsonString = _prefs.getString(_userKey);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final model = LoginResponseModel.fromJson(jsonMap);
      return UserMapper.toEntity(model);
    } catch (_) {
      await clearUser();
      return null;
    }
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }
}
