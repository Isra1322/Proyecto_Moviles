import '../../../domain/entities/cart.dart';
import '../../../domain/repositories/i_cart_repository.dart';

class GetCartUseCase {
  final ICartRepository _repository;

  GetCartUseCase(this._repository);

  Future<Cart> execute() async {
    return await _repository.getCart();
  }
}

