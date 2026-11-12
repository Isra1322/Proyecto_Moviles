import '../entities/cart.dart';

abstract class ICartRepository {
  Future<Cart> getCart();
  Future<void> saveCart(Cart cart);
  Future<void> clearCart();
}

