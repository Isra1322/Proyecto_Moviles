import 'order_item.dart';

class Order {
  final int id;
  final int? odooOrderId;
  final int customerId;
  final String customerName;
  final DateTime orderDate;
  final String status;
  final double totalAmount;
  final int? _itemsCount;
  final List<OrderItem> items;

  const Order({
    required this.id,
    this.odooOrderId,
    required this.customerId,
    required this.customerName,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    int? itemsCount,
    this.items = const [],
  }) : _itemsCount = (itemsCount != null && itemsCount > 0) ? itemsCount : null;

  int get itemsCount => _itemsCount ?? items.length;

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'draft':
      case '1':
        return 'Borrador / Presupuesto';
      case 'sent':
      case '2':
        return 'Enviado';
      case 'confirmed':
      case '3':
        return 'Confirmado';
      case 'done':
      case '4':
        return 'Completado';
      case 'cancelled':
      case '5':
        return 'Cancelado';
      default:
        return status;
    }
  }
}

