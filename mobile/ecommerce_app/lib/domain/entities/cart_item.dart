import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final double unitPrice;
  final String? imageBase64;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.imageBase64,
  });

  /// Imagen del producto en formato Base64 o URL.
  String? get image => imageBase64 ?? product.imageUrl;

  /// Subtotal orientativo calculado en el cliente móvil.
  double get subtotal => quantity * unitPrice;

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? unitPrice,
    String? imageBase64,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}

