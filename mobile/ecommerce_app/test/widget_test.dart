import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/product.dart';

void main() {
  group('Cart & IVA 15% Calculation Tests', () {
    const testProduct1 = Product(
      id: 7,
      name: 'Producto Prueba Integradores 1',
      price: 10.0,
      stock: 50.0,
    );

    const testProduct2 = Product(
      id: 8,
      name: 'Producto Prueba Integradores 2',
      price: 15.0,
      stock: 50.0,
    );

    test('Cálculo exacto de Subtotal, IVA 15% y Total con múltiples productos', () {
      Cart cart = const Cart();

      // Agregar 1 unidad de prod 1 ($10.00) y 2 unidades de prod 2 (2 * $15.00 = $30.00)
      cart = cart.addItem(testProduct1, quantity: 1);
      cart = cart.addItem(testProduct2, quantity: 2);

      // Subtotal esperado: 10.0 + 30.0 = 40.0 USD
      expect(cart.totalItems, 3);
      expect(cart.subtotal, 40.0);

      // IVA 15% esperado: 40.0 * 0.15 = 6.0 USD
      expect(cart.iva15, 6.0);

      // Total con IVA esperado: 46.0 USD (coincide con Paso 9 de la Validación Técnica)
      expect(cart.totalConIva, 46.0);
    });

    test('Vaciado del carrito restablece valores a cero', () {
      Cart cart = const Cart();
      cart = cart.addItem(testProduct1, quantity: 5);
      expect(cart.totalItems, 5);

      cart = cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(cart.totalItems, 0);
      expect(cart.subtotal, 0.0);
      expect(cart.iva15, 0.0);
      expect(cart.totalConIva, 0.0);
    });
  });
}
