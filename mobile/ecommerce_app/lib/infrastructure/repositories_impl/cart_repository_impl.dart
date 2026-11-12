import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/repositories/i_cart_repository.dart';
import 'package:ecommerce_app/infrastructure/datasources/local/cart_local_data_source.dart';

class CartRepositoryImpl implements ICartRepository {
  final CartLocalDataSource _localDataSource;

  CartRepositoryImpl(this._localDataSource);

  @override
  Future<Cart> getCart() async {
    return await _localDataSource.getCart();
  }

  @override
  Future<void> saveCart(Cart cart) async {
    await _localDataSource.saveCart(cart);
  }

  @override
  Future<void> clearCart() async {
    await _localDataSource.clearCart();
  }
}
