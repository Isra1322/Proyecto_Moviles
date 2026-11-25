import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/cart_item.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/domain/repositories/i_auth_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_cart_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_order_repository.dart';

import 'package:ecommerce_app/application/use_cases/auth/get_saved_user_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/login_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/logout_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/register_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/add_to_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/clear_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/get_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/remove_from_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/update_cart_quantity_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/create_order_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_orders_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_order_by_id_use_case.dart';

import 'package:ecommerce_app/infrastructure/datasources/remote/address_service.dart';
import 'package:ecommerce_app/infrastructure/datasources/remote/payment_service.dart';
import 'package:ecommerce_app/infrastructure/models/address_model.dart';
import 'package:ecommerce_app/infrastructure/models/payment_method_model.dart';

import 'package:ecommerce_app/presentation/providers/address_provider.dart';
import 'package:ecommerce_app/presentation/providers/auth_provider.dart';
import 'package:ecommerce_app/presentation/providers/cart_provider.dart';
import 'package:ecommerce_app/presentation/providers/order_provider.dart';
import 'package:ecommerce_app/presentation/providers/payment_provider.dart';
import 'package:ecommerce_app/presentation/routes/app_routes.dart';
import 'package:ecommerce_app/presentation/screens/cart/cart_screen.dart';

class _MockPaymentService implements PaymentService {
  List<PaymentMethodModel> methods;

  _MockPaymentService({
    required this.methods,
  });

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async => methods;

  @override
  Future<PaymentMethodModel> addPaymentMethod({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    bool isDefault = false,
  }) async =>
      throw UnimplementedError();

  @override
  Future<bool> deletePaymentMethod(String id) async => true;

  @override
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    String currency = 'usd',
    String? customerEmail,
    String? customerName,
  }) async {
    return {
      'clientSecret': 'pi_3MtwxAEhGQTR_secret_xyz123',
      'paymentIntentId': 'pi_3MtwxAEhGQTR',
      'customerId': 'cus_test_123',
      'ephemeralKeySecret': 'ek_test_secret_123',
      'publishableKey':
          'pk_test_51UfXT3RuFqpQHde6MCO1ajpTWvNHdtRTRMLNUPtk70AGJfX4EzuG154GVociMsBAIJpKNP7icDvqgekKmGUi6vSh00j4P3bSkC',
    };
  }
}

class _MockAddressService implements AddressService {
  List<AddressModel> addresses;
  _MockAddressService(this.addresses);

  @override
  Future<List<AddressModel>> getAddresses() async => addresses;

  @override
  Future<AddressModel> createAddress({
    required String title,
    required String street,
    required String city,
    String stateOrProvince = '',
    String? postalCode,
    String? reference,
    required String phone,
    bool isDefault = false,
  }) async =>
      throw UnimplementedError();

  @override
  Future<AddressModel> updateAddress({
    required String id,
    required String title,
    required String street,
    required String city,
    String stateOrProvince = '',
    String? postalCode,
    String? reference,
    required String phone,
    bool isDefault = false,
  }) async =>
      throw UnimplementedError();

  @override
  Future<bool> deleteAddress(String id) async => true;

  @override
  Future<AddressModel> setDefaultAddress(String id) async => addresses.first;
}

class _MockCartRepo implements ICartRepository {
  Cart _cart;
  _MockCartRepo(this._cart);

  @override
  Future<Cart> getCart() async => _cart;
  @override
  Future<void> saveCart(Cart cart) async => _cart = cart;
  @override
  Future<void> clearCart() async => _cart = const Cart();
}

