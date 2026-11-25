import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/domain/repositories/i_auth_repository.dart';
import 'package:ecommerce_app/application/use_cases/auth/login_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/register_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/get_saved_user_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/logout_use_case.dart';
import 'package:ecommerce_app/presentation/providers/auth_provider.dart';
import 'package:ecommerce_app/presentation/providers/theme_provider.dart';
import 'package:ecommerce_app/presentation/providers/product_provider.dart';
import 'package:ecommerce_app/presentation/providers/order_provider.dart';
import 'package:ecommerce_app/presentation/providers/cart_provider.dart';
import 'package:ecommerce_app/domain/repositories/i_product_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_order_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_cart_repository.dart';
import 'package:ecommerce_app/domain/entities/category.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/application/use_cases/products/get_products_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_product_by_id_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_categories_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/create_order_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_orders_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_order_by_id_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/get_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/add_to_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/update_cart_quantity_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/remove_from_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/clear_cart_use_case.dart';
import 'package:ecommerce_app/presentation/screens/auth/login_screen.dart';
import 'package:ecommerce_app/presentation/screens/catalog/catalog_screen.dart';
import 'package:ecommerce_app/presentation/screens/catalog/categories_screen.dart';
import 'package:ecommerce_app/presentation/screens/profile/profile_screen.dart';
import 'package:ecommerce_app/presentation/widgets/product/product_card.dart';
import 'package:ecommerce_app/presentation/screens/profile/settings_screen.dart';

class _MockProductRepo implements IProductRepository {
  @override
  Future<List<Product>> getProducts({int? categoryId}) async => [];
  @override
  Future<Product> getProductById(int id) async => throw UnimplementedError();
  @override
  Future<List<Category>> getCategories() async => [];
}

class _MockOrderRepo implements IOrderRepository {
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

class _MockCartRepo implements ICartRepository {
  @override
  Future<Cart> getCart() async => const Cart();
  @override
  Future<void> saveCart(Cart cart) async {}
  @override
  Future<void> clearCart() async {}
}

class _MockAuthRepo implements IAuthRepository {
  User? user;
  _MockAuthRepo({this.user});

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

void main() {
  group('AppTheme Configuration Tests', () {
    test('Dark theme contains exact requested colors and schemes', () {
      final dark = AppTheme.darkTheme;

      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, const Color(0xFF121212));
      expect(dark.primaryColor, const Color(0xFF2196F3));
      expect(dark.colorScheme.surface, const Color(0xFF1E1E1E));
      expect(dark.colorScheme.onSurface, const Color(0xFFF5F5F5));
      expect(dark.colorScheme.onSurfaceVariant, const Color(0xFFAAAAAA));
      expect(dark.cardTheme.color, const Color(0xFF1E1E1E));
      expect(dark.inputDecorationTheme.fillColor, const Color(0xFF2A2A2A));
      expect(dark.appBarTheme.backgroundColor, const Color(0xFF1E1E1E));
      expect(dark.bottomNavigationBarTheme.backgroundColor, const Color(0xFF1E1E1E));
      expect(dark.bottomNavigationBarTheme.selectedItemColor, const Color(0xFF2196F3));
      expect(dark.bottomNavigationBarTheme.unselectedItemColor, const Color(0xFFAAAAAA));
    });

    test('Light theme contains correct default theme properties', () {
      final light = AppTheme.lightTheme;

      expect(light.brightness, Brightness.light);
      expect(light.scaffoldBackgroundColor, AppColors.background);
      expect(light.primaryColor, AppColors.primary);
      expect(light.cardTheme.color, Colors.white);
      expect(light.appBarTheme.backgroundColor, Colors.white);
      expect(light.bottomNavigationBarTheme.backgroundColor, Colors.white);
      expect(light.bottomNavigationBarTheme.selectedItemColor, AppColors.primary);
    });
  });

  group('Dark Theme Widget Rendering Tests', () {
    testWidgets('ProductCard renders white text and blue price in dark mode', (tester) async {
      const product = Product(
        id: 1,
        name: 'Memoria RAM 16GB RGB',
        price: 85.0,
        stock: 10,
        imageUrl: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: ProductCard(product: product),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameFinder = find.text('Memoria RAM 16GB RGB');
      expect(nameFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(nameFinder);
      expect(textWidget.style?.color, Colors.white);

      final priceFinder = find.textContaining('85');
      expect(priceFinder, findsOneWidget);
      final priceWidget = tester.widget<Text>(priceFinder);
      expect(priceWidget.style?.color, AppColors.primary);
    });

    testWidgets('SettingsScreen renders dark theme options with high contrast', (tester) async {
      final authRepo = _MockAuthRepo(
        user: const User(uid: 1, name: 'Ana Lopez', username: 'ana@example.com', partnerId: 10),
      );
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      )..checkSavedSession();

      final themeProvider = ThemeProvider();
      await themeProvider.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: themeProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configuración'), findsOneWidget);
      expect(find.text('Apariencia'), findsOneWidget);
      expect(find.text('Modo Oscuro'), findsOneWidget);
      expect(find.text('Predeterminado del sistema'), findsOneWidget);
      expect(find.text('Modo Claro'), findsOneWidget);
      expect(find.text('Información de la Cuenta'), findsOneWidget);
    });

    testWidgets('LoginScreen disables leading back arrow and has high contrast button', (tester) async {
      final authRepo = _MockAuthRepo();
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.automaticallyImplyLeading, isFalse);
      expect(appBar.leading, isNull);
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      final loginBtn = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      expect(loginBtn, findsOneWidget);

      final btnText = find.text('Iniciar Sesión');
      final textWidget = tester.widget<Text>(btnText);
      expect(textWidget.style?.color, Colors.white);
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('CatalogScreen, CategoriesScreen and ProfileScreen have automaticallyImplyLeading false', (tester) async {
      final productRepo = _MockProductRepo();
      final orderRepo = _MockOrderRepo();
      final cartRepo = _MockCartRepo();
      final authRepo = _MockAuthRepo();

      final productProvider = ProductProvider(
        GetProductsUseCase(productRepo),
        GetProductByIdUseCase(productRepo),
        GetCategoriesUseCase(productRepo),
      );
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      final orderProvider = OrderProvider(
        CreateOrderUseCase(orderRepo, cartRepo),
        GetOrdersUseCase(orderRepo),
        GetOrderByIdUseCase(orderRepo),
      );
      final cartProvider = CartProvider(
        GetCartUseCase(cartRepo),
        AddToCartUseCase(cartRepo),
        UpdateCartQuantityUseCase(cartRepo),
        RemoveFromCartUseCase(cartRepo),
        ClearCartUseCase(cartRepo),
      );

      // 1. CatalogScreen
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: productProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: cartProvider),
          ],
          child: const MaterialApp(home: CatalogScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final catalogAppBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(catalogAppBar.automaticallyImplyLeading, isFalse);
      expect(catalogAppBar.leading, isNull);

      // 2. CategoriesScreen
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: productProvider),
            ChangeNotifierProvider.value(value: cartProvider),
          ],
          child: const MaterialApp(home: CategoriesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final categoriesAppBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(categoriesAppBar.automaticallyImplyLeading, isFalse);
      expect(categoriesAppBar.leading, isNull);

      // 3. ProfileScreen
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: orderProvider),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final profileAppBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(profileAppBar.automaticallyImplyLeading, isFalse);
      expect(profileAppBar.leading, isNull);
    });
  });
}
