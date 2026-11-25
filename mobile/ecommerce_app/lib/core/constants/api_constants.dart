class ApiConstants {
  static const String baseUrl = 'http://100.101.117.77:5124';

  static const String products = '/api/Products';
  static const String categories = '/api/Categories';
  static const String orders = '/api/Orders';
  static const String paymentMethods = '/api/PaymentMethods';
  static const String createPaymentIntent = '/api/Payments/create-payment-intent';
  static const String addresses = '/api/Addresses';
  static const String login = '/api/Auth/login';
  static const String register = '/api/Auth/register';

  static const Duration timeout = Duration(seconds: 30);
}
