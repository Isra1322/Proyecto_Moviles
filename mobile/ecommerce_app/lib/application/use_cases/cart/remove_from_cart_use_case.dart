import '../../../domain/entities/cart.dart';
import '../../../domain/repositories/i_cart_repository.dart';

class RemoveFromCartUseCase {
  final ICartRepository _repository;

  RemoveFromCartUseCase(this._repository);

  Future<Cart> execute(int productId) async {
    final currentCart = await _repository.getCart();
    final updatedCart = currentCart.removeItem(productId);
    await _repository.saveCart(updatedCart);
    return updatedCart;
  }
}

