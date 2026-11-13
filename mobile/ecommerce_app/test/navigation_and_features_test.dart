import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/category.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/order_item.dart';
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

import 'package:ecommerce_app/infrastructure/models/order_model.dart';
import 'package:ecommerce_app/infrastructure/models/order_item_model.dart';

import 'package:ecommerce_app/presentation/providers/auth_provider.dart';
import 'package:ecommerce_app/presentation/providers/cart_provider.dart';
import 'package:ecommerce_app/presentation/providers/order_provider.dart';
import 'package:ecommerce_app/presentation/providers/product_provider.dart';
import 'package:ecommerce_app/presentation/screens/main_navigation_screen.dart';
import 'package:ecommerce_app/presentation/screens/orders/order_detail_screen.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';

// Fakes
class FakeProductRepo implements IProductRepository {
  final List<Product> products;
  final List<Category> categories;

  FakeProductRepo({this.products = const [], this.categories = const []});

  @override
  Future<List<Product>> getProducts({int? categoryId}) async {
    if (categoryId != null) {
      return products.where((p) => p.categoryId == categoryId).toList();
    }
    return products;
  }

  @override
  Future<Product> getProductById(int id) async {
    return products.firstWhere((p) => p.id == id);
  }

  @override
  Future<List<Category>> getCategories() async => categories;
}

class FakeOrderRepo implements IOrderRepository {
  final List<Order> orders;
  FakeOrderRepo(this.orders);

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
  Future<List<Order>> getOrdersByCustomer(int customerId) async => orders;

  @override
  Future<Order> getOrderById(int orderId) async =>
      orders.firstWhere((o) => o.id == orderId, orElse: () => throw Exception('Order not found'));
}

class FakeAuthRepo implements IAuthRepository {
  final User? user;
  FakeAuthRepo(this.user);

  @override
  Future<User> login(String username, String password) async => user!;
  @override
  Future<User> register(String name, String email, String password, {String? phone}) async => user!;
  @override
  Future<User?> getSavedUser() async => user;
  @override
  Future<void> logout() async {}
}

