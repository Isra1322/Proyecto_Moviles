import 'package:flutter/material.dart';
import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/application/use_cases/cart/get_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/add_to_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/update_cart_quantity_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/remove_from_cart_use_case.dart';
import 'package:ecommerce_app/application/use_cases/cart/clear_cart_use_case.dart';
import 'auth_provider.dart';

class CartProvider extends ChangeNotifier {
  final GetCartUseCase _getCartUseCase;
  final AddToCartUseCase _addToCartUseCase;
  final UpdateCartQuantityUseCase _updateQuantityUseCase;
  final RemoveFromCartUseCase _removeFromCartUseCase;
  final ClearCartUseCase _clearCartUseCase;

  CartProvider(
    this._getCartUseCase,
    this._addToCartUseCase,
    this._updateQuantityUseCase,
    this._removeFromCartUseCase,
    this._clearCartUseCase,
  );

  Cart _cart = const Cart();
  // ignore: prefer_final_fields
  ViewStatus _status = ViewStatus.initial;
  String? _errorMessage;

  Cart get cart => _cart;
  ViewStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ViewStatus.loading;
  int get totalItems => _cart.totalItems;
  double get subtotal => _cart.subtotal;
  double get subtotalOrientativo => _cart.subtotalOrientativo;
  double get iva15 => _cart.iva15;
  double get totalConIva => _cart.totalConIva;

  Future<void> loadCart() async {
    try {
      _cart = await _getCartUseCase.execute();
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> addToCart(Product product, {int quantity = 1}) async {
    try {
      _cart = await _addToCartUseCase.execute(product, quantity: quantity);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> updateQuantity(int productId, int newQuantity) async {
    try {
      _cart = await _updateQuantityUseCase.execute(productId, newQuantity);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> removeItem(int productId) async {
    try {
      _cart = await _removeFromCartUseCase.execute(productId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clearCart() async {
    try {
      await _clearCartUseCase.execute();
      _cart = const Cart();
      notifyListeners();
    } catch (_) {}
  }

  void refreshAfterOrder() {
    _cart = const Cart();
    notifyListeners();
  }
}
