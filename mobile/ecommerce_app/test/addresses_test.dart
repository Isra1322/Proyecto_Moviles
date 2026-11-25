import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/cart_item.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/domain/repositories/i_auth_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_cart_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_order_repository.dart';
import 'package:ecommerce_app/application/use_cases/auth/login_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/register_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/get_saved_user_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/logout_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/get_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/add_to_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/update_cart_quantity_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/remove_from_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/clear_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/create_order_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_orders_use_case.dart';
import 'package:ecommerce_app/presentation/providers/auth_provider.dart';
import 'package:ecommerce_app/presentation/providers/cart_provider.dart';
import 'package:ecommerce_app/presentation/providers/order_provider.dart';
import 'package:ecommerce_app/presentation/providers/payment_provider.dart';
import 'package:ecommerce_app/infrastructure/models/address_model.dart';
import 'package:ecommerce_app/infrastructure/models/payment_method_model.dart';
import 'package:ecommerce_app/infrastructure/datasources/remote/address_service.dart';
import 'package:ecommerce_app/infrastructure/datasources/remote/payment_service.dart';
import 'package:ecommerce_app/presentation/providers/address_provider.dart';
import 'package:ecommerce_app/presentation/screens/address/address_list_screen.dart';
import 'package:ecommerce_app/presentation/screens/cart/cart_screen.dart';
import 'package:ecommerce_app/presentation/widgets/address/add_edit_address_modal.dart';
import 'package:ecommerce_app/presentation/routes/app_routes.dart';

class MockAddressService implements AddressService {
  List<AddressModel> addresses;
  MockAddressService([this.addresses = const []]);

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
  }) async {
    final newAddress = AddressModel(
      id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
      partnerId: 42,
      title: title,
      street: street,
      city: city,
      stateOrProvince: stateOrProvince,
      postalCode: postalCode,
      reference: reference,
      phone: phone,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
    addresses = [newAddress, ...addresses];
    return newAddress;
  }

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
  }) async {
    final updated = AddressModel(
      id: id,
      partnerId: 42,
      title: title,
      street: street,
      city: city,
      stateOrProvince: stateOrProvince,
      postalCode: postalCode,
      reference: reference,
      phone: phone,
      isDefault: isDefault,
    );
    addresses = addresses.map((a) => a.id == id ? updated : a).toList();
    return updated;
  }

  @override
  Future<bool> deleteAddress(String id) async {
    addresses = addresses.where((a) => a.id != id).toList();
    return true;
  }

  @override
  Future<AddressModel> setDefaultAddress(String id) async {
    addresses = addresses.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    return addresses.firstWhere((a) => a.id == id);
  }
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
  }) async =>
      {
        'clientSecret': 'pi_test_secret_123',
        'paymentIntentId': 'pi_test_123456789',
        'customerId': 'cus_test_123',
        'ephemeralKeySecret': 'ek_test_secret_123',
        'publishableKey': 'pk_test_mock',
      };
}

class MockAuthRepo implements IAuthRepository {
  final User? user;
  MockAuthRepo({this.user});

  @override
  Future<User> login(String username, String password) async =>
      user ?? const User(uid: 1, name: 'Juan Perez', username: 'juan@test.com', partnerId: 42);

  @override
  Future<User> register(String name, String email, String password, {String? phone}) async =>
      const User(uid: 1, name: 'Juan Perez', username: 'juan@test.com', partnerId: 42);

  @override
  Future<User?> getSavedUser() async => user;

  @override
  Future<void> logout() async {}
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
  String? lastPaymentMethodId;
  String? lastPaymentReference;
  String? lastShippingAddressId;
  String? lastShippingAddressText;

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
    lastPaymentMethodId = paymentMethodId;
    lastPaymentReference = paymentReference;
    lastShippingAddressId = shippingAddressId;
    lastShippingAddressText = shippingAddressText;
    return Order(
      id: 701,
      customerId: customerId,
      customerName: customerName ?? 'Juan Perez',
      orderDate: DateTime.now(),
      status: 'confirmed',
      totalAmount: 115.0,
      itemsCount: 1,
    );
  }

  @override
  Future<List<Order>> getOrdersByCustomer(int customerId) async => [];

  @override
  Future<Order> getOrderById(int orderId) async => throw UnimplementedError();
}

