class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}

