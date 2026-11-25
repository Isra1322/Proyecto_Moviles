import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/domain/repositories/i_auth_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_order_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_cart_repository.dart';
import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/order.dart';

import 'package:ecommerce_app/application/use_cases/auth/login_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/register_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/get_saved_user_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/logout_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/create_order_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_orders_use_case.dart';

import 'package:ecommerce_app/presentation/providers/auth_provider.dart';
import 'package:ecommerce_app/presentation/providers/order_provider.dart';
import 'package:ecommerce_app/presentation/providers/theme_provider.dart';
import 'package:ecommerce_app/presentation/routes/app_routes.dart';
import 'package:ecommerce_app/presentation/screens/profile/profile_screen.dart';
import 'package:ecommerce_app/presentation/screens/profile/settings_screen.dart';

class MockAuthRepo implements IAuthRepository {
  User? user;
  MockAuthRepo({this.user});

  @override
  Future<User> login(String username, String password) async => user!;
  @override
  Future<User> register(String name, String email, String password, {String? phone}) async => user!;
  @override
  Future<User?> getSavedUser() async => user;
  @override
  Future<void> logout() async {
    user = null;
  }
}

class MockOrderRepo implements IOrderRepository {
  @override
  Future<Order> createOrder({
    required int customerId,
    required Cart cart,
    String? customerName,
    String? customerEmail,
    String? paymentMethodId,
    String? paymentReference,
    String? shippingAddressId,
    String? shippingAddressText,
  }) async => throw UnimplementedError();

  @override
  Future<List<Order>> getOrdersByCustomer(int customerId) async => [];
  @override
  Future<Order> getOrderById(int orderId) async => throw UnimplementedError();
}

class MockCartRepo implements ICartRepository {
  @override
  Future<Cart> getCart() async => const Cart();
  @override
  Future<void> saveCart(Cart cart) async {}
  @override
  Future<void> clearCart() async {}
}

void main() {
  group('ThemeProvider Unit Tests', () {
    test('Inicializa en ThemeMode.system por defecto', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.isDarkMode, isFalse);
    });

    test('setThemeMode actualiza y notifica listeners', () async {
      final provider = ThemeProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);
      expect(notified, isTrue);

      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, isFalse);
    });
  });

  group('ProfileScreen Settings Button Tests', () {
    testWidgets('Muestra icono de tuerca de configuración en la AppBar y navega a SettingsScreen', (tester) async {
      final authRepo = MockAuthRepo(
        user: const User(uid: 1, name: 'Juan Perez', username: 'juan@correo.com', partnerId: 42),
      );
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      authProvider.login('juan@correo.com', '123456');

      final orderRepo = MockOrderRepo();
      final cartRepo = MockCartRepo();
      final orderProvider = OrderProvider(CreateOrderUseCase(orderRepo, cartRepo), GetOrdersUseCase(orderRepo));
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: themeProvider),
          ],
          child: MaterialApp(
            routes: {
              AppRoutes.settings: (_) => const Scaffold(body: Text('Pantalla de Configuración')),
            },
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar el icono de configuración
      final settingsButton = find.byIcon(Icons.settings_outlined);
      expect(settingsButton, findsOneWidget);

      // Al presionarlo, navega a configuración
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      expect(find.text('Pantalla de Configuración'), findsOneWidget);
    });
  });

  group('SettingsScreen Tests', () {
    testWidgets('Muestra opciones de Apariencia y cambia el ThemeMode', (tester) async {
      final authRepo = MockAuthRepo(
        user: const User(uid: 1, name: 'Juan Perez', username: 'juan@correo.com', partnerId: 42),
      );
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: themeProvider),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar sección Apariencia
      expect(find.text('Apariencia'), findsOneWidget);
      expect(find.text('Predeterminado del sistema'), findsOneWidget);
      expect(find.text('Modo Claro'), findsOneWidget);
      expect(find.text('Modo Oscuro'), findsOneWidget);

      // Cambiar a Modo Oscuro
      await tester.tap(find.text('Modo Oscuro'));
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.dark);

      // Cambiar a Modo Claro
      await tester.tap(find.text('Modo Claro'));
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    testWidgets('Muestra formulario de Información de la Cuenta y guarda cambios', (tester) async {
      final authRepo = MockAuthRepo(
        user: const User(
          uid: 1,
          name: 'Juan Perez',
          username: 'juan@correo.com',
          partnerId: 42,
          phone: '0991234567',
        ),
      );
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      authProvider.login('juan@correo.com', '123456');

      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: themeProvider),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar sección Información de la Cuenta
      expect(find.text('Información de la Cuenta'), findsOneWidget);
      expect(find.text('Juan Perez'), findsOneWidget);
      expect(find.text('0991234567'), findsOneWidget);
      expect(find.text('juan@correo.com'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      // Editar nombre
      final nameField = find.widgetWithText(TextFormField, 'Nombre Completo *');
      await tester.enterText(nameField, 'Carlos Gomez');

      // Editar teléfono
      final phoneField = find.widgetWithText(TextFormField, 'Teléfono de Contacto');
      await tester.enterText(phoneField, '0987654321');

      // Presionar Guardar Cambios
      final saveBtn = find.widgetWithText(ElevatedButton, 'Guardar Cambios');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verificar snackbar y datos actualizados en el provider
      expect(find.text('Datos actualizados correctamente'), findsOneWidget);
      expect(authProvider.currentUser?.name, 'Carlos Gomez');
      expect(authProvider.currentUser?.phone, '0987654321');
    });

    testWidgets('Muestra tarjeta de sesión no iniciada en modo invitado', (tester) async {
      final authRepo = MockAuthRepo(user: null);
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: themeProvider),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sesión no iniciada'), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });
  });
}
