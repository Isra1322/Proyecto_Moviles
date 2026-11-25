import 'package:flutter/material.dart';
import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/application/use_cases/auth/login_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/register_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/get_saved_user_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/logout_use_case.dart';
import 'package:ecommerce_app/infrastructure/datasources/local/auth_local_data_source.dart';

enum ViewStatus { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetSavedUserUseCase _getSavedUserUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthLocalDataSource? _authLocalDataSource;

  AuthProvider(
    this._loginUseCase,
    this._registerUseCase,
    this._getSavedUserUseCase,
    this._logoutUseCase, [
    this._authLocalDataSource,
  ]);

  ViewStatus _status = ViewStatus.initial;
  User? _currentUser;
  String? _errorMessage;
  bool _requiresVerification = false;

  ViewStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get requiresVerification => _requiresVerification;
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
    _requiresVerification = false;
    notifyListeners();
    try {
      final user = await _registerUseCase.execute(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _requiresVerification = user.requiresVerification;
      if (!user.requiresVerification) {
        _currentUser = user;
      } else {
        _currentUser = null;
      }
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

  Future<void> updateProfile({
    required String name,
    String? phone,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      name: name,
      phone: phone,
    );
    final localDs = _authLocalDataSource;
    if (localDs != null) {
      await localDs.saveUser(_currentUser!);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _logoutUseCase.execute();
    _currentUser = null;
    _status = ViewStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
