import '../../../domain/entities/cart.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/repositories/i_cart_repository.dart';
import '../../../domain/repositories/i_order_repository.dart';

class CreateOrderUseCase {
  final IOrderRepository _orderRepository;
  final ICartRepository _cartRepository;

  CreateOrderUseCase(this._orderRepository, this._cartRepository);

  Future<Order> execute({
    required int customerId,
    required Cart cart,
    String? customerName,
    String? customerEmail,
  }) async {
    if (customerId <= 0) {
      throw ArgumentError('El identificador del cliente es inválido.');
    }

    if (cart.isEmpty) {
      throw ArgumentError('El carrito no contiene productos para generar el pedido.');
    }

    // 1. Confirmar pedido en la API REST (.NET / Odoo)
    final createdOrder = await _orderRepository.createOrder(
      customerId: customerId,
      cart: cart,
      customerName: customerName,
      customerEmail: customerEmail,
    );

    // 2. Limpiar el carrito local tras la creación exitosa del pedido
    await _cartRepository.clearCart();

    return createdOrder;
  }
}

