import 'package:flutter/services.dart';

/// Formateador que convierte cualquier texto a minúsculas en tiempo real.
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

/// Formateador para el campo de Correo Electrónico:
/// - Convierte cualquier letra a minúscula.
/// - Permite únicamente letras minúsculas, números y los caracteres especiales: . _ @
/// - Límite de longitud: máximo 40 caracteres.
/// - No permite más de un '@'. Si ya existe un '@', rechaza un segundo '@'.
/// - No permite dos caracteres especiales seguidos (ej. no permitir .., __, @@, ._, .@, etc.).
/// - Bloquea cualquier ingreso después de '.com' (si el texto ya contiene '.com', no permitir escribir más caracteres).
class EmailInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 1. Convertir cualquier letra a minúscula
    final text = newValue.text.toLowerCase();

    // 2. No permitir ningún espacio en blanco
    if (text.contains(RegExp(r'\s'))) {
      return oldValue;
    }

    // 3. Caracteres permitidos: letras minúsculas, números y . _ @
    if (!RegExp(r'^[a-z0-9._@]+$').hasMatch(text)) {
      return oldValue;
    }

    // 4. Límite de longitud: máximo 40 caracteres
    if (text.length > 40) {
      return oldValue;
    }

    // 5. No permitir más de un '@'
    if ('@'.allMatches(text).length > 1) {
      return oldValue;
    }

    // 6. No permitir dos caracteres especiales seguidos (.., __, @@, ._, .@, _., etc.)
    if (RegExp(r'[._@]{2}').hasMatch(text)) {
      return oldValue;
    }

    // 7. Bloquear cualquier ingreso después del .com
    final comIndex = text.indexOf('.com');
    if (comIndex != -1 && comIndex + 4 < text.length) {
      return oldValue;
    }

    final baseOffset = newValue.selection.baseOffset.clamp(0, text.length);
    final extentOffset = newValue.selection.extentOffset.clamp(0, text.length);

    return TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
      ),
    );
  }
}
