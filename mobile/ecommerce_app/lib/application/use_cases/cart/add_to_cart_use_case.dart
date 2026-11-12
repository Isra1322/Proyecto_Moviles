import '../../../domain/entities/cart.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/i_cart_repository.dart';

class AddToCartUseCase {
  final ICartRepository _repository;

  AddToCartUseCase(this._repository);

  Future<Cart> execute(Product product, {int quantity = 1}) async {
    if (quantity <= 0) {
      throw ArgumentError('La cantidad a agregar debe ser mayor a cero.');
    }

    final currentCart = await _repository.getCart();
    final updatedCart = currentCart.addItem(product, quantity: quantity);
    await _repository.saveCart(updatedCart);
    return updatedCart;
  }
}

