import 'package:flutter/material.dart';
import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/application/use_cases/auth/login_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/register_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/get_saved_user_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/logout_use_case.dart';

enum ViewStatus { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetSavedUserUseCase _getSavedUserUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthProvider(
    this._loginUseCase,
    this._registerUseCase,
    this._getSavedUserUseCase,
    this._logoutUseCase,
  );

  ViewStatus _status = ViewStatus.initial;
  User? _currentUser;
  String? _errorMessage;

  ViewStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _currentUser!.isAuthenticated;
  bool get isLoading => _status == ViewStatus.loading;

  Future<void> checkSavedSession() async {
    _status = ViewStatus.loading;
    notifyListeners();
    try {
      _currentUser = await _getSavedUserUseCase.execute();
      _status = ViewStatus.success;
    } catch (_) {
      _currentUser = null;
      _status = ViewStatus.initial;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _loginUseCase.execute(username, password);
      _status = ViewStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      _status = ViewStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _registerUseCase.execute(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _status = ViewStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '').replaceAll('ArgumentError: ', '');
      _status = ViewStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _logoutUseCase.execute();
    _currentUser = null;
    _status = ViewStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
