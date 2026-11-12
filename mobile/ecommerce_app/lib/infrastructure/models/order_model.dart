import 'order_item_model.dart';

class OrderModel {
  final int id;
  final int? odooOrderId;
  final int customerId;
  final String customerName;
  final String? customerEmail;
  final String orderDate;
  final dynamic status; // Puede venir como int o string de .NET
  final String? statusName;
  final double totalAmount;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    this.odooOrderId,
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    required this.orderDate,
    required this.status,
    this.statusName,
    required this.totalAmount,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<OrderItemModel> itemList = [];
    if (rawItems is List) {
      itemList = rawItems
          .whereType<Map<String, dynamic>>()
          .map((item) => OrderItemModel.fromJson(item))
          .toList();
    }

    return OrderModel(
      id: json['id'] as int? ?? 0,
      odooOrderId: json['odooOrderId'] as int?,
      customerId: json['customerId'] as int? ?? 0,
      customerName: json['customerName'] as String? ?? '',
      customerEmail: json['customerEmail'] as String?,
      orderDate: json['orderDate'] as String? ?? '',
      status: json['status'],
      statusName: json['statusName'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'odooOrderId': odooOrderId,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'orderDate': orderDate,
      'status': status,
      'statusName': statusName,
      'totalAmount': totalAmount,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

