class CreateOrderRequestModel {
  final int customerId;
  final String? customerName;
  final String? customerEmail;
  final String? paymentMethodId;
  final String? paymentReference;
  final String? shippingAddressId;
  final String? shippingAddressText;
  final List<CreateOrderItemRequestModel> items;

  const CreateOrderRequestModel({
    required this.customerId,
    this.customerName,
    this.customerEmail,
    this.paymentMethodId,
    this.paymentReference,
    this.shippingAddressId,
    this.shippingAddressText,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (customerEmail != null) 'customerEmail': customerEmail,
      if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
      if (paymentReference != null) 'paymentReference': paymentReference,
      if (shippingAddressId != null) 'shippingAddressId': shippingAddressId,
      if (shippingAddressText != null) 'shippingAddressText': shippingAddressText,
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

