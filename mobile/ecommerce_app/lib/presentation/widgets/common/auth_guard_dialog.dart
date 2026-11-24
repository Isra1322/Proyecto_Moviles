import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

/// Muestra un diálogo moderno solicitando iniciar sesión para realizar acciones protegidas.
/// Retorna `true` si el usuario decidió presionar "Iniciar Sesión", o `false`/`null` si canceló.
Future<bool?> showAuthRequiredDialog(
  BuildContext context, {
  String title = 'Inicia sesión para continuar',
  String message =
      'Necesitas una cuenta para gestionar tu carrito y realizar pedidos.',
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Helper que muestra el diálogo de autenticación requerida y, si el usuario acepta,
/// navega a LoginScreen. Retorna `true` si el usuario inició sesión exitosamente.
Future<bool> promptLoginGuard(
  BuildContext context, {
  String? message,
}) async {
  final confirmed = await showAuthRequiredDialog(
    context,
    message: message ??
        'Necesitas una cuenta para gestionar tu carrito y realizar pedidos.',
  );

  if (confirmed == true && context.mounted) {
    final result = await Navigator.pushNamed(context, AppRoutes.login);
    if (!context.mounted) return false;
    return result == true || context.read<AuthProvider>().isAuthenticated;
  }

  return false;
}
