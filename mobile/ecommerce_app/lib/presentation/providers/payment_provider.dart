import 'package:flutter/material.dart';
import '../../infrastructure/datasources/remote/payment_service.dart';
import '../../infrastructure/models/payment_method_model.dart';
import 'auth_provider.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService;

  PaymentProvider(this._paymentService);

  ViewStatus _status = ViewStatus.initial;
  List<PaymentMethodModel> _paymentMethods = [];
  PaymentMethodModel? _selectedMethod;
  String? _errorMessage;

  ViewStatus get status => _status;
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  PaymentMethodModel? get selectedMethod => _selectedMethod;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ViewStatus.loading;

  void selectMethod(PaymentMethodModel method) {
    _selectedMethod = method;
    notifyListeners();
  }

  Future<void> loadPaymentMethods() async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _paymentMethods = await _paymentService.getPaymentMethods();
      if (_paymentMethods.isNotEmpty) {
        // Seleccionar tarjeta por defecto o la primera de la lista
        if (_selectedMethod == null || !_paymentMethods.any((m) => m.id == _selectedMethod!.id)) {
          _selectedMethod = _paymentMethods.firstWhere(
            (m) => m.isDefault,
            orElse: () => _paymentMethods.first,
          );
        }
      } else {
        _selectedMethod = null;
      }
      _status = ViewStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
      _status = ViewStatus.error;
    }
    notifyListeners();
  }

  Future<PaymentMethodModel?> addPaymentMethod({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    bool isDefault = false,
  }) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final newMethod = await _paymentService.addPaymentMethod(
        cardNumber: cardNumber,
        cardHolderName: cardHolderName,
        expiryDate: expiryDate,
        cvv: cvv,
        isDefault: isDefault,
      );
      _paymentMethods.insert(0, newMethod);
      _selectedMethod = newMethod;
      _status = ViewStatus.success;
      notifyListeners();
      return newMethod;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
      _status = ViewStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deletePaymentMethod(String id) async {
    try {
      final success = await _paymentService.deletePaymentMethod(id);
      if (success) {
        _paymentMethods.removeWhere((m) => m.id == id);
        if (_selectedMethod?.id == id) {
          _selectedMethod = _paymentMethods.isNotEmpty ? _paymentMethods.first : null;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    String currency = 'usd',
    String? customerEmail,
    String? customerName,
  }) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _paymentService.createPaymentIntent(
        amount: amount,
        currency: currency,
        customerEmail: customerEmail,
        customerName: customerName,
      );
      _status = ViewStatus.success;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ServerException: ', '');
      _status = ViewStatus.error;
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _status = ViewStatus.initial;
    _paymentMethods = [];
    _selectedMethod = null;
    _errorMessage = null;
    notifyListeners();
  }
}
