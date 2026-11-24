class PaymentMethodModel {
  final String id;
  final int partnerId;
  final String cardHolderName;
  final String maskedCardNumber;
  final String cardType;
  final String expiryDate;
  final bool isDefault;
  final DateTime? createdAt;

  const PaymentMethodModel({
    required this.id,
    required this.partnerId,
    required this.cardHolderName,
    required this.maskedCardNumber,
    required this.cardType,
    required this.expiryDate,
    required this.isDefault,
    this.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id']?.toString() ?? '',
      partnerId: json['partnerId'] is int
          ? json['partnerId'] as int
          : int.tryParse(json['partnerId']?.toString() ?? '0') ?? 0,
      cardHolderName: json['cardHolderName']?.toString() ?? '',
      maskedCardNumber: json['maskedCardNumber']?.toString() ?? '',
      cardType: json['cardType']?.toString() ?? 'Tarjeta',
      expiryDate: json['expiryDate']?.toString() ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'cardHolderName': cardHolderName,
      'maskedCardNumber': maskedCardNumber,
      'cardType': cardType,
      'expiryDate': expiryDate,
      'isDefault': isDefault,
    };
  }
}
