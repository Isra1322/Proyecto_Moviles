import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/category.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/order_item.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/domain/repositories/i_cart_repository.dart';
import 'package:ecommerce_app/domain/repositories/i_product_repository.dart';
import 'package:ecommerce_app/application/use_cases/cart/add_to_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/clear_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/get_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/remove_from_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/update_cart_quantity_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_categories_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_products_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_product_by_id_use_case.dart';
import 'package:ecommerce_app/infrastructure/models/order_item_model.dart';
import 'package:ecommerce_app/presentation/providers/cart_provider.dart';
import 'package:ecommerce_app/presentation/providers/product_provider.dart';
import 'package:ecommerce_app/presentation/screens/catalog/categories_screen.dart';
import 'package:ecommerce_app/presentation/screens/orders/order_detail_screen.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';

class FakeCartRepo implements ICartRepository {
  Cart cart = const Cart(items: []);
  @override
  Future<Cart> getCart() async => cart;
  @override
  Future<void> saveCart(Cart cart) async => this.cart = cart;
  @override
  Future<void> clearCart() async {}
}

class FakeProductRepo implements IProductRepository {
  final List<Category> categories;
  final List<Product> products;

  FakeProductRepo({required this.categories, required this.products});

  @override
  Future<List<Category>> getCategories() async => categories;

  @override
  Future<List<Product>> getProducts({int? categoryId}) async => products;

  @override
  Future<Product> getProductById(int id) async => products.first;
}

