import '../../../domain/entities/order.dart';
import '../../../domain/repositories/i_order_repository.dart';

class GetOrderByIdUseCase {
  final IOrderRepository _repository;

  GetOrderByIdUseCase(this._repository);

  Future<Order> execute(int orderId) async {
    if (orderId <= 0) {
      throw ArgumentError('El identificador del pedido debe ser mayor a cero.');
    }

    return await _repository.getOrderById(orderId);
  }
}
