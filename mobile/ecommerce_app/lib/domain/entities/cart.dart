import 'cart_item.dart';
import 'product.dart';

class Cart {
  final List<CartItem> items;

  const Cart({this.items = const []});

  /// Cantidad total de artículos en el carrito
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Subtotal neto sin impuestos
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Subtotal orientativo (compatibilidad)
  double get subtotalOrientativo => subtotal;

  /// Impuesto al Valor Agregado oficial (Ecuador IVA 15%)
  double get iva15 => subtotal * 0.15;

  /// Total general con IVA incluido
  double get totalConIva => subtotal + iva15;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  Cart copyWith({List<CartItem>? items}) {
    return Cart(items: items ?? this.items);
  }

  /// Añade un producto o incrementa la cantidad si ya existe.
  Cart addItem(Product product, {int quantity = 1}) {
    final existingIndex = items.indexWhere((i) => i.product.id == product.id);
    final updatedList = List<CartItem>.from(items);

    if (existingIndex >= 0) {
      final existing = items[existingIndex];
      updatedList[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      updatedList.add(
        CartItem(
          product: product,
          quantity: quantity,
          unitPrice: product.price,
          imageBase64: product.imageUrl,
        ),
      );
    }

    return Cart(items: updatedList);
  }

  /// Modifica la cantidad de un producto. Si la cantidad es <= 0, lo elimina.
  Cart updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      return removeItem(productId);
    }

    final updatedList = items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    return Cart(items: updatedList);
  }

  /// Elimina un producto del carrito.
  Cart removeItem(int productId) {
    final updatedList = items.where((i) => i.product.id != productId).toList();
    return Cart(items: updatedList);
  }

  /// Limpia todo el carrito.
  Cart clear() => const Cart(items: []);
}
