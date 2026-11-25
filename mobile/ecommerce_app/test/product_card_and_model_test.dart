import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/infrastructure/models/product_model.dart';
import 'package:ecommerce_app/application/use_cases/cart/add_to_cart_use_case.dart';
import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/repositories/i_cart_repository.dart';
import 'package:ecommerce_app/presentation/widgets/product/product_card.dart';

class _FakeCartRepo implements ICartRepository {
  Cart cart = const Cart();
  @override
  Future<void> clearCart() async { cart = const Cart(); }
  @override
  Future<Cart> getCart() async => cart;
  @override
  Future<void> saveCart(Cart newCart) async { cart = newCart; }
}

void main() {
  group('ProductModel & Product Entity Description & Stock Tests', () {
    test('ProductModel.fromJson parses description from various field names', () {
      final jsonDesc = {'id': 1, 'name': 'P1', 'description': 'Desc 1', 'price': 100.0, 'stock': 5.0};
      final modelDesc = ProductModel.fromJson(jsonDesc);
      expect(modelDesc.description, 'Desc 1');
      expect(modelDesc.descriptionSale, 'Desc 1');

      final jsonDescUpper = {'id': 2, 'name': 'P2', 'Description': 'Desc Upper', 'price': 50.0, 'stock': 0.0};
      final modelDescUpper = ProductModel.fromJson(jsonDescUpper);
      expect(modelDescUpper.description, 'Desc Upper');
      expect(modelDescUpper.descriptionSale, 'Desc Upper');

      final jsonDescSale = {'id': 3, 'name': 'P3', 'descriptionSale': 'Desc Sale Camels', 'price': 20.0, 'stock': 2.0};
      final modelDescSale = ProductModel.fromJson(jsonDescSale);
      expect(modelDescSale.description, 'Desc Sale Camels');

      final jsonDescSnake = {'id': 4, 'name': 'P4', 'description_sale': 'Desc Sale Snake', 'price': 15.0, 'stock': 1.0};
      final modelDescSnake = ProductModel.fromJson(jsonDescSnake);
      expect(modelDescSnake.description, 'Desc Sale Snake');

      final jsonNull = {'id': 5, 'name': 'P5', 'description': null, 'price': 10.0, 'stock': 0.0};
      final modelNull = ProductModel.fromJson(jsonNull);
      expect(modelNull.description, isNull);

      final jsonBoolFalse = {'id': 6, 'name': 'P6', 'description_sale': false, 'price': 10.0, 'stock': 0.0};
      final modelBool = ProductModel.fromJson(jsonBoolFalse);
      expect(modelBool.description, isNull);
    });

    test('Product entity provides description and descriptionSale', () {
      const product = Product(
        id: 1,
        name: 'Test Product',
        description: 'Breve detalle del producto',
        price: 99.99,
        stock: 12,
      );
      expect(product.description, 'Breve detalle del producto');
      expect(product.descriptionSale, 'Breve detalle del producto');
      expect(product.isInStock, isTrue);
    });
  });

  group('ProductCard Widget Layout and Aesthetics Tests', () {
    const productWithDesc = Product(
      id: 1,
      name: 'Laptop Gamer Ultra Pro 16GB RAM',
      description: 'Procesador Intel i7 13va gen, 1TB SSD NVMe y GPU RTX 4060.',
      price: 1299.99,
      stock: 8,
      imageUrl: '',
    );

    const productOutOfStock = Product(
      id: 2,
      name: 'Teclado Mecanico RGB OutOfStock',
      description: 'Switches Red silenciosos con cable desmontable tipo C.',
      price: 49.50,
      stock: 0,
      imageUrl: '',
    );

    const productNoDesc = Product(
      id: 3,
      name: 'Mouse Inalambrico Basico',
      price: 19.99,
      stock: 15,
      imageUrl: '',
    );

    testWidgets('renders title, description, price and in-stock badge in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: SizedBox(
              width: 180,
              height: 280,
              child: ProductCard(product: productWithDesc),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Título
      final titleFinder = find.text('Laptop Gamer Ultra Pro 16GB RAM');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.maxLines, 1);
      expect(titleWidget.overflow, TextOverflow.ellipsis);
      expect(titleWidget.style?.fontWeight, FontWeight.w600);
      expect(titleWidget.style?.fontSize, 13.5);
      expect(titleWidget.style?.color, Colors.white);

      // 2. Descripción corta
      final descFinder = find.text('Procesador Intel i7 13va gen, 1TB SSD NVMe y GPU RTX 4060.');
      expect(descFinder, findsOneWidget);
      final descWidget = tester.widget<Text>(descFinder);
      expect(descWidget.maxLines, 2);
      expect(descWidget.overflow, TextOverflow.ellipsis);
      expect(descWidget.style?.fontSize, 11.5);
      expect(descWidget.style?.height, 1.2);
      expect(descWidget.style?.color, Colors.grey.shade400);

      // 3. Precio
      final priceFinder = find.text(CurrencyFormatter.format(productWithDesc.price));
      expect(priceFinder, findsOneWidget);
      final priceWidget = tester.widget<Text>(priceFinder);
      expect(priceWidget.style?.color, const Color(0xFF2196F3));
      expect(priceWidget.style?.fontSize, 14);
      expect(priceWidget.style?.fontWeight, FontWeight.bold);

      // 4. Badge stock > 0
      final stockFinder = find.text('8 disp.');
      expect(stockFinder, findsOneWidget);
      final stockWidget = tester.widget<Text>(stockFinder);
      expect(stockWidget.style?.fontSize, 10.5);
      expect(stockWidget.style?.fontWeight, FontWeight.w600);
      expect(stockWidget.style?.color, const Color(0xFF81C784));

      // Container del badge
      final containerFinder = find.ancestor(of: stockFinder, matching: find.byType(Container));
      expect(containerFinder, findsWidgets);
      final containerWidget = tester.widget<Container>(containerFinder.first);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, const Color(0x224CAF50));
      expect(decoration.borderRadius, BorderRadius.circular(6));
    });

    testWidgets('renders light mode colors for title, description and stock badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const Scaffold(
            body: SizedBox(
              width: 180,
              height: 280,
              child: ProductCard(product: productWithDesc),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleWidget = tester.widget<Text>(find.text('Laptop Gamer Ultra Pro 16GB RAM'));
      expect(titleWidget.style?.color, AppColors.textPrimary);

      final descWidget = tester.widget<Text>(find.text('Procesador Intel i7 13va gen, 1TB SSD NVMe y GPU RTX 4060.'));
      expect(descWidget.style?.color, Colors.grey.shade600);

      final stockWidget = tester.widget<Text>(find.text('8 disp.'));
      expect(stockWidget.style?.color, const Color(0xFF2E7D32));
    });

    testWidgets('renders "Agotado" badge with red colors when stock <= 0', (tester) async {
      // Dark mode agotado
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: SizedBox(
              width: 180,
              height: 280,
              child: ProductCard(product: productOutOfStock),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final agotadoFinder = find.text('Agotado');
      expect(agotadoFinder, findsOneWidget);
      final agotadoWidget = tester.widget<Text>(agotadoFinder);
      expect(agotadoWidget.style?.fontSize, 10.5);
      expect(agotadoWidget.style?.fontWeight, FontWeight.w600);
      expect(agotadoWidget.style?.color, const Color(0xFFE57373));

      final containerFinder = find.ancestor(of: agotadoFinder, matching: find.byType(Container));
      final containerWidget = tester.widget<Container>(containerFinder.first);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, const Color(0x22E53935));
      expect(decoration.borderRadius, BorderRadius.circular(6));

      // Light mode agotado
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const Scaffold(
            body: SizedBox(
              width: 180,
              height: 280,
              child: ProductCard(product: productOutOfStock),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final agotadoLightWidget = tester.widget<Text>(find.text('Agotado'));
      expect(agotadoLightWidget.style?.color, const Color(0xFFD32F2F));
    });

    testWidgets('does not render description widget when product.description is null or empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const Scaffold(
            body: SizedBox(
              width: 180,
              height: 280,
              child: ProductCard(product: productNoDesc),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mouse Inalambrico Basico'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(productNoDesc.price)), findsOneWidget);
      expect(find.text('15 disp.'), findsOneWidget);

      // Verify no description text widget exists
      final allTextWidgets = tester.widgetList<Text>(find.byType(Text));
      final hasDescription = allTextWidgets.any((w) => w.data == null && w.textSpan == null);
      expect(hasDescription, isFalse);
    });
  });

  group('Zero Stock Validation Tests', () {
    test('AddToCartUseCase throws StateError when product has stock <= 0', () async {
      final repo = _FakeCartRepo();
      final useCase = AddToCartUseCase(repo);
      const outOfStockProduct = Product(id: 99, name: 'Sin Stock', price: 10, stock: 0);

      expect(() => useCase.execute(outOfStockProduct), throwsA(isA<StateError>()));
    });
  });
}
