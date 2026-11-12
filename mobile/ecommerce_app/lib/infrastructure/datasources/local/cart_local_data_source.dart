import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/cart_item.dart';
import 'package:ecommerce_app/infrastructure/mappers/product_mapper.dart';
import 'package:ecommerce_app/infrastructure/models/product_model.dart';

class CartLocalDataSource {
  static const String _cartKey = 'cached_shopping_cart';
  final SharedPreferences _prefs;
  Cart _memoryCart = const Cart();

  CartLocalDataSource(this._prefs) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final raw = _prefs.getString(_cartKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final list = jsonDecode(raw) as List;
      final items = list.map<CartItem>((item) {
        final map = item as Map<String, dynamic>;
        final productModel = ProductModel.fromJson(map['product'] as Map<String, dynamic>);
        return CartItem(
          product: ProductMapper.toEntity(productModel),
          quantity: map['quantity'] as int? ?? 1,
          unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? productModel.price,
          imageBase64: (map['imageBase64'] ?? map['image_128'] ?? productModel.imageUrl) as String?,
        );
      }).toList();

      _memoryCart = Cart(items: items);
    } catch (_) {
      _memoryCart = const Cart();
    }
  }

  Future<Cart> getCart() async {
    return _memoryCart;
  }

  Future<void> saveCart(Cart cart) async {
    _memoryCart = cart;

    final serialized = cart.items.map((item) {
      final productModel = ProductMapper.toModel(item.product);
      final img = item.imageBase64 ?? item.product.imageUrl;
      return {
        'product': productModel.toJson(),
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'imageBase64': img,
        'image_128': img,
      };
    }).toList();

    await _prefs.setString(_cartKey, jsonEncode(serialized));
  }

  Future<void> clearCart() async {
    _memoryCart = const Cart();
    await _prefs.remove(_cartKey);
  }
}
