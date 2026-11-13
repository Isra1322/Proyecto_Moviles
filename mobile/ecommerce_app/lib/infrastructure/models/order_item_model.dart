class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    int parsedProductId = 0;
    String parsedProductName = '';

    // 1. Extraer ID del producto
    if (json['productId'] != null) {
      parsedProductId = (json['productId'] as num?)?.toInt() ?? 0;
    }

    // 2. Extraer Nombre del producto
    if (json['productName'] != null) {
      parsedProductName = json['productName'].toString().trim();
    }

    // Compatibilidad con tupla Many2one de Odoo: product_id: [id, "Nombre del producto"]
    final rawProductId = json['product_id'] ?? json['productId'];
    if (rawProductId is List && rawProductId.isNotEmpty) {
      if (parsedProductId == 0 && rawProductId[0] is num) {
        parsedProductId = (rawProductId[0] as num).toInt();
      }
      if (parsedProductName.isEmpty && rawProductId.length > 1 && rawProductId[1] != null) {
        parsedProductName = rawProductId[1].toString().trim();
      }
    } else if (rawProductId is num && parsedProductId == 0) {
      parsedProductId = rawProductId.toInt();
    }

    // Fallback a 'name', 'display_name', o 'description' si 'productName' sigue vacío
    if (parsedProductName.isEmpty && json['name'] != null && json['name'].toString().trim().isNotEmpty) {
      parsedProductName = json['name'].toString().trim();
    }
    if (parsedProductName.isEmpty && json['display_name'] != null && json['display_name'].toString().trim().isNotEmpty) {
      parsedProductName = json['display_name'].toString().trim();
    }
    if (parsedProductName.isEmpty && json['description'] != null && json['description'].toString().trim().isNotEmpty) {
      parsedProductName = json['description'].toString().trim();
    }

    // Asegurar que el nombre real nunca quede vacío
    if (parsedProductName.isEmpty) {
      parsedProductName = parsedProductId > 0 ? 'Producto #$parsedProductId' : 'Producto';
    }

    // 3. Cantidad comprada: quantity, product_uom_qty, qty, product_qty
    double parsedQuantity = (json['quantity'] as num?)?.toDouble() ??
        (json['product_uom_qty'] as num?)?.toDouble() ??
        (json['product_qty'] as num?)?.toDouble() ??
        (json['qty'] as num?)?.toDouble() ??
        0.0;

    // 4. Precio unitario: unitPrice, price, price_unit
    final parsedUnitPrice = (json['unitPrice'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        (json['price_unit'] as num?)?.toDouble() ??
        0.0;

    // 5. Subtotal: subtotal, price_subtotal, o producto de cantidad * precio
    double parsedSubtotal = (json['subtotal'] as num?)?.toDouble() ??
        (json['price_subtotal'] as num?)?.toDouble() ??
        0.0;

    // Si la cantidad es 0 pero hay subtotal y precio unitario, derivar cantidad
    if (parsedQuantity <= 0.0 && parsedSubtotal > 0 && parsedUnitPrice > 0) {
      parsedQuantity = parsedSubtotal / parsedUnitPrice;
    }
    // Asegurar que la cantidad nunca quede en 0
    if (parsedQuantity <= 0.0) {
      parsedQuantity = 1.0;
    }

    if (parsedSubtotal == 0.0 && parsedQuantity > 0 && parsedUnitPrice > 0) {
      parsedSubtotal = parsedQuantity * parsedUnitPrice;
    }

    return OrderItemModel(
      id: json['id'] as int? ?? 0,
      productId: parsedProductId,
      productName: parsedProductName,
      quantity: parsedQuantity,
      unitPrice: parsedUnitPrice,
      subtotal: parsedSubtotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }
}
