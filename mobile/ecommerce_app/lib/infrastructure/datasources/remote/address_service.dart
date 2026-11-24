import 'package:ecommerce_app/core/constants/api_constants.dart';
import 'package:ecommerce_app/infrastructure/http/api_client.dart';
import 'package:ecommerce_app/infrastructure/models/address_model.dart';

class AddressService {
  final ApiClient _client;

  AddressService(this._client);

  Future<List<AddressModel>> getAddresses() async {
    final data = await _client.get(ApiConstants.addresses);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map<AddressModel>((json) => AddressModel.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<AddressModel> createAddress({
    required String title,
    required String street,
    required String city,
    String stateOrProvince = '',
    String? postalCode,
    String? reference,
    required String phone,
    bool isDefault = false,
  }) async {
    final body = {
      'title': title,
      'street': street,
      'city': city,
      'stateOrProvince': stateOrProvince,
      if (postalCode != null && postalCode.isNotEmpty) 'postalCode': postalCode,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
      'phone': phone,
      'isDefault': isDefault,
    };

    final data = await _client.post(
      ApiConstants.addresses,
      body: body,
    );

    if (data is Map<String, dynamic>) {
      return AddressModel.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al guardar la dirección.');
  }

  Future<AddressModel> updateAddress({
    required String id,
    required String title,
    required String street,
    required String city,
    String stateOrProvince = '',
    String? postalCode,
    String? reference,
    required String phone,
    bool isDefault = false,
  }) async {
    final body = {
      'title': title,
      'street': street,
      'city': city,
      'stateOrProvince': stateOrProvince,
      if (postalCode != null && postalCode.isNotEmpty) 'postalCode': postalCode,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
      'phone': phone,
      'isDefault': isDefault,
    };

    final data = await _client.put(
      '${ApiConstants.addresses}/$id',
      body: body,
    );

    if (data is Map<String, dynamic>) {
      return AddressModel.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al actualizar la dirección.');
  }

  Future<bool> deleteAddress(String id) async {
    final data = await _client.delete('${ApiConstants.addresses}/$id');
    return data == true || (data is Map && data['success'] == true);
  }

  Future<AddressModel> setDefaultAddress(String id) async {
    final data = await _client.put('${ApiConstants.addresses}/$id/set-default');
    if (data is Map<String, dynamic>) {
      return AddressModel.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al establecer dirección predeterminada.');
  }
}