void main() {
  group('CategoriesScreen Icons & Design Tests', () {
    testWidgets('Mapea dinámicamente iconos y muestra tarjeta con avatar e icono centrado y chevron_right', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeCategories = [
        const Category(id: 1, name: 'Laptops Gamer'),
        const Category(id: 2, name: 'Teléfonos Inteligentes'),
        const Category(id: 3, name: 'Audio & Auriculares'),
        const Category(id: 4, name: 'Accesorios'),
        const Category(id: 5, name: 'Monitores 4K'),
        const Category(id: 6, name: 'Componentes PC'),
        const Category(id: 7, name: 'Varios'),
      ];

      final fakeRepo = FakeProductRepo(categories: fakeCategories, products: const []);
      final productProvider = ProductProvider(
        GetProductsUseCase(fakeRepo),
        GetProductByIdUseCase(fakeRepo),
        GetCategoriesUseCase(fakeRepo),
      );

      final cartRepo = FakeCartRepo();
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
            ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ],
          child: const MaterialApp(
            home: CategoriesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica presencia de nombres de categorías
      expect(find.text('Laptops Gamer'), findsOneWidget);
      expect(find.text('Teléfonos Inteligentes'), findsOneWidget);
      expect(find.text('Audio & Auriculares'), findsOneWidget);
      expect(find.text('Accesorios'), findsOneWidget);
      expect(find.text('Monitores 4K'), findsOneWidget);
      expect(find.text('Componentes PC'), findsOneWidget);
      expect(find.text('Varios'), findsOneWidget);

      // Verifica que cada tarjeta de categoría tiene la flecha indicadora chevron_right
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(8)); // 1 de "Todas" + 7 categorías

      // Verifica los iconos dinámicos
      expect(find.byIcon(Icons.laptop_mac_rounded), findsOneWidget);
      expect(find.byIcon(Icons.smartphone_rounded), findsOneWidget);
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);
      expect(find.byIcon(Icons.devices_other_rounded), findsOneWidget);
      expect(find.byIcon(Icons.monitor_rounded), findsOneWidget);
      expect(find.byIcon(Icons.memory_rounded), findsOneWidget);
      expect(find.byIcon(Icons.category_rounded), findsWidgets);
    });
  });

  group('OrderDetailScreen Comprobante / Recibo Tests', () {
    test('OrderItemModel extrae product_id[1] y product_uom_qty sin quedar en 0 ni vacíos', () {
      final jsonOdoo = {
        'id': 101,
        'product_id': [42, 'MacBook Pro M3 Max'],
        'product_uom_qty': 3.0,
        'price_unit': 2499.0,
        'price_subtotal': 7497.0,
      };

      final item = OrderItemModel.fromJson(jsonOdoo);
      expect(item.productId, 42);
      expect(item.productName, 'MacBook Pro M3 Max');
      expect(item.quantity, 3.0);
      expect(item.unitPrice, 2499.0);
      expect(item.subtotal, 7497.0);

      // Caso cuando quantity viene en 0 pero se deriva o no queda en 0
      final jsonZeroQty = {
        'id': 102,
        'name': 'Mouse Inalámbrico',
        'quantity': 0,
        'price_unit': 25.0,
        'price_subtotal': 50.0,
      };
      final itemZero = OrderItemModel.fromJson(jsonZeroQty);
      expect(itemZero.productName, 'Mouse Inalámbrico');
      expect(itemZero.quantity, 2.0); // 50 / 25 = 2.0

      // Caso cuando viene formato API estándar con productName, quantity, unitPrice, subtotal
      final jsonApi = {
        'id': 103,
        'productId': 15,
        'productName': 'Teclado Mecánico RGB',
        'quantity': 2.0,
        'unitPrice': 75.50,
        'subtotal': 151.00,
      };
      final itemApi = OrderItemModel.fromJson(jsonApi);
      expect(itemApi.productName, 'Teclado Mecánico RGB');
      expect(itemApi.quantity, 2.0);
      expect(itemApi.unitPrice, 75.50);
      expect(itemApi.subtotal, 151.00);

      // Caso con alias name y price
      final jsonAlias = {
        'id': 104,
        'name': 'Auriculares Bluetooth',
        'quantity': 1.0,
        'price': 40.0,
        'subtotal': 40.0,
      };
      final itemAlias = OrderItemModel.fromJson(jsonAlias);
      expect(itemAlias.productName, 'Auriculares Bluetooth');
      expect(itemAlias.quantity, 1.0);
      expect(itemAlias.unitPrice, 40.0);
      expect(itemAlias.subtotal, 40.0);
    });

    testWidgets('Muestra comprobante estilo ticket con encabezado, items [Cantidad] x \\\$[Precio], divisorias y resumen', (tester) async {
      final sampleOrder = Order(
        id: 26,
        odooOrderId: 104,
        customerId: 7,
        customerName: 'Sebastián Andrade',
        orderDate: DateTime(2026, 11, 13, 11, 00),
        status: 'confirmed',
        totalAmount: 115.0,
        items: const [
          OrderItem(
            id: 1,
            productId: 10,
            productName: 'Monitor Dell 27"',
            quantity: 2,
            unitPrice: 50.0,
            subtotal: 100.0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailScreen(order: sampleOrder),
        ),
      );
      await tester.pumpAndSettle();

      // Encabezado
      expect(find.text('E-Commerce Móvil'), findsOneWidget);
      expect(find.text('Comprobante de Pedido'), findsOneWidget);
      expect(find.text('Pedido #26'), findsWidgets);
      expect(find.text('Referencia Odoo: #104'), findsOneWidget);
      expect(find.text('Cliente: Sebastián Andrade'), findsOneWidget);

      // Sello de estado
      expect(find.text('CONFIRMADO'), findsOneWidget);

      // Líneas divisorias punteadas
      expect(find.byType(DottedDivider), findsNWidgets(2));

      // Detalle de producto
      expect(find.text('Monitor Dell 27"'), findsOneWidget);
      expect(find.text('2 x \$50.00'), findsOneWidget);
      expect(find.text('x2 uds'), findsOneWidget);
      expect(find.text('${CurrencyFormatter.format(50.0)} c/u'), findsOneWidget);
      expect(find.text('\$100.00'), findsOneWidget);

      // Resumen Financiero
      expect(find.text('Subtotal (sin impuestos)'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(100.0)), findsWidgets);
      expect(find.text('IVA (15%)'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(15.0)), findsOneWidget);
      expect(find.text('Total Pagado'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(115.0)), findsWidgets);
    });
  });
}
