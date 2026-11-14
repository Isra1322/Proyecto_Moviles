import '../../core/utils/date_formatter.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class OrderMapper {
  static OrderItem toItemEntity(OrderItemModel model) {
    final double quantity = model.quantity > 0 ? model.quantity : 1.0;
    final double computedSubtotal = model.subtotal > 0
        ? model.subtotal
        : (quantity * model.unitPrice);

    final String displayName = model.productName.trim().isNotEmpty
        ? model.productName.trim()
        : (model.productId > 0 ? 'Producto #${model.productId}' : 'Producto');

    return OrderItem(
      id: model.id,
      productId: model.productId,
      productName: displayName,
      quantity: quantity,
      unitPrice: model.unitPrice,
      subtotal: computedSubtotal,
    );
  }

  static Order toEntity(OrderModel model) {
    final parsedDate = DateFormatter.parseSafe(model.orderDate);

    final items = model.items.map(toItemEntity).toList();
    final itemsCount = model.itemsCount > 0 ? model.itemsCount : items.length;

    return Order(
      id: model.id,
      odooOrderId: model.odooOrderId,
      customerId: model.customerId,
      customerName: model.customerName,
      orderDate: parsedDate,
      status: model.statusName ?? model.status?.toString() ?? 'draft',
      totalAmount: model.totalAmount,
      itemsCount: itemsCount,
      items: items,
    );
  }
}
