import '../entities/cart.dart';
import '../entities/order.dart';

abstract class IOrderRepository {
  Future<Order> createOrder({
    required int customerId,
    required Cart cart,
    String? customerName,
    String? customerEmail,
    String? paymentMethodId,
    String? paymentReference,
    String? shippingAddressId,
    String? shippingAddressText,
  });

  Future<List<Order>> getOrdersByCustomer(int customerId);

  Future<Order> getOrderById(int orderId);
}

