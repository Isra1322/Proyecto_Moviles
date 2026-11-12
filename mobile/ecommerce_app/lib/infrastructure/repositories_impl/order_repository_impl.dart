import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/repositories/i_order_repository.dart';
import 'package:ecommerce_app/infrastructure/datasources/remote/order_remote_data_source.dart';
import 'package:ecommerce_app/infrastructure/mappers/order_mapper.dart';
import 'package:ecommerce_app/infrastructure/models/create_order_request_model.dart';

class OrderRepositoryImpl implements IOrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<Order> createOrder({
    required int customerId,
    required Cart cart,
    String? customerName,
    String? customerEmail,
  }) async {
    final requestItems = cart.items.map((item) {
      return CreateOrderItemRequestModel(
        productId: item.product.id,
        quantity: item.quantity.toDouble(),
        unitPrice: item.unitPrice,
      );
    }).toList();

    final request = CreateOrderRequestModel(
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      items: requestItems,
    );

    final model = await _remoteDataSource.createOrder(request);
    return OrderMapper.toEntity(model);
  }

  @override
  Future<List<Order>> getOrdersByCustomer(int customerId) async {
    final models = await _remoteDataSource.getOrdersByCustomer(customerId);
    return models.map<Order>(OrderMapper.toEntity).toList();
  }
}
