import 'package:ecommerce_app/core/constants/api_constants.dart';
import 'package:ecommerce_app/infrastructure/http/api_client.dart';
import 'package:ecommerce_app/infrastructure/models/payment_method_model.dart';

class PaymentService {
  final ApiClient _client;

  PaymentService(this._client);

  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    final data = await _client.get(ApiConstants.paymentMethods);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map<PaymentMethodModel>((json) => PaymentMethodModel.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<PaymentMethodModel> addPaymentMethod({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    bool isDefault = false,
  }) async {
    final body = {
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'isDefault': isDefault,
    };

    final data = await _client.post(
      ApiConstants.paymentMethods,
      body: body,
    );

    if (data is Map<String, dynamic>) {
      return PaymentMethodModel.fromJson(data);
    }
    throw const FormatException('Respuesta inesperada al guardar método de pago.');
  }

  Future<bool> deletePaymentMethod(String id) async {
    final data = await _client.delete('${ApiConstants.paymentMethods}/$id');
    return data == true || (data is Map && data['success'] == true);
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    String currency = 'usd',
    String? customerEmail,
    String? customerName,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'currency': currency,
    };
    if (customerEmail != null && customerEmail.isNotEmpty) {
      body['customerEmail'] = customerEmail;
    }
    if (customerName != null && customerName.isNotEmpty) {
      body['customerName'] = customerName;
    }

    final data = await _client.post(
      ApiConstants.createPaymentIntent,
      body: body,
    );

    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const FormatException('Respuesta inesperada al crear PaymentIntent.');
  }
}
