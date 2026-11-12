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

    test('Permite únicamente letras, números y @, _, -, .', () {
      const oldValue = TextEditingValue.empty;
      const validValue = TextEditingValue(
        text: 'carlos.m_1-2@correo.com',
        selection: TextSelection.collapsed(offset: 23),
      );
      final result = formatter.formatEditUpdate(oldValue, validValue);
      expect(result.text, 'carlos.m_1-2@correo.com');

      // Intento de símbolo no permitido (ej: !)
      const invalidValue = TextEditingValue(
        text: 'carlos!@correo.com',
        selection: TextSelection.collapsed(offset: 7),
      );
      final invalidResult = formatter.formatEditUpdate(oldValue, invalidValue);
      expect(invalidResult.text, '');
    });

    test('Bloquea caracteres especiales iguales consecutivos (--, .., __, @@)', () {
      // @@
      const oldValueAt = TextEditingValue(text: 'user@', selection: TextSelection.collapsed(offset: 5));
      const newValueAt = TextEditingValue(text: 'user@@', selection: TextSelection.collapsed(offset: 6));
      expect(formatter.formatEditUpdate(oldValueAt, newValueAt).text, 'user@');

      // ..
      const oldValueDot = TextEditingValue(text: 'user.', selection: TextSelection.collapsed(offset: 5));
      const newValueDot = TextEditingValue(text: 'user..', selection: TextSelection.collapsed(offset: 6));
      expect(formatter.formatEditUpdate(oldValueDot, newValueDot).text, 'user.');

      // --
      const oldValueDash = TextEditingValue(text: 'user-', selection: TextSelection.collapsed(offset: 5));
      const newValueDash = TextEditingValue(text: 'user--', selection: TextSelection.collapsed(offset: 6));
      expect(formatter.formatEditUpdate(oldValueDash, newValueDash).text, 'user-');

      // __
      const oldValueUnder = TextEditingValue(text: 'user_', selection: TextSelection.collapsed(offset: 5));
      const newValueUnder = TextEditingValue(text: 'user__', selection: TextSelection.collapsed(offset: 6));
      expect(formatter.formatEditUpdate(oldValueUnder, newValueUnder).text, 'user_');
    });

    test('Bloquea punto inmediatamente después o al final si contiene .com, .net, .org, .ec', () {
      // Tras .com
      const valCom = TextEditingValue(text: 'carlos@mail.com', selection: TextSelection.collapsed(offset: 15));
      const valComDot = TextEditingValue(text: 'carlos@mail.com.', selection: TextSelection.collapsed(offset: 16));
      expect(formatter.formatEditUpdate(valCom, valComDot).text, 'carlos@mail.com');

      // Tras .net
      const valNet = TextEditingValue(text: 'carlos@mail.net', selection: TextSelection.collapsed(offset: 15));
      const valNetDot = TextEditingValue(text: 'carlos@mail.net.', selection: TextSelection.collapsed(offset: 16));
      expect(formatter.formatEditUpdate(valNet, valNetDot).text, 'carlos@mail.net');

      // Tras .org
      const valOrg = TextEditingValue(text: 'carlos@mail.org', selection: TextSelection.collapsed(offset: 15));
      const valOrgDot = TextEditingValue(text: 'carlos@mail.org.', selection: TextSelection.collapsed(offset: 16));
      expect(formatter.formatEditUpdate(valOrg, valOrgDot).text, 'carlos@mail.org');

      // Tras .ec
      const valEc = TextEditingValue(text: 'carlos@mail.ec', selection: TextSelection.collapsed(offset: 14));
      const valEcDot = TextEditingValue(text: 'carlos@mail.ec.', selection: TextSelection.collapsed(offset: 15));
      expect(formatter.formatEditUpdate(valEc, valEcDot).text, 'carlos@mail.ec');

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
        return 'El correo electrónico es obligatorio.';
      }
      final trimmed = val.trim();
      if (trimmed.endsWith('.')) {
        return 'El correo no puede terminar con un punto.';
      }
      if (RegExp(r'\.(com|net|org|ec)\.', caseSensitive: false).hasMatch(trimmed) || trimmed.contains('..')) {
        return 'El correo no debe contener puntos después de la extensión (ej: .com.).';
      }
      final strictEmailRegex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!strictEmailRegex.hasMatch(trimmed)) {
        return 'Ingresa un correo electrónico válido (ej: usuario@dominio.com).';
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

    test('Correo: rechaza vacío, si termina en punto, secuencias .com. o estructura inválida', () {
      expect(validateEmail(''), 'El correo electrónico es obligatorio.');
      expect(validateEmail('usuario@dominio.'), 'El correo no puede terminar con un punto.');
      expect(validateEmail('usuario@dominio.com.'), 'El correo no puede terminar con un punto.');
      expect(validateEmail('usuario@dominio.com.ar'), 'El correo no debe contener puntos después de la extensión (ej: .com.).');
      expect(validateEmail('usuario@dominio.net.ec'), 'El correo no debe contener puntos después de la extensión (ej: .com.).');
      expect(validateEmail('usuario@dominio'), 'Ingresa un correo electrónico válido (ej: usuario@dominio.com).');
      expect(validateEmail('usuario.com'), 'Ingresa un correo electrónico válido (ej: usuario@dominio.com).');
      expect(validateEmail('usuario@dominio..com'), 'El correo no debe contener puntos después de la extensión (ej: .com.).');
      expect(validateEmail('usuario@dominio.c'), 'Ingresa un correo electrónico válido (ej: usuario@dominio.com).');
      expect(validateEmail('usuario@dominio.123'), 'Ingresa un correo electrónico válido (ej: usuario@dominio.com).');
      expect(validateEmail('usuario@dominio.com'), isNull);
      expect(validateEmail('carlos_mendoza-12@empresa.com'), isNull);
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
