import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '\$',
    decimalDigits: 2,
  );

  static String format(num amount) {
    return _formatter.format(amount);
  }
}

