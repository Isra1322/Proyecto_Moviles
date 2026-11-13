import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import '../../../core/utils/email_input_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await context.read<AuthProvider>().login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.catalog,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / Ícono
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'E-Commerce Móvil',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 36),
                  // Campo de usuario/correo
                  CustomTextField(
                    controller: _emailController,
                    label: 'Correo electrónico',
                    hint: 'ejemplo@correo.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !authProvider.isLoading,
                    autovalidateMode: _autovalidateMode,
                    maxLength: 40,
                    counterText: '',
                    inputFormatters: [
                      LowerCaseTextFormatter(),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._@]')),
                      LengthLimitingTextInputFormatter(40),
                      EmailInputFormatter(),
                    ],
                    validator: (val) {
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
                    },
                  ),
                  const SizedBox(height: 16),
                  // Campo de contraseña
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    enabled: !authProvider.isLoading,
                    autovalidateMode: _autovalidateMode,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Por favor, ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Mensaje de error de autenticación
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
                              authProvider.errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Botón de login
                  CustomButton(
                    label: 'Iniciar Sesión',
                    onPressed: _submit,
                    isLoading: authProvider.isLoading,
                    width: double.infinity,
                    icon: Icons.login,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes una cuenta?',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text(
                          'Regístrate aquí',
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

