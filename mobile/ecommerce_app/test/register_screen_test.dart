import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_app/presentation/screens/auth/register_screen.dart';

void main() {
  group('FullName Formatters Tests', () {
    final allowFilter = FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'));
    final titleFormatter = FullNameInputFormatter();

    test('FilteringTextInputFormatter.allow solo admite letras (con tildes/ñ) y espacios', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'Carlos 123 @# Mendoza Áñigo',
        selection: TextSelection.collapsed(offset: 27),
      );
      final result = allowFilter.formatEditUpdate(oldValue, newValue);
      // Números y @# deben ser eliminados
      expect(result.text, 'Carlos   Mendoza Áñigo');
    });

    test('No permite iniciar con un espacio en blanco', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: ' ',
        selection: TextSelection.collapsed(offset: 1),
      );
      final result = titleFormatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });

    test('No permite escribir dos espacios consecutivos', () {
      const oldValue = TextEditingValue(
        text: 'Carlos ',
        selection: TextSelection.collapsed(offset: 7),
      );
      const newValue = TextEditingValue(
        text: 'Carlos  ',
        selection: TextSelection.collapsed(offset: 8),
      );
      final result = titleFormatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'Carlos ');
    });

    test('Convierte automáticamente a Title Case tras cada palabra y espacio', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'carlos mendoza pérez',
        selection: TextSelection.collapsed(offset: 20),
      );
      final result = titleFormatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'Carlos Mendoza Pérez');
    });

    test('Conserva espacio al final para seguir escribiendo siguiente palabra', () {
      const oldValue = TextEditingValue(
        text: 'Carlos',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newValue = TextEditingValue(
        text: 'Carlos ',
        selection: TextSelection.collapsed(offset: 7),
      );
      final result = titleFormatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'Carlos ');
    });
  });

  group('EmailInputFormatter Tests', () {
    final formatter = EmailInputFormatter();

    test('No permite ingresar espacios en blanco', () {
      const oldValue = TextEditingValue(
        text: 'carlos',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newValue = TextEditingValue(
        text: 'carlos ',
        selection: TextSelection.collapsed(offset: 7),
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'carlos');
    });

    test('Permite únicamente letras, números y @, _, .', () {
      const oldValue = TextEditingValue.empty;
      const validValue = TextEditingValue(
        text: 'carlos.m_12@correo.com',
        selection: TextSelection.collapsed(offset: 22),
      );
      final result = formatter.formatEditUpdate(oldValue, validValue);
      expect(result.text, 'carlos.m_12@correo.com');

      // Intento de símbolo no permitido (ej: !)
      const invalidValue = TextEditingValue(
        text: 'carlos!@correo.com',
        selection: TextSelection.collapsed(offset: 7),
      );
      final invalidResult = formatter.formatEditUpdate(oldValue, invalidValue);
      expect(invalidResult.text, '');
    });

    test('Bloquea caracteres especiales iguales consecutivos y combinados (.., __, @@, ._, .@, etc.)', () {
      // @@
      const oldValueAt = TextEditingValue(text: 'user@', selection: TextSelection.collapsed(offset: 5));
      const newValueAt = TextEditingValue(text: 'user@@', selection: TextSelection.collapsed(offset: 6));
      expect(formatter.formatEditUpdate(oldValueAt, newValueAt).text, 'user@');

      // ..
      const oldValueDot = TextEditingValue(text: 'user.', selection: TextSelection.collapsed(offset: 5));
      const newValueDot = TextEditingValue(text: 'user..', selection: TextSelection.collapsed(offset: 6));
      expect(formatter.formatEditUpdate(oldValueDot, newValueDot).text, 'user.');

      // ._
      const oldValueDotUnder = TextEditingValue(text: 'user.', selection: TextSelection.collapsed(offset: 5));
      const newValueDotUnder = TextEditingValue(text: 'user._', selection: TextSelection.collapsed(offset: 6));
      expect(formatter.formatEditUpdate(oldValueDotUnder, newValueDotUnder).text, 'user.');

      // __
      const oldValueUnder = TextEditingValue(text: 'user_', selection: TextSelection.collapsed(offset: 5));
      const newValueUnder = TextEditingValue(text: 'user__', selection: TextSelection.collapsed(offset: 6));
      expect(formatter.formatEditUpdate(oldValueUnder, newValueUnder).text, 'user_');
    });

    test('Convierte automáticamente a minúsculas', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'CARLOS@GMAIL.COM',
        selection: TextSelection.collapsed(offset: 16),
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'carlos@gmail.com');
    });

    test('Bloquea cualquier ingreso después de .com', () {
      // Tras .com
      const valCom = TextEditingValue(text: 'carlos@mail.com', selection: TextSelection.collapsed(offset: 15));
      const valComDot = TextEditingValue(text: 'carlos@mail.com.', selection: TextSelection.collapsed(offset: 16));
      expect(formatter.formatEditUpdate(valCom, valComDot).text, 'carlos@mail.com');

      const valComChar = TextEditingValue(text: 'carlos@mail.coma', selection: TextSelection.collapsed(offset: 16));
      expect(formatter.formatEditUpdate(valCom, valComChar).text, 'carlos@mail.com');

      // Secuencia .com. en el texto
      const valComInMiddle = TextEditingValue(text: 'carlos@mail.com.ar', selection: TextSelection.collapsed(offset: 18));
      expect(formatter.formatEditUpdate(valCom, valComInMiddle).text, 'carlos@mail.com');

      // Punto normal antes de escribir la extensión sí es permitido (ej: dominio.)
      const valDominio = TextEditingValue(text: 'carlos@dominio', selection: TextSelection.collapsed(offset: 14));
      const valDominioDot = TextEditingValue(text: 'carlos@dominio.', selection: TextSelection.collapsed(offset: 15));
      expect(formatter.formatEditUpdate(valDominio, valDominioDot).text, 'carlos@dominio.');
    });
  });

  group('cleanServerErrorMessage Tests', () {
    test('Limpia la palabra "Server" pegada al mensaje', () {
      const raw = 'ServerYa existe un contacto registrado con este correo en Odoo.';
      final cleaned = cleanServerErrorMessage(raw);
      expect(cleaned, 'Error: Ya existe un contacto registrado con este correo en Odoo.');
    });

    test('Limpia "Server" pegado y elimina el sufijo "(status: 400)"', () {
      const raw = 'ServerYa existe un contacto registrado con este correo en Odoo. (status: 400)';
      final cleaned = cleanServerErrorMessage(raw);
      expect(cleaned, 'Error: Ya existe un contacto registrado con este correo en Odoo.');
    });

    test('Limpia "ServerException: "', () {
      const raw = 'ServerException: Ya existe un contacto registrado con este correo en Odoo.';
      final cleaned = cleanServerErrorMessage(raw);
      expect(cleaned, 'Error: Ya existe un contacto registrado con este correo en Odoo.');
    });

    test('Mantiene mensaje limpio si ya empieza con Error:', () {
      const raw = 'Error: Ya existe un contacto registrado con este correo en Odoo.';
      final cleaned = cleanServerErrorMessage(raw);
      expect(cleaned, 'Error: Ya existe un contacto registrado con este correo en Odoo.');
    });
  });

  group('Validators Logic Tests', () {
    String? validateName(String? val) {
      if (val == null || val.trim().isEmpty) {
        return 'El nombre completo es obligatorio.';
      }
      final trimmed = val.trim();
      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(trimmed)) {
        return 'El nombre no debe contener números ni caracteres especiales.';
      }
      final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.length < 2) {
        return 'Debes ingresar al menos 2 palabras (nombre y apellido).';
      }
      return null;
    }

    String? validateEmail(String? val) {
      if (val == null || val.trim().isEmpty) {
        return 'Por favor, ingresa tu correo electrónico';
      }
      final trimmed = val.trim().toLowerCase();
      if (trimmed.startsWith('.') || trimmed.startsWith('_') || trimmed.startsWith('@')) {
        return 'Ingresa un correo electrónico válido';
      }
      if (trimmed.endsWith('.') || trimmed.endsWith('_') || trimmed.endsWith('@')) {
        return 'Ingresa un correo electrónico válido';
      }
      if (RegExp(r'[._@]{2}').hasMatch(trimmed)) {
        return 'Ingresa un correo electrónico válido';
      }
      if ('@'.allMatches(trimmed).length != 1) {
        return 'Ingresa un correo electrónico válido';
      }
      final emailRegex = RegExp(r'^[a-z0-9]+([._][a-z0-9]+)*@[a-z0-9]+(\.[a-z0-9]+)*\.[a-z]{2,}$');
      if (!emailRegex.hasMatch(trimmed)) {
        return 'Ingresa un correo electrónico válido';
      }
      return null;
    }

    String? validatePhone(String? val) {
      if (val == null || val.trim().isEmpty) {
        return 'El teléfono es obligatorio.';
      }
      final trimmed = val.trim();
      if (!trimmed.startsWith('09')) {
        return 'El teléfono debe comenzar obligatoriamente con el prefijo 09.';
      }
      if (trimmed.length != 10) {
        return 'El teléfono debe contener exactamente 10 dígitos numéricos.';
      }
      return null;
    }

    test('Nombre: rechaza vacío, números, caracteres especiales o menos de 2 palabras', () {
      expect(validateName(''), 'El nombre completo es obligatorio.');
      expect(validateName('Carlos123'), 'El nombre no debe contener números ni caracteres especiales.');
      expect(validateName('Carlos@ Mendoza'), 'El nombre no debe contener números ni caracteres especiales.');
      expect(validateName('Carlos'), 'Debes ingresar al menos 2 palabras (nombre y apellido).');
      expect(validateName('Carlos Mendoza'), isNull);
      expect(validateName('María José Peña Gómez'), isNull);
    });

    test('Correo: rechaza vacío, si termina en punto o estructura inválida', () {
      expect(validateEmail(''), 'Por favor, ingresa tu correo electrónico');
      expect(validateEmail('usuario@dominio.'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio.com.'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario.com'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio..com'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio.c'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio.123'), 'Ingresa un correo electrónico válido');
      expect(validateEmail('usuario@dominio.com'), isNull);
      expect(validateEmail('carlos_mendoza.12@empresa.com'), isNull);
      expect(validateEmail('carlos@empresa.ec'), isNull);
      expect(validateEmail('carlos@empresa.org'), isNull);
      expect(validateEmail('carlos@empresa.net'), isNull);
    });

    test('Teléfono: rechaza vacío, prefijo distinto a 09 o longitud diferente a 10', () {
      expect(validatePhone(''), 'El teléfono es obligatorio.');
      expect(validatePhone('0891234567'), 'El teléfono debe comenzar obligatoriamente con el prefijo 09.');
      expect(validatePhone('0912345'), 'El teléfono debe contener exactamente 10 dígitos numéricos.');
      expect(validatePhone('09912345678'), 'El teléfono debe contener exactamente 10 dígitos numéricos.');
      expect(validatePhone('0991234567'), isNull);
    });
  });
}
