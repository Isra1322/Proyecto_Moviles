import '../../../domain/entities/cart.dart';
import '../../../domain/repositories/i_cart_repository.dart';

class UpdateCartQuantityUseCase {
  final ICartRepository _repository;

  UpdateCartQuantityUseCase(this._repository);

  Future<Cart> execute(int productId, int newQuantity) async {
    final currentCart = await _repository.getCart();
    final updatedCart = currentCart.updateQuantity(productId, newQuantity);
    await _repository.saveCart(updatedCart);
    return updatedCart;
  }
}

