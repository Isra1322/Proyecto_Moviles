import 'package:intl/intl.dart';

class DateFormatter {
  static DateFormat get _dateFormat {
    try {
      return DateFormat('dd/MM/yyyy HH:mm', 'es_ES');
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy HH:mm', 'es');
      } catch (_) {
        return DateFormat('dd/MM/yyyy HH:mm');
      }
    }
  }

  /// Formatea un [DateTime] a string seguro en español 'dd/MM/yyyy HH:mm'.
  /// Defensivo: Convierte UTC a hora local y cuenta con múltiples niveles de fallback
  /// para garantizar que nunca arroje LocaleDataException ni rompa la UI.
  static String format(DateTime? date) {
    if (date == null) return '';
    final localDate = date.isUtc ? date.toLocal() : date;
    try {
      return _dateFormat.format(localDate);
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy HH:mm').format(localDate);
      } catch (_) {
        // Fallback manual seguro sin dependencia de intl
        final d = localDate.day.toString().padLeft(2, '0');
        final m = localDate.month.toString().padLeft(2, '0');
        final y = localDate.year.toString().padLeft(4, '0');
        final h = localDate.hour.toString().padLeft(2, '0');
        final min = localDate.minute.toString().padLeft(2, '0');
        return '$d/$m/$y $h:$min';
      }
    }
  }

  /// Parsea de forma segura cualquier string ISO 8601 o fecha UTC del backend (.NET/Odoo).
  static DateTime parseSafe(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(str);
    } catch (_) {
      try {
        final normalized = str.replaceAll('/', '-');
        return DateTime.parse(normalized);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  /// Parsea y formatea directamente desde un string o valor dinámico.
  static String formatFromString(dynamic dateStr) {
    return format(parseSafe(dateStr));
  }
}
