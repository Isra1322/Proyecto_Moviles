import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/cart_item.dart';
import 'package:ecommerce_app/domain/entities/category.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/domain/repositories/i_auth_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_cart_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_order_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_product_repository.dart';

import 'package:ecommerce_app/application/use_cases/auth/get_saved_user_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/login_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/logout_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/register_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/create_order_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_orders_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_categories_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_product_by_id_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_products_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/get_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/add_to_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/update_cart_quantity_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/remove_from_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/clear_cart_use_case.dart';

import 'package:ecommerce_app/presentation/providers/auth_provider.dart';
import 'package:ecommerce_app/presentation/providers/cart_provider.dart';
import 'package:ecommerce_app/presentation/providers/order_provider.dart';
import 'package:ecommerce_app/presentation/providers/payment_provider.dart';
import 'package:ecommerce_app/presentation/providers/product_provider.dart';
import 'package:ecommerce_app/presentation/routes/app_routes.dart';
import 'package:ecommerce_app/presentation/screens/profile/profile_screen.dart';
import 'package:ecommerce_app/presentation/screens/catalog/product_detail_screen.dart';
import 'package:ecommerce_app/presentation/screens/cart/cart_screen.dart';
import 'package:ecommerce_app/infrastructure/datasources/remote/payment_service.dart';
import 'package:ecommerce_app/infrastructure/models/payment_method_model.dart';

class MockGuestAuthRepo implements IAuthRepository {
  User? user;
  MockGuestAuthRepo({this.user});

  @override
  Future<User> login(String username, String password) async {
    user = const User(
      uid: 99,
      name: 'Usuario Logueado',
      username: 'usuario@correo.com',
      partnerId: 99,
    );
    return user!;
  }

  @override
  Future<User> register(String name, String email, String password, {String? phone}) async => throw UnimplementedError();

  @override
  Future<User?> getSavedUser() async => user;

  @override
  Future<void> logout() async {
    user = null;
  }
}

class MockProductRepo implements IProductRepository {
  final List<Product> products;
  MockProductRepo(this.products);

  @override
  Future<List<Product>> getProducts({int? categoryId}) async => products;
  @override
  Future<Product> getProductById(int id) async => products.firstWhere((p) => p.id == id);
  @override
  Future<List<Category>> getCategories() async => [];
}

class MockCartRepo implements ICartRepository {
  Cart _cart;
  MockCartRepo([this._cart = const Cart()]);

  @override
  Future<Cart> getCart() async => _cart;
  @override
  Future<void> saveCart(Cart cart) async => _cart = cart;
  @override
  Future<void> clearCart() async => _cart = const Cart();
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
  }) async =>
      throw UnimplementedError();
  @override
  Future<List<Order>> getOrdersByCustomer(int customerId) async => [];
  @override
  Future<Order> getOrderById(int orderId) async => throw UnimplementedError();
}

class MockPaymentService implements PaymentService {
  List<PaymentMethodModel> methods;
  MockPaymentService([this.methods = const []]);

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async => methods;

