import 'package:flutter/services.dart';

/// Formateador para campos de cantidad:
/// 1. Bloquea ceros iniciales (evita '0', '01', '05', etc.).
/// 2. Si el número excede el stock máximo disponible, lo sustituye automáticamente.
class QuantityInputFormatter extends TextInputFormatter {
  final int maxStock;

  QuantityInputFormatter({required this.maxStock});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 1. Eliminar o bloquear ceros a la izquierda
    String text = newValue.text;
    if (text.startsWith('0')) {
      text = text.replaceFirst(RegExp(r'^0+'), '');
      if (text.isEmpty) {
        // Bloquear completamente la escritura del 0 si queda vacío
        return oldValue.text.isEmpty ? const TextEditingValue(text: '') : oldValue;
      }
    }

    // 2. Limitar según stock máximo
    final parsed = int.tryParse(text);
    if (parsed != null && maxStock > 0 && parsed > maxStock) {
      text = maxStock.toString();
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
