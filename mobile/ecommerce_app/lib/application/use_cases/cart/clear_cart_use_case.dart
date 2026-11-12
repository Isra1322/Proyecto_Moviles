import '../../../domain/repositories/i_cart_repository.dart';

class ClearCartUseCase {
  final ICartRepository _repository;

  ClearCartUseCase(this._repository);

  Future<void> execute() async {
    await _repository.clearCart();
  }
}

