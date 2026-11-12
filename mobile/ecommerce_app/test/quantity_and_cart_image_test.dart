import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_app/core/utils/quantity_input_formatter.dart';
import 'package:ecommerce_app/domain/entities/cart_item.dart';
import 'package:ecommerce_app/domain/entities/product.dart';

void main() {
  group('QuantityInputFormatter Tests', () {
    test('Bloquea la entrada de cero inicial', () {
      final formatter = QuantityInputFormatter(maxStock: 20);

      // Usuario intenta teclear '0'
      final resultZero = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '0'),
      );
      expect(resultZero.text, '');

      // Usuario intenta teclear '05'
      final resultLeadingZero = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '05'),
      );
      expect(resultLeadingZero.text, '5');
    });

    test('Limita automáticamente al stock disponible cuando el número excede', () {
      final formatter = QuantityInputFormatter(maxStock: 20);

      final resultExceeded = formatter.formatEditUpdate(
        const TextEditingValue(text: '2'),
        const TextEditingValue(text: '999'),
      );
      expect(resultExceeded.text, '20');
    });

    test('Permite valores válidos dentro del stock', () {
      final formatter = QuantityInputFormatter(maxStock: 50);

      final resultValid = formatter.formatEditUpdate(
        const TextEditingValue(text: '1'),
        const TextEditingValue(text: '15'),
      );
      expect(resultValid.text, '15');
    });
  });

  group('CartItem Image Tests', () {
    test('CartItem almacena y expone imageBase64 correctamente', () {
      const dummyBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
      const product = Product(
        id: 1,
        name: 'Producto Prueba',
        price: 100.0,
        stock: 10,
        imageUrl: dummyBase64,
      );

      const cartItem = CartItem(
        product: product,
        quantity: 2,
        unitPrice: 100.0,
        imageBase64: dummyBase64,
      );

      expect(cartItem.imageBase64, dummyBase64);
      expect(cartItem.image, dummyBase64);

      // Verificación de sanitización con espacios en blanco
      final withSpaces = ' $dummyBase64 \n ';
      final clean = withSpaces.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64Decode(clean);
      expect(bytes.isNotEmpty, true);
    });
  });
}
