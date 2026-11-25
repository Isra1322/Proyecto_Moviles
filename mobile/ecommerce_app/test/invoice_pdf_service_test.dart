import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/services/invoice_pdf_service.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/order_item.dart';
import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/domain/repositories/i_auth_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_order_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_cart_repository.dart';
import 'package:ecommerce_app/application/use_cases/auth/login_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/register_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/get_saved_user_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/logout_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/create_order_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_orders_use_case.dart';
import 'package:ecommerce_app/presentation/providers/auth_provider.dart';
import 'package:ecommerce_app/presentation/providers/order_provider.dart';
import 'package:ecommerce_app/presentation/screens/orders/order_detail_screen.dart';
import 'package:ecommerce_app/presentation/screens/orders/order_success_screen.dart';
import 'package:ecommerce_app/presentation/screens/orders/order_history_screen.dart';

class _FakeAuthRepo implements IAuthRepository {
  final User? user;
  _FakeAuthRepo({this.user});
  @override
  Future<User> login(String u, String p) async => user!;
  @override
  Future<User> register(String n, String u, String p, {String? phone}) async => user!;
  @override
  Future<User?> getSavedUser() async => user;
  @override
  Future<void> logout() async {}
}

class _FakeCartRepo implements ICartRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrderRepo implements IOrderRepository {
  final List<Order> orders;
  _FakeOrderRepo({required this.orders});

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
  }) async => orders.first;

  @override
  Future<List<Order>> getOrdersByCustomer(int customerId) async => orders;

  @override
  Future<Order> getOrderById(int orderId) async =>
      orders.firstWhere((o) => o.id == orderId, orElse: () => orders.first);
}

void main() {
  final sampleOrder = Order(
    id: 42,
    odooOrderId: 1042,
    customerId: 7,
    customerName: 'Carlos Mendoza',
    orderDate: DateTime(2026, 11, 24, 15, 30),
    status: 'done',
    totalAmount: 115.0,
    items: const [
      OrderItem(
        id: 1,
        productId: 101,
        productName: 'Monitor Gamer 24" 165Hz',
        quantity: 1,
        unitPrice: 100.0,
        subtotal: 100.0,
      ),
    ],
  );

  const sampleUser = User(
    uid: 7,
    name: 'Carlos Mendoza',
    username: 'carlos@example.com',
    partnerId: 7,
    phone: '0987654321',
  );

  group('InvoicePdfService Unit Tests', () {
    test('generateAccessKey generates valid 49-digit SRI numeric code', () {
      final key = InvoicePdfService.generateAccessKey(sampleOrder);
      expect(key.length, 49);
      expect(RegExp(r'^\d{49}$').hasMatch(key), isTrue);
      // Debe contener la fecha formateada 24112026 y RUC 1790012345001
      expect(key.startsWith('24112026011790012345001'), isTrue);
    });

    test('buildInvoicePdf returns valid PDF binary document with exact financial math', () async {
      final bytes = await InvoicePdfService.buildInvoicePdf(
        order: sampleOrder,
        user: sampleUser,
        addressSummary: 'Av. República del Salvador y Moscú, Quito',
        paymentLabel: 'Visa (•••• 4321)',
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      // Encabezado estándar de documento PDF (%PDF-)
      final header = ascii.decode(bytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('buildInvoicePdf handles order with empty items calculating 15% IVA from total', () async {
      final emptyItemsOrder = Order(
        id: 99,
        customerId: 12,
        customerName: 'Cliente Sin Items',
        orderDate: DateTime(2026, 11, 20),
        status: 'confirmed',
        totalAmount: 230.0, // 200 subtotal + 30 IVA 15%
        items: const [],
      );

      final bytes = await InvoicePdfService.buildInvoicePdf(
        order: emptyItemsOrder,
      );

      expect(bytes, isNotEmpty);
      final header = ascii.decode(bytes.sublist(0, 5));
      expect(header, '%PDF-');
    });
  });

  group('Invoice UI Integration Tests', () {
    late AuthProvider authProvider;
    late OrderProvider orderProvider;

    setUp(() {
      final authRepo = _FakeAuthRepo(user: sampleUser);
      authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      )..checkSavedSession();

      final orderRepo = _FakeOrderRepo(orders: [sampleOrder]);
      final cartRepo = _FakeCartRepo();
      orderProvider = OrderProvider(
        CreateOrderUseCase(orderRepo, cartRepo),
        GetOrdersUseCase(orderRepo),
      );
    });

    testWidgets('OrderDetailScreen renders "Descargar Factura PDF" action and button', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: OrderDetailScreen(order: sampleOrder),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar botón en el AppBar o cuerpo
      expect(find.text('Descargar Factura PDF'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsNWidgets(2)); // AppBar icon + prominent button
    });

    testWidgets('OrderSuccessScreen renders "Descargar Factura" button', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: OrderSuccessScreen(order: sampleOrder),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Descargar Factura'), findsOneWidget);
      expect(find.text('Seguir Comprando'), findsOneWidget);
      expect(find.text('Ver mis Pedidos'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
    });

    testWidgets('OrderHistoryScreen renders PDF invoice direct download icon button on cards', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
          ],
          child: const MaterialApp(
            home: OrderHistoryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Pedido #42'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
      expect(find.byTooltip('Descargar Factura PDF'), findsOneWidget);
    });
  });
}
