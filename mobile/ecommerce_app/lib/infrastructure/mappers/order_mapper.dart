import '../../core/utils/date_formatter.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class OrderMapper {
  static OrderItem toItemEntity(OrderItemModel model) {
    return OrderItem(
      id: model.id,
      productId: model.productId,
      productName: model.productName,
      quantity: model.quantity,
      unitPrice: model.unitPrice,
      subtotal: model.subtotal,
    );
  }

  static Order toEntity(OrderModel model) {
    final parsedDate = DateFormatter.parseSafe(model.orderDate);

    final items = model.items.map(toItemEntity).toList();

    return Order(
      id: model.id,
      odooOrderId: model.odooOrderId,
      customerId: model.customerId,
      customerName: model.customerName,
      orderDate: parsedDate,
      status: model.statusName ?? model.status?.toString() ?? 'draft',
      totalAmount: model.totalAmount,
      items: items,
    );
  }
}

