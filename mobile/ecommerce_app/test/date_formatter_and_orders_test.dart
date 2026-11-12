import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/utils/date_formatter.dart';
import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/order_item.dart';
import 'package:ecommerce_app/domain/entities/user.dart';
import 'package:ecommerce_app/infrastructure/mappers/order_mapper.dart';
import 'package:ecommerce_app/infrastructure/models/order_model.dart';
import 'package:ecommerce_app/presentation/providers/auth_provider.dart';
import 'package:ecommerce_app/presentation/providers/order_provider.dart';
import 'package:ecommerce_app/presentation/screens/orders/order_history_screen.dart';
import 'package:ecommerce_app/application/use_cases/orders/create_order_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_orders_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/login_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/register_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/get_saved_user_use_case.dart';
import 'package:ecommerce_app/application/use_cases/auth/logout_use_case.dart';
import 'package:ecommerce_app/domain/repositories/i_order_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_auth_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_cart_repository.dart';

class FakeOrderRepository implements IOrderRepository {
  final List<Order> _orders;
  FakeOrderRepository(this._orders);

  @override
  Future<Order> createOrder({
    required int customerId,
    required Cart cart,
    String? customerName,
    String? customerEmail,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Order>> getOrdersByCustomer(int customerId) async => _orders;
}

class FakeAuthRepository implements IAuthRepository {
  final User? user;
  FakeAuthRepository(this.user);

  @override
  Future<User> login(String username, String password) async => user!;

  @override
  Future<User> register(String name, String email, String password, {String? phone}) async => user!;

  @override
  Future<User?> getSavedUser() async => user;

  @override
  Future<void> logout() async {}
}

class FakeCartRepository implements ICartRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DateFormatter Tests', () {
    test('Parsea y formatea strings ISO 8601 UTC de forma segura', () {
      const isoUtc = '2026-11-03T14:30:00Z';
      final dt = DateFormatter.parseSafe(isoUtc);
      expect(dt.isUtc, isTrue);

      final formatted = DateFormatter.format(dt);
      expect(formatted.isNotEmpty, isTrue);
      expect(formatted, contains('/'));
      expect(formatted, contains(':'));
    });

    test('Parsea de forma segura formato Odoo (YYYY-MM-DD HH:mm:ss)', () {
      const odooDate = '2026-11-03 14:30:00';
      final dt = DateFormatter.parseSafe(odooDate);
      expect(dt.year, 2026);
      expect(dt.month, 11);
      expect(dt.day, 3);
      expect(dt.hour, 14);
      expect(dt.minute, 30);

      final formatted = DateFormatter.format(dt);
      expect(formatted, '03/11/2026 14:30');
    });

    test('Manejo seguro ante null o strings corruptos', () {
      expect(DateFormatter.format(null), '');
      final safeDt = DateFormatter.parseSafe('fecha-invalida-xyz');
      expect(safeDt, isA<DateTime>());
      expect(DateFormatter.format(safeDt).isNotEmpty, isTrue);
    });

    test('OrderMapper convierte OrderModel con fecha UTC a entidad Order sin errores', () {
      const model = OrderModel(
        id: 101,
        odooOrderId: 55,
        customerId: 1,
        customerName: 'Cliente Test',
        orderDate: '2026-11-03T18:45:00.000Z',
        status: 'draft',
        statusName: 'Borrador',
        totalAmount: 115.0,
      );

      final entity = OrderMapper.toEntity(model);
      expect(entity.id, 101);
      expect(entity.orderDate.isUtc, isTrue);
      expect(entity.displayStatus, 'Borrador');
      expect(DateFormatter.format(entity.orderDate).isNotEmpty, isTrue);
    });
  });

  group('OrderHistoryScreen Widget Tests', () {
    testWidgets('Renderiza lista de órdenes sin lanzar LocaleDataException', (tester) async {
      await initializeDateFormatting('es_ES', null);

      final sampleOrder = Order(
        id: 1234,
        odooOrderId: 456,
        customerId: 1,
        customerName: 'Test User',
        orderDate: DateTime(2026, 11, 3, 15, 45),
        status: 'confirmado',
        totalAmount: 99.99,
        items: [
          const OrderItem(
            id: 1,
            productId: 1,
            productName: 'Producto de Prueba',
            quantity: 2,
            unitPrice: 49.995,
            subtotal: 99.99,
          ),
        ],
      );

      const fakeUser = User(
        uid: 1,
        name: 'Test User',
        username: 'test@example.com',
        partnerId: 1,
      );

      final orderRepo = FakeOrderRepository([sampleOrder]);
      final authRepo = FakeAuthRepository(fakeUser);
      final cartRepo = FakeCartRepository();

      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      await authProvider.checkSavedSession();

      final orderProvider = OrderProvider(
        CreateOrderUseCase(orderRepo, cartRepo),
        GetOrdersUseCase(orderRepo),
      );

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

      // Esperar a que se procese el frame y el postFrameCallback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que se renderizó el pedido
      expect(find.text('Mis Pedidos'), findsOneWidget);
      expect(find.text('Pedido #1234'), findsOneWidget);
      expect(find.text('03/11/2026 15:45'), findsOneWidget);
      expect(find.text('1 producto(s)'), findsOneWidget);
    });
  });
}
