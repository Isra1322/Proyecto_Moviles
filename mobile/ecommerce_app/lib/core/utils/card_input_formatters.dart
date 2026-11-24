import 'package:flutter/services.dart';

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text.replaceAll(' ', '');
    if (rawText.length > 16) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < rawText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(rawText[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var rawText = newValue.text.replaceAll('/', '');
    if (rawText.length > 4) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < rawText.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(rawText[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