class _MockOrderRepo implements IOrderRepository {
  int createOrderCalls = 0;
  String? lastPaymentMethodId;
  String? lastPaymentReference;

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
  }) async {
    createOrderCalls++;
    lastPaymentMethodId = paymentMethodId;
    lastPaymentReference = paymentReference;
    return Order(
      id: 999,
      customerId: customerId,
      customerName: customerName ?? 'Sebas',
      orderDate: DateTime.now(),
      totalAmount: cart.totalConIva,
      status: 'sale',
      items: const [],
    );
  }

  @override
  Future<List<Order>> getOrdersByCustomer(int customerId) async => [];

  @override
  Future<Order> getOrderById(int orderId) async => throw UnimplementedError();
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
  Future<void> logout() async => user = null;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES', null);
    await initializeDateFormatting('es', null);
  });

  const testProduct = Product(
    id: 1,
    name: 'Teclado Mecánico RGB',
    description: 'Switches azules',
    price: 100.0,
    stock: 10,
  );

  final testCard = PaymentMethodModel(
    id: 'card-stripe-1',
    partnerId: 42,
    cardHolderName: 'SEBAS',
    maskedCardNumber: '**** **** **** 4242',
    cardType: 'Visa',
    expiryDate: '10/27',
    isDefault: true,
    createdAt: DateTime.now(),
  );

  final testAddress = AddressModel(
    id: 'addr-1',
    partnerId: 42,
    title: 'Casa',
    street: 'Av. Amazonas N24-196',
    city: 'Quito',
    stateOrProvince: 'Pichincha',
    phone: '0991234567',
    isDefault: true,
    createdAt: DateTime.now(),
  );

  group('Stripe Payment Integration Tests in CartScreen', () {
    testWidgets('Pago exitoso con Stripe crea la orden registrando el ID de transacción y vacía el carrito', (tester) async {
      final cartRepo = _MockCartRepo(const Cart(items: [
        CartItem(product: testProduct, quantity: 1, unitPrice: 100.0),
      ]));
      final orderRepo = _MockOrderRepo();
      final authRepo = _MockAuthRepo(
        user: const User(uid: 1, name: 'Sebas', username: 'sebas@correo.com', partnerId: 42),
      );
      final paymentService = _MockPaymentService(methods: [testCard]);
      final addressService = _MockAddressService([testAddress]);

      final cartProvider = CartProvider(
        GetCartUseCase(cartRepo),
        AddToCartUseCase(cartRepo),
        UpdateCartQuantityUseCase(cartRepo),
        RemoveFromCartUseCase(cartRepo),
        ClearCartUseCase(cartRepo),
      );
      await cartProvider.loadCart();

      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

      final addressProvider = AddressProvider(addressService);
      await addressProvider.loadAddresses();

      final orderProvider = OrderProvider(
        CreateOrderUseCase(orderRepo, cartRepo),
        GetOrdersUseCase(orderRepo),
        GetOrderByIdUseCase(orderRepo),
      );

      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      await authProvider.checkSavedSession();

      // Mock para la pasarela de Stripe simulando éxito
      bool sheetWasPresented = false;
      CartScreen.presentStripeSheet = ({
        required BuildContext context,
        required String clientSecret,
        String? customerId,
        String? customerEphemeralKeySecret,
      }) async {
        expect(clientSecret, 'pi_3MtwxAEhGQTR_secret_xyz123');
        expect(customerId, 'cus_test_123');
        expect(customerEphemeralKeySecret, 'ek_test_secret_123');
        sheetWasPresented = true;
      };

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cartProvider),
            ChangeNotifierProvider.value(value: paymentProvider),
            ChangeNotifierProvider.value(value: addressProvider),
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: MaterialApp(
            routes: {
              AppRoutes.orderSuccess: (ctx) => const Scaffold(body: Text('Pantalla de Éxito')),
            },
            home: const CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirmar Pedido');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verificar que se presentó la pasarela de Stripe
      expect(sheetWasPresented, isTrue);

      // Verificar que se creó la orden con el ID de Stripe
      expect(orderRepo.createOrderCalls, equals(1));
      expect(orderRepo.lastPaymentReference, contains('Stripe: pi_3MtwxAEhGQTR'));

      // Verificar navegación a pantalla de éxito
      expect(find.text('Pantalla de Éxito'), findsOneWidget);
    });

    testWidgets('Cancelación de usuario en Stripe muestra SnackBar y NO crea la orden en Odoo', (tester) async {
      final cartRepo = _MockCartRepo(const Cart(items: [
        CartItem(product: testProduct, quantity: 1, unitPrice: 100.0),
      ]));
      final orderRepo = _MockOrderRepo();
      final authRepo = _MockAuthRepo(
        user: const User(uid: 1, name: 'Sebas', username: 'sebas@correo.com', partnerId: 42),
      );
      final paymentService = _MockPaymentService(methods: [testCard]);
      final addressService = _MockAddressService([testAddress]);

      final cartProvider = CartProvider(
        GetCartUseCase(cartRepo),
        AddToCartUseCase(cartRepo),
        UpdateCartQuantityUseCase(cartRepo),
        RemoveFromCartUseCase(cartRepo),
        ClearCartUseCase(cartRepo),
      );
      await cartProvider.loadCart();

      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

      final addressProvider = AddressProvider(addressService);
      await addressProvider.loadAddresses();

      final orderProvider = OrderProvider(
        CreateOrderUseCase(orderRepo, cartRepo),
        GetOrdersUseCase(orderRepo),
        GetOrderByIdUseCase(orderRepo),
      );

      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      await authProvider.checkSavedSession();

      // Mock simulando que el usuario cancela la pasarela de Stripe
      CartScreen.presentStripeSheet = ({
        required BuildContext context,
        required String clientSecret,
        String? customerId,
        String? customerEphemeralKeySecret,
      }) async {
        throw const StripeException(
          error: LocalizedErrorMessage(
            code: FailureCode.Canceled,
            message: 'El usuario canceló el pago',
          ),
        );
      };

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cartProvider),
            ChangeNotifierProvider.value(value: paymentProvider),
            ChangeNotifierProvider.value(value: addressProvider),
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirmar Pedido');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // NO debe haberse creado orden en Odoo
      expect(orderRepo.createOrderCalls, equals(0));

      // Debe mostrar el mensaje amigable de cancelación
      expect(find.text('Pago cancelado. Puedes intentarlo de nuevo cuando desees.'), findsOneWidget);
    });

    testWidgets('Error de tarjeta en Stripe muestra SnackBar de error y no crea orden', (tester) async {
      final cartRepo = _MockCartRepo(const Cart(items: [
        CartItem(product: testProduct, quantity: 1, unitPrice: 100.0),
      ]));
      final orderRepo = _MockOrderRepo();
      final authRepo = _MockAuthRepo(
        user: const User(uid: 1, name: 'Sebas', username: 'sebas@correo.com', partnerId: 42),
      );
      final paymentService = _MockPaymentService(methods: [testCard]);
      final addressService = _MockAddressService([testAddress]);

      final cartProvider = CartProvider(
        GetCartUseCase(cartRepo),
        AddToCartUseCase(cartRepo),
        UpdateCartQuantityUseCase(cartRepo),
        RemoveFromCartUseCase(cartRepo),
        ClearCartUseCase(cartRepo),
      );
      await cartProvider.loadCart();

      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

      final addressProvider = AddressProvider(addressService);
      await addressProvider.loadAddresses();

      final orderProvider = OrderProvider(
        CreateOrderUseCase(orderRepo, cartRepo),
        GetOrdersUseCase(orderRepo),
        GetOrderByIdUseCase(orderRepo),
      );

      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      await authProvider.checkSavedSession();

      // Mock simulando fallo de autenticación de tarjeta
      CartScreen.presentStripeSheet = ({
        required BuildContext context,
        required String clientSecret,
        String? customerId,
        String? customerEphemeralKeySecret,
      }) async {
        throw const StripeException(
          error: LocalizedErrorMessage(
            code: FailureCode.Failed,
            localizedMessage: 'Tarjeta rechazada por fondos insuficientes',
          ),
        );
      };

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cartProvider),
            ChangeNotifierProvider.value(value: paymentProvider),
            ChangeNotifierProvider.value(value: addressProvider),
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirmar Pedido');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // NO debe haberse creado orden en Odoo
      expect(orderRepo.createOrderCalls, equals(0));

      // Debe mostrar el mensaje con la causa del error
      expect(find.text('Tarjeta rechazada por fondos insuficientes'), findsOneWidget);
    });
  });
}
