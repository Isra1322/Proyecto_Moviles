import 'package:ecommerce_app/core/constants/api_constants.dart';
import 'package:ecommerce_app/infrastructure/http/api_client.dart';
import 'package:ecommerce_app/infrastructure/models/create_order_request_model.dart';
import 'package:ecommerce_app/infrastructure/models/order_model.dart';

class OrderRemoteDataSource {
  final ApiClient _client;

  OrderRemoteDataSource(this._client);

  Future<OrderModel> createOrder(CreateOrderRequestModel request) async {
    final data = await _client.post(
      ApiConstants.orders,
      body: request.toJson(),
    );

    if (data is Map<String, dynamic>) {
      return OrderModel.fromJson(data);
    }
    throw const FormatException('Formato de orden inesperado devuelto por la API.');
  }

  Future<List<OrderModel>> getOrdersByCustomer(int customerId) async {
    final queryParams = {'customerId': customerId.toString()};
    final data = await _client.get(
      ApiConstants.orders,
      queryParams: queryParams,
    );

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map<OrderModel>((item) => OrderModel.fromJson(item))
          .toList();
    }
    return <OrderModel>[];
  }

  Future<OrderModel> getOrderById(int orderId) async {
    final data = await _client.get('${ApiConstants.orders}/$orderId');

    if (data is Map<String, dynamic>) {
      return OrderModel.fromJson(data);
    }
    throw const FormatException('Formato de orden inesperado devuelto por la API.');
  }
}
