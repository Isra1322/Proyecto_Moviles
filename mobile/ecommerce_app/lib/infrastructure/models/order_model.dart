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
    // 1. Extraer ítems de la orden (items, order_line, orderLines, lines)
    var rawItems = json['items'] ?? json['order_line'] ?? json['orderLines'] ?? json['lines'];
    List<OrderItemModel> itemList = [];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          itemList.add(OrderItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // 2. Extraer Cliente (customerId y customerName)
    int parsedCustomerId = (json['customerId'] as num?)?.toInt() ?? 0;
    String parsedCustomerName = json['customerName'] as String? ?? '';

    final rawPartner = json['partner_id'];
    if (rawPartner is List && rawPartner.isNotEmpty) {
      if (parsedCustomerId == 0 && rawPartner[0] is num) {
        parsedCustomerId = (rawPartner[0] as num).toInt();
      }
      if (parsedCustomerName.isEmpty && rawPartner.length > 1 && rawPartner[1] != null) {
        parsedCustomerName = rawPartner[1].toString();
      }
    }

    // 3. Monto total (totalAmount, amount_total)
    final double parsedTotalAmount = (json['totalAmount'] as num?)?.toDouble() ??
        (json['amount_total'] as num?)?.toDouble() ??
        0.0;

    return OrderModel(
      id: json['id'] as int? ?? 0,
      odooOrderId: json['odooOrderId'] as int?,
      customerId: parsedCustomerId,
      customerName: parsedCustomerName,
      customerEmail: json['customerEmail'] as String?,
      orderDate: json['orderDate'] as String? ?? json['date_order'] as String? ?? '',
      status: json['status'] ?? json['state'],
      statusName: json['statusName'] as String?,
      totalAmount: parsedTotalAmount,
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
