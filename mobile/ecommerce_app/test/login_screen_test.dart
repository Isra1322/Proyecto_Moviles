import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/domain/repositories/i_auth_repository.dart';
import 'package:ecommerce_app/application/use_cases/auth/get_saved_user_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/login_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/logout_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/register_use_case.dart';
import 'package:ecommerce_app/presentation/providers/auth_provider.dart';
import 'package:ecommerce_app/presentation/screens/auth/login_screen.dart';
import 'package:ecommerce_app/presentation/routes/app_routes.dart';

class MockAuthRepository implements IAuthRepository {
  bool loginCalled = false;
  String? lastUsername;
  String? lastPassword;

  @override
  Future<User> login(String username, String password) async {
    loginCalled = true;
    lastUsername = username;
    lastPassword = password;
    return const User(
      uid: 1,
      name: 'Test User',
      username: 'test@example.com',
      partnerId: 10,
    );
  }

  @override
  Future<User> register(
    String name,
    String email,
    String password, {
    String? phone,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<User?> getSavedUser() async => null;

  @override
  Future<void> logout() async {}
}

void main() {
  group('LoginScreen Validators Logic Tests', () {
    String? validateEmail(String? val) {
      if (val == null || val.trim().isEmpty) {
        return 'Por favor, ingresa tu correo electrónico';
      }
      final trimmed = val.trim();
      if (trimmed.endsWith('.')) {
        return 'Ingresa un correo electrónico válido';
      }
      if (RegExp(r'\.(com|net|org|ec)\.', caseSensitive: false).hasMatch(trimmed) ||
          trimmed.contains('..')) {
        return 'Ingresa un correo electrónico válido';
      }
      final emailRegex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(trimmed)) {
        return 'Ingresa un correo electrónico válido';
      }
      return null;
    }

    String? validatePassword(String? val) {
      if (val == null || val.trim().isEmpty) {
        return 'Por favor, ingresa tu contraseña';
      }
      return null;
    }

    test('Correo: rechaza nulo, vacío o sólo espacios con mensaje requerido', () {
      expect(validateEmail(null), 'Por favor, ingresa tu correo electrónico');
      expect(validateEmail(''), 'Por favor, ingresa tu correo electrónico');
      expect(validateEmail('   '), 'Por favor, ingresa tu correo electrónico');
    });

    test('Correo: rechaza formato inválido con mensaje de correo válido', () {
      expect(validateEmail('usuario'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio.'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio.c'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio..com'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio.com.'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio.com.ec'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio.123'), 'Ingresa un correo electrónico válido');
    });

    test('Correo: acepta correos con formato válido', () {
      expect(validateEmail('usuario@dominio.com'), isNull);
      expect(validateEmail('juan.perez@empresa.ec'), isNull);
      expect(validateEmail('carlos_123-test@correo.net'), isNull);
      expect(validateEmail('soporte@organizacion.org'), isNull);
    });

    test('Contraseña: rechaza nulo, vacío o sólo espacios', () {
      expect(validatePassword(null), 'Por favor, ingresa tu contraseña');
      expect(validatePassword(''), 'Por favor, ingresa tu contraseña');
      expect(validatePassword('   '), 'Por favor, ingresa tu contraseña');
    });

    test('Contraseña: acepta contraseña no vacía', () {
      expect(validatePassword('123456'), isNull);
      expect(validatePassword('miPasswordSeguro!'), isNull);
    });
  });

  group('LoginScreen Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late AuthProvider authProvider;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authProvider = AuthProvider(
        LoginUseCase(mockAuthRepository),
        RegisterUseCase(mockAuthRepository),
        GetSavedUserUseCase(mockAuthRepository),
        LogoutUseCase(mockAuthRepository),
      );
    });

    Widget createLoginWidget() {
      return MaterialApp(
        routes: {
          AppRoutes.catalog: (_) => const Scaffold(body: Text('Catalog')),
        },
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const LoginScreen(),
        ),
      );
    }

    testWidgets('Muestra errores requeridos al intentar enviar con campos vacíos', (tester) async {
      await tester.pumpWidget(createLoginWidget());

      // Inicialmente no se muestran errores
      expect(find.text('Por favor, ingresa tu correo electrónico'), findsNothing);
      expect(find.text('Por favor, ingresa tu contraseña'), findsNothing);

      // Presionar botón Iniciar Sesión
      final submitButton = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Deben aparecer los mensajes de error
      expect(find.text('Por favor, ingresa tu correo electrónico'), findsOneWidget);
      expect(find.text('Por favor, ingresa tu contraseña'), findsOneWidget);
      expect(mockAuthRepository.loginCalled, isFalse);
    });

    testWidgets('Autovalidación en tiempo real al escribir tras intento de envío', (tester) async {
      await tester.pumpWidget(createLoginWidget());

      final submitButton = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Por favor, ingresa tu correo electrónico'), findsOneWidget);

      // Escribir correo con formato inválido
      final emailField = find.widgetWithText(TextFormField, 'Correo electrónico');
      await tester.enterText(emailField, 'correo-invalido');
      await tester.pumpAndSettle();

      // Debe mostrar en tiempo real mensaje de formato inválido
      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
      expect(find.text('Por favor, ingresa tu correo electrónico'), findsNothing);

      // Corregir a correo válido
      await tester.enterText(emailField, 'usuario@dominio.com');
      await tester.pumpAndSettle();

      // El error de correo desaparece
      expect(find.text('Ingresa un correo electrónico válido'), findsNothing);
      expect(find.text('Por favor, ingresa tu correo electrónico'), findsNothing);

      // El error de contraseña sigue presente
      expect(find.text('Por favor, ingresa tu contraseña'), findsOneWidget);

      // Ingresar contraseña
      final passwordField = find.widgetWithText(TextFormField, 'Contraseña');
      await tester.enterText(passwordField, '123456');
      await tester.pumpAndSettle();

      // Error de contraseña desaparece en tiempo real
      expect(find.text('Por favor, ingresa tu contraseña'), findsNothing);

      // Ahora enviar debe tener éxito
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(mockAuthRepository.loginCalled, isTrue);
      expect(mockAuthRepository.lastUsername, 'usuario@dominio.com');
      expect(mockAuthRepository.lastPassword, '123456');
    });
  });
}
