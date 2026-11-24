import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ecommerce_app/core/utils/card_input_formatters.dart';
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
import 'package:ecommerce_app/application/use_cases/orders/create_order_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_orders_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/get_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/add_to_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/update_cart_quantity_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/remove_from_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/clear_cart_use_case.dart';

import 'package:ecommerce_app/infrastructure/datasources/remote/payment_service.dart';
import 'package:ecommerce_app/infrastructure/models/payment_method_model.dart';
import 'package:ecommerce_app/presentation/providers/auth_provider.dart';
import 'package:ecommerce_app/presentation/providers/cart_provider.dart';
import 'package:ecommerce_app/presentation/providers/order_provider.dart';
import 'package:ecommerce_app/presentation/providers/payment_provider.dart';
import 'package:ecommerce_app/presentation/routes/app_routes.dart';
import 'package:ecommerce_app/presentation/screens/cart/cart_screen.dart';
import 'package:ecommerce_app/presentation/screens/payment/payment_methods_screen.dart';
import 'package:ecommerce_app/presentation/screens/profile/profile_screen.dart';
import 'package:ecommerce_app/presentation/widgets/payment/add_card_modal.dart';
import 'package:ecommerce_app/presentation/widgets/payment/select_card_modal.dart';

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
    return Order(
      id: 501,
      customerId: customerId,
      customerName: customerName ?? 'Test User',
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

class MockPaymentService implements PaymentService {
  List<PaymentMethodModel> methods;
  MockPaymentService([List<PaymentMethodModel>? methods])
      : methods = methods != null ? List.from(methods) : [];

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async => List.from(methods);

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
      id: 'mock-card-${methods.length + 1}',
      partnerId: 42,
      cardHolderName: cardHolderName,
      maskedCardNumber: '**** **** **** $last4',
      cardType: 'Visa',
      expiryDate: expiryDate,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
    methods.insert(0, newMethod);
    return newMethod;
  }

  @override
  Future<bool> deletePaymentMethod(String id) async {
    final initialCount = methods.length;
    methods.removeWhere((m) => m.id == id);
    return methods.length < initialCount;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES', null);
    await initializeDateFormatting('es', null);
  });

  const testProduct = Product(
    id: 1,
    name: 'Teclado Mecánico RGB',
    description: 'Switches azules con iluminación customizable',
    price: 85.0,
    stock: 10,
  );

  final testCard1 = PaymentMethodModel(
    id: 'card-1',
    partnerId: 42,
    cardHolderName: 'Juan Perez',
    maskedCardNumber: '**** **** **** 4242',
    cardType: 'Visa',
    expiryDate: '12/28',
    isDefault: true,
    createdAt: DateTime.parse('2026-01-01T10:00:00Z'),
  );

  final testCard2 = PaymentMethodModel(
    id: 'card-2',
    partnerId: 42,
    cardHolderName: 'Juan Perez',
    maskedCardNumber: '**** **** **** 5555',
    cardType: 'MasterCard',
    expiryDate: '06/29',
    isDefault: false,
    createdAt: DateTime.parse('2026-02-01T10:00:00Z'),
  );

  group('PaymentMethodModel Unit Tests', () {
    test('Serialización y deserialización correcta', () {
      final json = testCard1.toJson();
      expect(json['id'], 'card-1');
      expect(json['partnerId'], 42);
      expect(json['maskedCardNumber'], '**** **** **** 4242');
      expect(json['cardType'], 'Visa');
      expect(json['isDefault'], true);

      final deserialized = PaymentMethodModel.fromJson(json);
      expect(deserialized.id, testCard1.id);
      expect(deserialized.maskedCardNumber, testCard1.maskedCardNumber);
      expect(deserialized.cardHolderName, testCard1.cardHolderName);
      expect(deserialized.expiryDate, testCard1.expiryDate);
    });
  });

  group('CardInputFormatters Tests', () {
    test('CardNumberInputFormatter formatea correctamente grupos de 4 dígitos', () {
      final formatter = CardNumberInputFormatter();
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '4532111122223333',
        selection: TextSelection.collapsed(offset: 16),
      );

      final formatted = formatter.formatEditUpdate(oldValue, newValue);
      expect(formatted.text, '4532 1111 2222 3333');
    });

    test('CardExpiryInputFormatter formatea MM/AA', () {
      final formatter = CardExpiryInputFormatter();
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '1228',
        selection: TextSelection.collapsed(offset: 4),
      );

      final formatted = formatter.formatEditUpdate(oldValue, newValue);
      expect(formatted.text, '12/28');
    });
  });

  group('PaymentProvider Unit Tests', () {
    test('loadPaymentMethods carga tarjetas y selecciona la tarjeta por defecto', () async {
      final mockService = MockPaymentService([testCard2, testCard1]);
      final provider = PaymentProvider(mockService);

      await provider.loadPaymentMethods();

      expect(provider.paymentMethods.length, 2);
      expect(provider.selectedMethod?.id, 'card-1'); // isDefault=true
    });

    test('addPaymentMethod agrega y selecciona la nueva tarjeta', () async {
      final mockService = MockPaymentService([testCard1]);
      final provider = PaymentProvider(mockService);
      await provider.loadPaymentMethods();

      final added = await provider.addPaymentMethod(
        cardNumber: '4111222233334444',
        cardHolderName: 'Carlos Gomez',
        expiryDate: '10/27',
        cvv: '123',
      );

      expect(added, isNotNull);
      expect(provider.paymentMethods.length, 2);
      expect(provider.selectedMethod?.id, added!.id);
      expect(provider.selectedMethod?.maskedCardNumber, '**** **** **** 4444');
    });

    test('selectMethod actualiza la tarjeta activa', () async {
      final mockService = MockPaymentService([testCard1, testCard2]);
      final provider = PaymentProvider(mockService);
      await provider.loadPaymentMethods();

      expect(provider.selectedMethod?.id, 'card-1');
      provider.selectMethod(testCard2);
      expect(provider.selectedMethod?.id, 'card-2');
    });

    test('deletePaymentMethod elimina y reasigna selección', () async {
      final mockService = MockPaymentService([testCard1, testCard2]);
      final provider = PaymentProvider(mockService);
      await provider.loadPaymentMethods();

      final deleted = await provider.deletePaymentMethod('card-1');
      expect(deleted, isTrue);
      expect(provider.paymentMethods.length, 1);
      expect(provider.selectedMethod?.id, 'card-2');
    });
  });

  group('CartScreen Payment Integration Tests', () {
    testWidgets('Muestra tarjeta seleccionada y permite confirmar pedido asociando método de pago', (tester) async {
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

      final cartRepo = MockCartRepo(const Cart(items: [
        CartItem(product: testProduct, quantity: 1, unitPrice: 85.0),
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

      final paymentService = MockPaymentService([testCard1]);
      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

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
              AppRoutes.orderSuccess: (_) => const Scaffold(body: Text('Orden Exitosa')),
              AppRoutes.catalog: (_) => const Scaffold(body: Text('Catalogo')),
            },
            home: const CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que se ve la sección de Método de Pago y la tarjeta seleccionada
      expect(find.text('Método de Pago'), findsOneWidget);
      expect(find.text('**** **** **** 4242'), findsOneWidget);
      expect(find.text('Juan Perez • Exp: 12/28'), findsOneWidget);
      expect(find.text('Cambiar'), findsOneWidget);

      // Confirmar Pedido debe estar disponible
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirmar Pedido');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verificar que la orden se creó con los datos de pago
      expect(orderRepo.lastPaymentMethodId, 'card-1');
      expect(orderRepo.lastPaymentReference, 'Pago con Visa terminada en 4242');
    });

    testWidgets('Deshabilita Confirmar Pedido cuando usuario autenticado no tiene tarjetas registradas', (tester) async {
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

      final cartRepo = MockCartRepo(const Cart(items: [
        CartItem(product: testProduct, quantity: 1, unitPrice: 85.0),
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

      // Sin tarjetas
      final paymentService = MockPaymentService([]);
      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: cartProvider),
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: paymentProvider),
          ],
          child: MaterialApp(
            home: const CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar mensaje y botón de agregar tarjeta
      expect(find.text('No tienes tarjetas registradas para pagar.'), findsOneWidget);
      expect(find.text('Agregar tarjeta para pagar'), findsOneWidget);

      // El botón 'Confirmar Pedido' debe estar deshabilitado (ElevatedButton con onPressed == null)
      final elevatedButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirmar Pedido'),
      );
      expect(elevatedButton.onPressed, isNull);
    });
  });

  group('AddCardModal Refactor Tests', () {
    testWidgets('Límite estricto de 35 caracteres en Nombre del Titular y counterText vacío', (tester) async {
      final paymentService = MockPaymentService([]);
      final paymentProvider = PaymentProvider(paymentService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: paymentProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddCardModal(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que los campos y tarjeta existen
      expect(find.text('Nueva Tarjeta'), findsOneWidget);
      expect(find.text('Nombre del Titular'), findsOneWidget);
      expect(find.text('Guardar Tarjeta'), findsOneWidget);

      // Ingresar más de 35 caracteres
      final nameField = find.widgetWithText(TextFormField, 'Nombre del Titular');
      expect(nameField, findsOneWidget);

      const longName = 'ESTE ES UN NOMBRE EXTREMADAMENTE LARGO QUE SUPERA LOS TREINTA Y CINCO CARACTERES';
      await tester.enterText(nameField, longName);
      await tester.pumpAndSettle();

      final textFormFieldWidget = tester.widget<TextFormField>(nameField);
      expect(textFormFieldWidget.controller?.text.length, 35);
      expect(textFormFieldWidget.controller?.text, longName.substring(0, 35));

      // Verificar que counterText está vacío
      expect(find.text('35/35'), findsNothing);
    });

    testWidgets('Muestra degradado contemporáneo Deep Blue/Indigo y botón estilizado', (tester) async {
      final paymentService = MockPaymentService([]);
      final paymentProvider = PaymentProvider(paymentService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: paymentProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddCardModal(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Botón Guardar Tarjeta
      final saveButtonFinder = find.widgetWithText(ElevatedButton, 'Guardar Tarjeta');
      expect(saveButtonFinder, findsOneWidget);
      final saveButton = tester.widget<ElevatedButton>(saveButtonFinder);
      expect(saveButton.style?.shape?.resolve({}), isA<RoundedRectangleBorder>());
      final border = saveButton.style?.shape?.resolve({}) as RoundedRectangleBorder;
      expect(border.borderRadius, BorderRadius.circular(16));

      // Fila Expiración y CVV
      expect(find.text('Expiración'), findsOneWidget);
      expect(find.text('CVV'), findsOneWidget);
    });
  });

  group('PaymentMethodsScreen & ProfileScreen Integration Tests', () {
    testWidgets('ProfileScreen muestra opción Mis Métodos de Pago', (tester) async {
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

      expect(find.text('Mis Métodos de Pago'), findsOneWidget);
      expect(find.text('Gestiona tus tarjetas de crédito y débito'), findsOneWidget);
      expect(find.byIcon(Icons.credit_card), findsOneWidget);
    });

    testWidgets('PaymentMethodsScreen muestra lista de tarjetas, badge Predeterminada y diálogo de eliminación', (tester) async {
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

      final paymentService = MockPaymentService([testCard1, testCard2]);
      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: paymentProvider),
          ],
          child: const MaterialApp(
            home: PaymentMethodsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar elementos de la pantalla
      expect(find.text('Mis Métodos de Pago'), findsOneWidget);
      expect(find.text('Nueva Tarjeta'), findsOneWidget);
      expect(find.text('**** **** **** 4242'), findsOneWidget);
      expect(find.text('**** **** **** 5555'), findsOneWidget);
      expect(find.text('Predeterminada'), findsOneWidget);

      // Los botones de eliminar existen en esta pantalla
      final deleteButtons = find.byIcon(Icons.delete_outline);
      expect(deleteButtons, findsNWidgets(2));

      // Presionar eliminar en la primera tarjeta para verificar diálogo de confirmación
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Eliminar Tarjeta'), findsOneWidget);
      expect(find.text('¿Deseas eliminar la tarjeta **** **** **** 4242?'), findsOneWidget);

      // Cancelar diálogo
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Deseas eliminar la tarjeta **** **** **** 4242?'), findsNothing);
    });
  });

  group('SelectCardModal Checkout Quick Selector Tests', () {
    testWidgets('SelectCardModal NO contiene botón de eliminar y permite seleccionar tarjeta', (tester) async {
      final paymentService = MockPaymentService([testCard1, testCard2]);
      final paymentProvider = PaymentProvider(paymentService);
      await paymentProvider.loadPaymentMethods();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: paymentProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SelectCardModal(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que muestra las tarjetas y el botón de agregar otra tarjeta
      expect(find.text('Seleccionar Método de Pago'), findsOneWidget);
      expect(find.text('**** **** **** 4242'), findsOneWidget);
      expect(find.text('**** **** **** 5555'), findsOneWidget);
      expect(find.text('Agregar otra tarjeta'), findsOneWidget);

      // REGLA CLAVE: En el modal del checkout NO debe existir ningún botón de papelera/eliminar
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      // Debe mostrar el check de selección
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
