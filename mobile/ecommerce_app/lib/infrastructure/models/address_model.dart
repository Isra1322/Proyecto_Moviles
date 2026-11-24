class AddressModel {
  final String id;
  final int partnerId;
  final String title;
  final String street;
  final String city;
  final String stateOrProvince;
  final String? postalCode;
  final String? reference;
  final String phone;
  final bool isDefault;
  final DateTime? createdAt;

  const AddressModel({
    required this.id,
    required this.partnerId,
    required this.title,
    required this.street,
    required this.city,
    required this.stateOrProvince,
    this.postalCode,
    this.reference,
    required this.phone,
    required this.isDefault,
    this.createdAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      partnerId: json['partnerId'] is int
          ? json['partnerId'] as int
          : int.tryParse(json['partnerId']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      stateOrProvince: json['stateOrProvince']?.toString() ?? '',
      postalCode: json['postalCode']?.toString(),
      reference: json['reference']?.toString(),
      phone: json['phone']?.toString() ?? '',
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
      'title': title,
      'street': street,
      'city': city,
      'stateOrProvince': stateOrProvince,
      if (postalCode != null) 'postalCode': postalCode,
      if (reference != null) 'reference': reference,
      'phone': phone,
      'isDefault': isDefault,
    };
  }

  AddressModel copyWith({
    String? id,
    int? partnerId,
    String? title,
    String? street,
    String? city,
    String? stateOrProvince,
    String? postalCode,
    String? reference,
    String? phone,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      title: title ?? this.title,
      street: street ?? this.street,
      city: city ?? this.city,
      stateOrProvince: stateOrProvince ?? this.stateOrProvince,
      postalCode: postalCode ?? this.postalCode,
      reference: reference ?? this.reference,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get shortSummary => '$street, $city';

  String get fullSummary {
    final parts = [title, street, city];
    if (stateOrProvince.isNotEmpty) parts.add(stateOrProvince);
    if (reference != null && reference!.isNotEmpty) parts.add('Ref: $reference');
    if (phone.isNotEmpty) parts.add('Tel: $phone');
    return parts.join(', ');
  }
}