class FakeCartRepo implements ICartRepository {
  @override
  Future<Cart> getCart() async => const Cart();
  @override
  Future<void> saveCart(Cart cart) async {}
  @override
  Future<void> clearCart() async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES', null);
    await initializeDateFormatting('es', null);
  });

  const p1 = Product(id: 1, name: 'Zapatos Deportivos', description: 'Calzado para correr', price: 50.0, stock: 10, categoryId: 1);
  const p2 = Product(id: 2, name: 'Camiseta de Algodón', description: 'Ropa casual suave', price: 20.0, stock: 15, categoryId: 1);
  const p3 = Product(id: 3, name: 'Auriculares Bluetooth', description: 'Audio alta definición', price: 80.0, stock: 5, categoryId: 2);

  group('ProductProvider Filter & Search Tests', () {
    test('Búsqueda por nombre y descripción en tiempo real', () async {
      final repo = FakeProductRepo(products: [p1, p2, p3]);
      final provider = ProductProvider(
        GetProductsUseCase(repo),
        GetProductByIdUseCase(repo),
        GetCategoriesUseCase(repo),
      );

      await provider.loadProducts();
      expect(provider.products.length, 3);

      // Buscar por nombre
      provider.setSearchQuery('Zapatos');
      expect(provider.products.length, 1);
      expect(provider.products.first.name, 'Zapatos Deportivos');

      // Buscar por descripción
      provider.setSearchQuery('casual');
      expect(provider.products.length, 1);
      expect(provider.products.first.name, 'Camiseta de Algodón');

      // Limpiar búsqueda
      provider.clearSearch();
      expect(provider.products.length, 3);
    });

    test('Filtrado por rango de precios', () async {
      final repo = FakeProductRepo(products: [p1, p2, p3]);
      final provider = ProductProvider(
        GetProductsUseCase(repo),
        GetProductByIdUseCase(repo),
        GetCategoriesUseCase(repo),
      );

      await provider.loadProducts();

      // Filtrar entre $25 y $60
      provider.setPriceRange(25.0, 60.0);
      expect(provider.products.length, 1);
      expect(provider.products.first.name, 'Zapatos Deportivos');

      // Resetear rango
      provider.resetPriceRange();
      expect(provider.products.length, 3);
    });

    test('Ordenación alfabética y por precio', () async {
      final repo = FakeProductRepo(products: [p1, p2, p3]);
      final provider = ProductProvider(
        GetProductsUseCase(repo),
        GetProductByIdUseCase(repo),
        GetCategoriesUseCase(repo),
      );

      await provider.loadProducts();

      // Alfabético A-Z
      provider.setSortOption(ProductSortOption.nameAsc);
      expect(provider.products.map((p) => p.name).toList(), [
        'Auriculares Bluetooth',
        'Camiseta de Algodón',
        'Zapatos Deportivos',
      ]);

      // Alfabético Z-A
      provider.setSortOption(ProductSortOption.nameDesc);
      expect(provider.products.map((p) => p.name).toList(), [
        'Zapatos Deportivos',
        'Camiseta de Algodón',
        'Auriculares Bluetooth',
      ]);

      // Precio: Menor a Mayor
      provider.setSortOption(ProductSortOption.priceAsc);
      expect(provider.products.map((p) => p.price).toList(), [20.0, 50.0, 80.0]);

      // Precio: Mayor a Menor
      provider.setSortOption(ProductSortOption.priceDesc);
      expect(provider.products.map((p) => p.price).toList(), [80.0, 50.0, 20.0]);
    });
  });

  group('OrderItemModel & OrderModel Parsing Tests', () {
    test('Parsea correctamente tupla Many2One de Odoo product_id: [id, "Nombre"] y campos Odoo', () {
      final odooJson = {
        'id': 15,
        'product_id': [42, 'ASUS ROG Zephyrus G14'],
        'product_uom_qty': 2.0,
        'price_unit': 1450.0,
        'price_subtotal': 2900.0,
      };

      final item = OrderItemModel.fromJson(odooJson);
      expect(item.id, 15);
      expect(item.productId, 42);
      expect(item.productName, 'ASUS ROG Zephyrus G14');
      expect(item.quantity, 2.0);
      expect(item.unitPrice, 1450.0);
      expect(item.subtotal, 2900.0);
    });

    test('Parsea correctamente OrderModel con partner_id: [id, "Nombre"] y order_line', () {
      final odooOrderJson = {
        'id': 100,
        'partner_id': [7, 'Carlos Mendoza'],
        'date_order': '2026-11-12 18:00:00',
        'amount_total': 2900.0,
        'state': 'sale',
        'order_line': [
          {
            'id': 15,
            'product_id': [42, 'ASUS ROG Zephyrus G14'],
            'product_uom_qty': 2.0,
            'price_unit': 1450.0,
            'price_subtotal': 2900.0,
          }
        ]
      };

      final orderModel = OrderModel.fromJson(odooOrderJson);
      expect(orderModel.id, 100);
      expect(orderModel.customerId, 7);
      expect(orderModel.customerName, 'Carlos Mendoza');
      expect(orderModel.totalAmount, 2900.0);
      expect(orderModel.items.length, 1);
      expect(orderModel.items.first.productName, 'ASUS ROG Zephyrus G14');
    });
  });

  group('OrderDetailScreen Tests', () {
    final sampleOrder = Order(
      id: 999,
      odooOrderId: 888,
      customerId: 42,
      customerName: 'Juan Pérez',
      orderDate: DateTime(2026, 11, 10, 10, 30),
      status: 'confirmed',
      totalAmount: 115.0, // Subtotal: 100.0, IVA: 15.0
      items: const [
        OrderItem(
          id: 1,
          productId: 1,
          productName: 'Zapatos Deportivos',
          quantity: 2,
          unitPrice: 50.0,
          subtotal: 100.0,
        ),
      ],
    );

    testWidgets('Muestra cabecera, lista de productos y desglose con IVA 15%', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailScreen(order: sampleOrder),
        ),
      );

      // Cabecera
      expect(find.text('Pedido #999'), findsWidgets);
      expect(find.text('Referencia Odoo: #888'), findsOneWidget);
      expect(find.text('Cliente: Juan Pérez'), findsOneWidget);

      // Producto
      expect(find.text('Zapatos Deportivos'), findsOneWidget);
      expect(find.text('x2 uds'), findsOneWidget);
      expect(find.text('${CurrencyFormatter.format(50.0)} c/u'), findsOneWidget);
      expect(find.text('Subtotal'), findsWidgets);

      // Desglose Financiero
      // 115 / 1.15 = 100.00
      expect(find.text(CurrencyFormatter.format(100.0)), findsWidgets);
      // 115 - 100 = 15.00
      expect(find.text(CurrencyFormatter.format(15.0)), findsOneWidget);
      // Total: 115.00
      expect(find.text(CurrencyFormatter.format(115.0)), findsWidgets);
    });
  });

  group('MainNavigationScreen & ProfileScreen Tests', () {
    const fakeUser = User(
      uid: 42,
      name: 'Carlos Mendoza',
      username: 'carlos@test.com',
      partnerId: 42,
    );

    final confirmedOrder = Order(
      id: 101,
      customerId: 42,
      customerName: 'Carlos Mendoza',
      orderDate: DateTime(2026, 11, 1),
      status: 'confirmed',
      totalAmount: 230.0,
      items: const [],
    );

    testWidgets('MainNavigationScreen renderiza las 3 pestañas y permite navegar', (tester) async {
      final productRepo = FakeProductRepo(products: [p1]);
      final authRepo = FakeAuthRepo(fakeUser);
      final orderRepo = FakeOrderRepo([confirmedOrder]);
      final cartRepo = FakeCartRepo();

      final authProvider = AuthProvider(
        LoginUseCase(authRepo),
        RegisterUseCase(authRepo),
        GetSavedUserUseCase(authRepo),
        LogoutUseCase(authRepo),
      );
      await authProvider.checkSavedSession();

      final productProvider = ProductProvider(
        GetProductsUseCase(productRepo),
        GetProductByIdUseCase(productRepo),
        GetCategoriesUseCase(productRepo),
      );

      final orderProvider = OrderProvider(
        CreateOrderUseCase(orderRepo, cartRepo),
        GetOrdersUseCase(orderRepo),
      );

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
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: cartProvider),
          ],
          child: const MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar pestañas de la BottomNavigationBar
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Yo'), findsOneWidget);

      // Tocar pestaña 'Yo' (Perfil)
      await tester.tap(find.text('Yo'));
      await tester.pumpAndSettle();

      // Verificar información del perfil
      expect(find.text('Carlos Mendoza'), findsOneWidget);
      expect(find.text('carlos@test.com'), findsOneWidget);
      expect(find.text('Total Gastado Acumulado'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(230.0)), findsOneWidget);
      expect(find.text('Cerrar Sesión'), findsOneWidget);
    });
  });
}
