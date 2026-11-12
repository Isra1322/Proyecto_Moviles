import '../../../domain/entities/order.dart';
import '../../../domain/repositories/i_order_repository.dart';

class GetOrdersUseCase {
  final IOrderRepository _repository;

  GetOrdersUseCase(this._repository);

  Future<List<Order>> execute(int customerId) async {
    if (customerId <= 0) {
      throw ArgumentError('El identificador del cliente debe ser válido.');
    }

    return await _repository.getOrdersByCustomer(customerId);
  }
}

