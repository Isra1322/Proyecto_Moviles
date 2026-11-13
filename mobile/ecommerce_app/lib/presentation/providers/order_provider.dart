import 'package:flutter/material.dart';
import 'package:ecommerce_app/domain/entities/cart.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/application/use_cases/orders/create_order_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_orders_use_case.dart';
import 'package:ecommerce_app/application/use_cases/orders/get_order_by_id_use_case.dart';
import 'auth_provider.dart';

class OrderProvider extends ChangeNotifier {
  final CreateOrderUseCase _createOrderUseCase;
  final GetOrdersUseCase _getOrdersUseCase;
  final GetOrderByIdUseCase? _getOrderByIdUseCase;

  OrderProvider(
    this._createOrderUseCase,
    this._getOrdersUseCase, [
    this._getOrderByIdUseCase,
  ]);

  ViewStatus _status = ViewStatus.initial;
  ViewStatus _createStatus = ViewStatus.initial;
  List<Order> _orders = [];
  Order? _lastCreatedOrder;
  String? _errorMessage;

  ViewStatus get status => _status;
  ViewStatus get createStatus => _createStatus;
  List<Order> get orders => _orders;
  Order? get lastCreatedOrder => _lastCreatedOrder;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ViewStatus.loading;
  bool get isCreating => _createStatus == ViewStatus.loading;

  Future<Order?> createOrder({
    required int customerId,
    required Cart cart,
    String? customerName,
    String? customerEmail,
  }) async {
    _createStatus = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _lastCreatedOrder = await _createOrderUseCase.execute(
        customerId: customerId,
        cart: cart,
        customerName: customerName,
        customerEmail: customerEmail,
      );
      _createStatus = ViewStatus.success;
      notifyListeners();
      return _lastCreatedOrder;
    } catch (e) {
      _errorMessage = _friendlyMessage(e);
      _createStatus = ViewStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadOrders(int customerId) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _orders = await _getOrdersUseCase.execute(customerId);
      _status = ViewStatus.success;
    } catch (e) {
      _errorMessage = _friendlyMessage(e);
      _status = ViewStatus.error;
    }
    notifyListeners();
  }

  Future<Order?> getOrderById(int orderId) async {
    final useCase = _getOrderByIdUseCase;
    if (useCase == null) return null;
    try {
      final order = await useCase.execute(orderId);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = order;
      }
      notifyListeners();
      return order;
    } catch (e) {
      return null;
    }
  }

  void resetCreateStatus() {
    _createStatus = ViewStatus.initial;
    _lastCreatedOrder = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('NetworkException') || msg.contains('SocketException')) {
      return 'Sin conexión a internet. Verifica tu red e intenta de nuevo.';
    }
    return msg.replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
  }
}