void main() {
  const testAddress1 = AddressModel(
    id: 'addr-1',
    partnerId: 42,
    title: 'Casa',
    street: 'Av. Amazonas N24-196',
    city: 'Quito',
    stateOrProvince: 'Pichincha',
    reference: 'Frente al parque',
    phone: '0991234567',
    isDefault: true,
  );

  const testAddress2 = AddressModel(
    id: 'addr-2',
    partnerId: 42,
    title: 'Oficina',
    street: 'Av. 9 de Octubre 100',
    city: 'Guayaquil',
    stateOrProvince: 'Guayas',
    reference: 'Edificio Torre Azul piso 5',
    phone: '0987654321',
    isDefault: false,
  );

  const testCard = PaymentMethodModel(
    id: 'card-1',
    partnerId: 42,
    cardHolderName: 'JUAN PEREZ',
    maskedCardNumber: '**** **** **** 4242',
    cardType: 'Visa',
    expiryDate: '12/28',
    isDefault: true,
  );

  const testProduct = Product(
    id: 1,
    name: 'Teclado Gamer',
    description: 'Teclado mecánico RGB',
    price: 100.0,
    stock: 10,
  );

  group('AddressModel Unit Tests', () {
    test('serialization and summaries', () {
      final json = {
        'id': 'uuid-1',
        'partnerId': 10,
        'title': 'Casa',
        'street': 'Av. Principal 123',
        'city': 'Quito',
        'stateOrProvince': 'Pichincha',
        'reference': 'Portón blanco',
        'phone': '0991234567',
        'isDefault': true,
      };

      final model = AddressModel.fromJson(json);
      expect(model.id, 'uuid-1');
      expect(model.title, 'Casa');
      expect(model.isDefault, true);
      expect(model.shortSummary, 'Av. Principal 123, Quito');
      expect(model.fullSummary, contains('Ref: Portón blanco'));
    });
  });

  group('AddressProvider Unit Tests', () {
    test('loadAddresses selects default address automatically', () async {
      final service = MockAddressService([testAddress2, testAddress1]);
      final provider = AddressProvider(service);

      await provider.loadAddresses();

      expect(provider.addresses.length, 2);
      expect(provider.selectedAddress?.id, 'addr-1');
      expect(provider.selectedAddress?.title, 'Casa');
    });

    test('createAddress adds and selects address', () async {
      final service = MockAddressService([]);
      final provider = AddressProvider(service);

      final created = await provider.createAddress(
        title: 'Departamento',
        street: 'Calle 50 y 10',
        city: 'Guayaquil',
        phone: '0981112233',
        isDefault: true,
      );

      expect(created, isNotNull);
      expect(provider.addresses.length, 1);
      expect(provider.selectedAddress?.title, 'Departamento');
    });

    test('deleteAddress selects fallback when deleting active address', () async {
      final service = MockAddressService([testAddress1, testAddress2]);
      final provider = AddressProvider(service);
      await provider.loadAddresses();

      expect(provider.selectedAddress?.id, 'addr-1');
      await provider.deleteAddress('addr-1');

      expect(provider.addresses.length, 1);
      expect(provider.selectedAddress?.id, 'addr-2');
    });
  });

  group('AddressListScreen Widget Tests', () {
    testWidgets('Muestra lista de direcciones con chip Predeterminada y botón flotante', (tester) async {
      final authRepo = MockAuthRepo(
        user: const User(uid: 1, name: 'Juan', username: 'juan@test.com', partnerId: 42),
      );
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      authProvider.login('juan@test.com', '123456');

      final addressService = MockAddressService([testAddress1, testAddress2]);
      final addressProvider = AddressProvider(addressService);
      await addressProvider.loadAddresses();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: addressProvider),
          ],
          child: const MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mis Direcciones'), findsOneWidget);
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Oficina'), findsOneWidget);
      expect(find.text('Predeterminada'), findsOneWidget);
      expect(find.text('Nueva Dirección'), findsOneWidget);
    });
  });

  group('CartScreen Address Integration Widget Tests', () {
    testWidgets('Muestra tarjeta de agregar dirección si usuario no tiene ninguna y deshabilita confirmar', (tester) async {
      final authRepo = MockAuthRepo(
        user: const User(uid: 1, name: 'Juan', username: 'juan@test.com', partnerId: 42),
      );
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      authProvider.login('juan@test.com', '123456');

      final cartRepo = MockCartRepo(const Cart(items: [
        CartItem(product: testProduct, quantity: 1, unitPrice: 100.0),
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

      // Tiene tarjeta pero NO tiene direcciones
      final paymentService = MockPaymentService([testCard]);
      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

      final addressService = MockAddressService([]);
      final addressProvider = AddressProvider(addressService);
      await addressProvider.loadAddresses();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: cartProvider),
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: paymentProvider),
            ChangeNotifierProvider.value(value: addressProvider),
          ],
          child: MaterialApp(
            routes: {
              AppRoutes.orderSuccess: (_) => const Scaffold(body: Text('Order Success Screen')),
            },
            home: const CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar advertencia de dirección faltante y botón para agregarla
      expect(find.text('No tienes una dirección de entrega configurada'), findsOneWidget);
      expect(find.text('Agregar Dirección de Entrega'), findsOneWidget);
      expect(find.text('Selecciona o agrega una dirección de entrega para continuar.'), findsOneWidget);

      // El botón de Confirmar Pedido debe estar deshabilitado
      final btn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Confirmar Pedido'));
      expect(btn.onPressed, isNull);
    });

    testWidgets('Muestra dirección seleccionada con botón Cambiar y permite confirmar pedido', (tester) async {
      final authRepo = MockAuthRepo(
        user: const User(uid: 1, name: 'Juan', username: 'juan@test.com', partnerId: 42),
      );
      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      authProvider.login('juan@test.com', '123456');

      final cartRepo = MockCartRepo(const Cart(items: [
        CartItem(product: testProduct, quantity: 1, unitPrice: 100.0),
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

      // Tarjeta y Dirección listas
      final paymentService = MockPaymentService([testCard]);
      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

      final addressService = MockAddressService([testAddress1]);
      final addressProvider = AddressProvider(addressService);
      await addressProvider.loadAddresses();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: cartProvider),
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: paymentProvider),
            ChangeNotifierProvider.value(value: addressProvider),
          ],
          child: MaterialApp(
            routes: {
              AppRoutes.orderSuccess: (_) => const Scaffold(body: Text('Order Success Screen')),
            },
            home: const CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar dirección seleccionada y botón Cambiar
      expect(find.text('Dirección de Entrega'), findsOneWidget);
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Av. Amazonas N24-196'), findsOneWidget);

      // Confirmar Pedido habilitado
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirmar Pedido');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verificar que la orden se creó con los datos de pago y dirección
      expect(orderRepo.lastPaymentReference, contains('Stripe'));
      expect(orderRepo.lastShippingAddressId, 'addr-1');
      expect(orderRepo.lastShippingAddressText, contains('Av. Amazonas N24-196'));
    });
  });

  group('AddEditAddressModal Validations & Formatters Tests', () {
    testWidgets('Sin chips de alias y validaciones de Teléfono, Alias, Calle y estado del Botón', (tester) async {
      final addressService = MockAddressService([]);
      final addressProvider = AddressProvider(addressService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: addressProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddEditAddressModal(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que NO existe la sección de chips
      expect(find.text('Identifica este lugar:'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'Casa'), findsNothing);

      // Inicialmente la calle, ciudad y teléfono están vacíos -> botón deshabilitado
      final saveBtnFinder = find.widgetWithText(ElevatedButton, 'Guardar Dirección');
      expect(saveBtnFinder, findsOneWidget);
      var btn = tester.widget<ElevatedButton>(saveBtnFinder);
      expect(btn.onPressed, isNull);

      // Ingresar alias
      final titleField = find.widgetWithText(TextFormField, 'Nombre o Alias de la Dirección *');
      await tester.enterText(titleField, 'Casa');

      // Ingresar calle
      final streetField = find.widgetWithText(TextFormField, 'Calle Principal y Número / Intersección *');
      await tester.enterText(streetField, 'Av. 10 de Agosto N20-50');

      // Ingresar ciudad
      final cityField = find.widgetWithText(TextFormField, 'Ciudad *');
      await tester.enterText(cityField, 'Quito');

      // Ingresar teléfono inválido (ej. no empieza con 09 o tiene menos de 10)
      final phoneField = find.widgetWithText(TextFormField, 'Teléfono para el Repartidor *');
      await tester.enterText(phoneField, '0812345678');
      await tester.pumpAndSettle();

      // Sigue deshabilitado porque no empieza con 09
      btn = tester.widget<ElevatedButton>(saveBtnFinder);
      expect(btn.onPressed, isNull);
      expect(find.text('Debe empezar con 09 y tener 10 dígitos exactos'), findsOneWidget);

      // Ingresar teléfono correcto (09 y 10 dígitos)
      await tester.enterText(phoneField, '0991234567');
      await tester.pumpAndSettle();

      // Ahora el botón debe estar habilitado
      btn = tester.widget<ElevatedButton>(saveBtnFinder);
      expect(btn.onPressed, isNotNull);

      // Probar calle iniciando con caracter especial
      await tester.enterText(streetField, '#Av. 10 de Agosto');
      await tester.pumpAndSettle();
      btn = tester.widget<ElevatedButton>(saveBtnFinder);
      expect(btn.onPressed, isNull);
      expect(find.text('No debe iniciar con caracteres especiales'), findsOneWidget);

      // Probar calle terminando con caracter especial
      await tester.enterText(streetField, 'Av. 10 de Agosto -');
      await tester.pumpAndSettle();
      btn = tester.widget<ElevatedButton>(saveBtnFinder);
      expect(btn.onPressed, isNull);
      expect(find.text('No debe terminar con caracteres especiales'), findsOneWidget);

      // Restaurar calle válida
      await tester.enterText(streetField, 'Av. 10 de Agosto N20-50');
      await tester.pumpAndSettle();
      btn = tester.widget<ElevatedButton>(saveBtnFinder);
      expect(btn.onPressed, isNotNull);

      // Probar Title Case y bloqueo de espacios iniciales en alias
      await tester.enterText(titleField, '  mi departamento nuevo');
      await tester.pumpAndSettle();
      expect(find.text('Mi Departamento Nuevo'), findsOneWidget);

      // Probar Title Case y bloqueo de espacio inicial en ciudad
      await tester.enterText(cityField, '  quito norte');
      await tester.pumpAndSettle();
      expect(find.text('Quito Norte'), findsOneWidget);

      // Verificar textCapitalization en los campos internos (TextField)
      final titleTextField = tester.widget<TextField>(
        find.descendant(of: titleField, matching: find.byType(TextField)),
      );
      expect(titleTextField.textCapitalization, TextCapitalization.words);

      final streetTextField = tester.widget<TextField>(
        find.descendant(of: streetField, matching: find.byType(TextField)),
      );
      expect(streetTextField.textCapitalization, TextCapitalization.words);

      final cityTextField = tester.widget<TextField>(
        find.descendant(of: cityField, matching: find.byType(TextField)),
      );
      expect(cityTextField.textCapitalization, TextCapitalization.words);
    });
  });
}
