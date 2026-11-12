class CreateOrderRequestModel {
  final int customerId;
  final String? customerName;
  final String? customerEmail;
  final List<CreateOrderItemRequestModel> items;

  const CreateOrderRequestModel({
    required this.customerId,
    this.customerName,
    this.customerEmail,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (customerEmail != null) 'customerEmail': customerEmail,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class CreateOrderItemRequestModel {
  final int productId;
  final double quantity;
  final double unitPrice;

  const CreateOrderItemRequestModel({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