  @override
  Future<PaymentMethodModel> addPaymentMethod({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    bool isDefault = false,
  }) async {
    final clean = cardNumber.replaceAll(' ', '');
    final last4 = clean.length >= 4 ? clean.substring(clean.length - 4) : clean;
    final newMethod = PaymentMethodModel(
      id: 'mock-1',
      partnerId: 99,
      cardHolderName: cardHolderName,
      maskedCardNumber: '**** **** **** $last4',
      cardType: 'Visa',
      expiryDate: expiryDate,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
    methods.add(newMethod);
    return newMethod;
  }

  @override
  Future<bool> deletePaymentMethod(String id) async {
    methods.removeWhere((m) => m.id == id);
    return true;
  }

  @override
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    String currency = 'usd',
    String? customerEmail,
    String? customerName,
  }) async =>
      {
        'clientSecret': 'pi_test_secret_123',
        'paymentIntentId': 'pi_test_123456789',
        'customerId': 'cus_test_123',
        'ephemeralKeySecret': 'ek_test_secret_123',
        'publishableKey': 'pk_test_mock',
      };
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES', null);
    await initializeDateFormatting('es', null);
  });

  const testProduct = Product(
    id: 10,
    name: 'Laptop Gamer Ultra',
    description: 'Potente laptop con 32GB RAM',
    price: 1500.0,
    stock: 5,
  );

  group('Modo Invitado (Guest Browsing) Tests', () {
    testWidgets('ProfileScreen en Modo Invitado muestra cabecera estilizada y oculta métricas en cero', (tester) async {
      final authRepo = MockGuestAuthRepo(user: null);
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      final orderRepo = MockOrderRepo();
      final cartRepo = MockCartRepo();
      final orderProvider = OrderProvider(CreateOrderUseCase(orderRepo, cartRepo), GetOrdersUseCase(orderRepo));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: orderProvider),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar la cabecera estilizada de usuario invitado
      expect(find.text('Bienvenido a E-Commerce'), findsOneWidget);
      expect(find.text('Iniciar Sesión o Registrarse'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

      // NO debe mostrar la tarjeta financiera con contadores en 0
      expect(find.text('Total Gastado Acumulado'), findsNothing);
      expect(find.text('Cerrar Sesión'), findsNothing);

      // Opción 'Mis Pedidos' disponible
      expect(find.text('Mis Pedidos'), findsOneWidget);
    });

    testWidgets('ProductDetailScreen en Modo Invitado intercepta "Agregar al Carrito" y muestra diálogo auth guard', (tester) async {
      final authRepo = MockGuestAuthRepo(user: null);
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      final productRepo = MockProductRepo([testProduct]);
      final productProvider = ProductProvider(
        GetProductsUseCase(productRepo),
        GetProductByIdUseCase(productRepo),
        GetCategoriesUseCase(productRepo),
      );
      final cartRepo = MockCartRepo();
      final cartProvider = CartProvider(
        GetCartUseCase(cartRepo),
        AddToCartUseCase(cartRepo),
        UpdateCartQuantityUseCase(cartRepo),
        RemoveFromCartUseCase(cartRepo),
        ClearCartUseCase(cartRepo),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: productProvider),
            ChangeNotifierProvider.value(value: cartProvider),
          ],
          child: MaterialApp(
            routes: {
              AppRoutes.login: (_) => const Scaffold(body: Text('Login Screen')),
            },
            home: const ProductDetailScreen(
              productId: 10,
              initialProduct: testProduct,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Presionar "Agregar al Carrito"
      final addToCartButton = find.widgetWithText(ElevatedButton, 'Agregar al Carrito');
      expect(addToCartButton, findsOneWidget);
      await tester.ensureVisible(addToCartButton);
      await tester.pumpAndSettle();
      await tester.tap(addToCartButton);
      await tester.pumpAndSettle();

      // Debe mostrar el diálogo de autenticación requerida
      expect(find.text('Inicia sesión para continuar'), findsOneWidget);
      expect(find.text('Necesitas una cuenta para gestionar tu carrito y realizar pedidos.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancelar'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'), findsOneWidget);

      // Si presiona cancelar, el diálogo se cierra
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Inicia sesión para continuar'), findsNothing);
      expect(cartProvider.totalItems, 0);
    });

    testWidgets('CartScreen en Modo Invitado intercepta checkout y muestra diálogo auth guard', (tester) async {
      final authRepo = MockGuestAuthRepo(user: null);
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      final cartRepo = MockCartRepo(const Cart(items: [
        CartItem(product: testProduct, quantity: 1, unitPrice: 1500.0),
      ]));
      final cartProvider = CartProvider(
        GetCartUseCase(cartRepo),
        AddToCartUseCase(cartRepo),
        UpdateCartQuantityUseCase(cartRepo),
        RemoveFromCartUseCase(cartRepo),
        ClearCartUseCase(cartRepo),
      );
      await cartProvider.loadCart();

      final orderRepo = MockOrderRepo();
      final orderProvider = OrderProvider(CreateOrderUseCase(orderRepo, cartRepo), GetOrdersUseCase(orderRepo));
      final paymentService = MockPaymentService();
      final paymentProvider = PaymentProvider(paymentService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: cartProvider),
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: paymentProvider),
          ],
          child: MaterialApp(
            routes: {
              AppRoutes.login: (_) => const Scaffold(body: Text('Login Screen')),
            },
            home: const CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Presionar "Confirmar Pedido"
      final confirmButton = find.widgetWithText(ElevatedButton, 'Confirmar Pedido');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Debe interceptar mostrando el diálogo
      expect(find.text('Inicia sesión para continuar'), findsOneWidget);
      expect(find.text('Necesitas una cuenta para gestionar tu carrito y realizar pedidos.'), findsOneWidget);
    });
  });
}
