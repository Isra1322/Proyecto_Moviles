import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../catalog/catalog_screen.dart';

/// Formateador para el campo "Nombre Completo":
/// - No permitir iniciar el texto con un espacio en blanco.
/// - No permitir escribir dos o más espacios en blanco consecutivos.
/// - Convertir automáticamente a mayúscula la primera letra de cada palabra
///   y el resto en minúsculas (formato Title Case).
class FullNameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // No permitir iniciar el texto con un espacio en blanco
    if (newValue.text.startsWith(' ')) {
      return oldValue;
    }

    // No permitir escribir dos o más espacios en blanco consecutivos
    if (newValue.text.contains('  ')) {
      return oldValue;
    }

    // Formateo Title Case: primera letra de cada palabra mayúscula, resto en minúsculas
    final words = newValue.text.split(' ');
    final formattedWords = words.map((word) {
      if (word.isEmpty) return word;
      final firstChar = word[0].toUpperCase();
      final rest = word.length > 1 ? word.substring(1).toLowerCase() : '';
      return '$firstChar$rest';
    });
    final formattedText = formattedWords.join(' ');

    final baseOffset = newValue.selection.baseOffset < 0
        ? formattedText.length
        : newValue.selection.baseOffset.clamp(0, formattedText.length);
    final extentOffset = newValue.selection.extentOffset < 0
        ? formattedText.length
        : newValue.selection.extentOffset.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
      ),
    );
  }
}

/// Formateador para el campo "Correo Electrónico":
/// - No permitir ingresar ningún espacio en blanco.
/// - Permitir únicamente letras, números y los caracteres especiales: @, _, -, .
///   Bloquear cualquier otro símbolo.
/// - No permitir escribir dos caracteres especiales iguales de forma consecutiva (ej: ---, ..., ___, @@).
/// - Si el texto ya contiene .com (o .net, .org, .ec), bloquea la escritura de un punto '.' adicional inmediatamente después o al final.
class EmailInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // No permitir ningún espacio en blanco
    if (newValue.text.contains(RegExp(r'\s'))) {
      return oldValue;
    }

    // Permitir únicamente letras, números y los caracteres especiales: @, _, -, .
    if (!RegExp(r'^[a-zA-Z0-9@_.-]+$').hasMatch(newValue.text)) {
      return oldValue;
    }

    // No permitir escribir dos caracteres especiales iguales de forma consecutiva
    if (RegExp(r'([@_.-])\1').hasMatch(newValue.text)) {
      return oldValue;
    }

    final lower = newValue.text.toLowerCase();

    // Bloquea punto inmediatamente después de .com, .net, .org, .ec (ej: .com.)
    if (RegExp(r'\.(com|net|org|ec)\.').hasMatch(lower)) {
      return oldValue;
    }

    // Si el texto ya contiene .com (o .net, .org, .ec), bloquea la escritura de un punto adicional al final
    if (lower.endsWith('.')) {
      if (lower.contains('.com') ||
          lower.contains('.net') ||
          lower.contains('.org') ||
          lower.contains('.ec')) {
        return oldValue;
      }
    }

    return newValue;
  }
}

/// Limpia y formatea mensajes de error devueltos por la API eliminando la palabra "Server" pegada
/// o prefijos de excepción, mostrando una cadena limpia para el usuario.
String cleanServerErrorMessage(String rawMessage) {
  var message = rawMessage.trim();

  if (message.startsWith('ServerException:')) {
    message = message.replaceFirst(RegExp(r'^ServerException:\s*'), '');
  } else if (message.startsWith('Server')) {
    message = message.replaceFirst(RegExp(r'^Server\s*'), '');
  }
  message = message.replaceFirst(RegExp(r'^(Exception|AuthException|ArgumentError):\s*'), '');

  // Limpiar cualquier sufijo de estado tipo (status: 400)
  message = message.replaceAll(RegExp(r'\s*\(status:\s*\d+\)'), '');
  message = message.trim();

  if (message.isEmpty) {
    return 'Error: Ocurrió un error inesperado al procesar la solicitud.';
  }

  if (message.toLowerCase().startsWith('error:')) {
    return message;
  }

  return 'Error: $message';
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada exitosamente en Odoo!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CatalogScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      size: 52,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Registro de Cliente',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Crea tu cuenta para vincular tu contacto en Odoo',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // 1. Nombre Completo
                  CustomTextField(
                    label: 'Nombre Completo',
                    hint: 'Ej: Carlos Mendoza',
                    controller: _nameController,
                    prefixIcon: Icons.badge_outlined,
                    maxLength: 50,
                    counterText: '',
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      FullNameInputFormatter(),
                    ],
                    validator: (val) {
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
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Correo Electrónico
                  CustomTextField(
                    label: 'Correo Electrónico',
                    hint: 'ejemplo@correo.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    maxLength: 30,
                    counterText: '',
                    inputFormatters: [
                      EmailInputFormatter(),
                    ],
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'El correo electrónico es obligatorio.';
                      }
                      final trimmed = val.trim();
                      // Rechaza explícitamente cualquier correo que finalice con un punto '.'
                      if (trimmed.endsWith('.')) {
                        return 'El correo no puede terminar con un punto.';
                      }
                      // Rechaza explícitamente secuencias como .com., .net., .org., .ec. o dobles puntos
                      if (RegExp(r'\.(com|net|org|ec)\.', caseSensitive: false).hasMatch(trimmed) || trimmed.contains('..')) {
                        return 'El correo no debe contener puntos después de la extensión (ej: .com.).';
                      }
                      // Expresión regular estricta que exige terminar en un dominio alfanumérico válido ([a-zA-Z]{2,})
                      final strictEmailRegex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!strictEmailRegex.hasMatch(trimmed)) {
                        return 'Ingresa un correo electrónico válido (ej: usuario@dominio.com).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Teléfono
                  CustomTextField(
                    label: 'Teléfono',
                    hint: '0991234567',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    maxLength: 10,
                    counterText: '',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (val) {
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
                    },
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
                  CustomTextField(
                    label: 'Contraseña',
                    hint: 'Mínimo 6 caracteres',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'La contraseña es obligatoria.';
                      }
                      if (val.length < 6) {
                        return 'Debe tener al menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Mensaje de error del servidor con formato limpio
                  if (authProvider.status == ViewStatus.error && authProvider.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cleanServerErrorMessage(authProvider.errorMessage!),
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Botón de Registrarse
                  CustomButton(
                    label: 'Registrar Cuenta',
                    onPressed: _submit,
                    isLoading: authProvider.isLoading,
                    width: double.infinity,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 16),

                  // Volver a login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes una cuenta?',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Inicia Sesión',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
