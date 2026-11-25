import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<OrderProvider>().loadOrders(user.customerId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().currentUser;
    final orderProvider = context.read<OrderProvider>();
    if (user != null &&
        orderProvider.status == ViewStatus.initial &&
        !orderProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          orderProvider.loadOrders(user.customerId);
        }
      });
    }
  }

  Future<void> _navigateToLogin() async {
    await Navigator.pushNamed(context, AppRoutes.login);
    if (!mounted) return;
    if (context.read<AuthProvider>().isAuthenticated) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<OrderProvider>().loadOrders(user.customerId);
      }
    }
  }

  Future<void> _navigateToLoginForOrders() async {
    await Navigator.pushNamed(context, AppRoutes.login);
    if (!mounted) return;
    if (context.read<AuthProvider>().isAuthenticated) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await context.read<OrderProvider>().loadOrders(user.customerId);
      }
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.orderHistory);
    }
  }

  Future<void> _navigateToLoginForAddresses() async {
    await Navigator.pushNamed(context, AppRoutes.login);
    if (!mounted) return;
    if (context.read<AuthProvider>().isAuthenticated) {
      Navigator.pushNamed(context, AppRoutes.addressList);
    }
  }

  String _getUserInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cálculo del total gastado acumulado a partir de las órdenes confirmadas/no canceladas
    final confirmedOrders = orderProvider.orders.where((o) {
      final s = o.status.toLowerCase();
      return s != 'cancelled' && s != 'cancelado' && s != '5';
    }).toList();

    final totalSpent = confirmedOrders.fold<double>(
      0.0,
      (sum, o) => sum + o.totalAmount,
    );

    final name = user?.name.isNotEmpty == true ? user!.name : 'Usuario';
    final email = user?.username ?? 'Sin correo asociado';
    final customerId = user?.customerId;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mi Perfil'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Configuración',
            splashRadius: 22,
            icon: Icon(
              Icons.settings_outlined,
              size: 22,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          if (authProvider.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Center(
                child: IconButton(
                  tooltip: 'Cerrar Sesión',
                  splashRadius: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  onPressed: _handleLogout,
                ),
              ),
            ),
          if (!authProvider.isAuthenticated)
            const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: user == null
              ? () async {}
              : () => orderProvider.loadOrders(user.customerId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!authProvider.isAuthenticated) ...[
                  // Cabecera estilizada de usuario invitado
                  _buildGuestCard(context),
                  const SizedBox(height: 20),

                  Text(
                    'Actividad y Opciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Mis Pedidos (con redirección al login)
                  _buildActionTile(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.primary,
                    title: 'Mis Pedidos',
                    subtitle:
                        'Inicia sesión para consultar tus pedidos anteriores',
                    onTap: _navigateToLoginForOrders,
                  ),
                  const SizedBox(height: 8),

                  // Mis Direcciones (con redirección al login)
                  _buildActionTile(
                    context: context,
                    icon: Icons.location_on_outlined,
                    iconColor: AppColors.primary,
                    title: 'Mis Direcciones',
                    subtitle:
                        'Inicia sesión para gestionar tus direcciones de entrega',
                    onTap: _navigateToLoginForAddresses,
                  ),
                ] else ...[
                  // 1. Tarjeta de Usuario (Avatar + Nombre + Correo)
                  _buildUserCard(
                    context,
                    name: name,
                    email: email,
                    customerId: customerId,
                  ),
                  const SizedBox(height: 16),

                  // 2. Resumen Financiero
                  _buildFinancialCard(
                    totalSpent: totalSpent,
                    confirmedCount: confirmedOrders.length,
                    totalOrders: orderProvider.orders.length,
                    isLoading: orderProvider.isLoading,
                  ),
                  const SizedBox(height: 20),

                  // 3. Accesos y Opciones
                  Text(
                    'Actividad y Opciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Acceso directo a Mis Pedidos
                  _buildActionTile(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.primary,
                    title: 'Mis Pedidos',
                    subtitle:
                        '${orderProvider.orders.length} pedidos registrados en tu historial',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.orderHistory),
                  ),
                  const SizedBox(height: 8),

                  // Acceso directo a Mis Direcciones
                  _buildActionTile(
                    context: context,
                    icon: Icons.location_on_outlined,
                    iconColor: AppColors.primary,
                    title: 'Mis Direcciones',
                    subtitle: 'Gestiona tus direcciones de entrega para el checkout',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.addressList),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primary.withAlpha(isDark ? 35 : 20),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido a E-Commerce',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explora el catálogo y accede a tu cuenta para comprar.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFAAAAAA) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _navigateToLogin,
                icon: const Icon(Icons.login_rounded, size: 20),
                label: const Text(
                  'Iniciar Sesión o Registrarse',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context, {
    required String name,
    required String email,
    required int? customerId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.primary,
              child: Text(
                _getUserInitials(name),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 15,
                        color: isDark ? const Color(0xFFAAAAAA) : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFFAAAAAA) : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (customerId != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(isDark ? 35 : 20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Cliente ID: #$customerId',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.lightBlueAccent : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard({
    required double totalSpent,
    required int confirmedCount,
    required int totalOrders,
    required bool isLoading,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Gastado Acumulado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const SizedBox(
                height: 36,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              Text(
                CurrencyFormatter.format(totalSpent),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.lightGreenAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$confirmedCount pedidos confirmados',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Total: $totalOrders',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(isDark ? 35 : 20),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: titleColor ?? (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? const Color(0xFFAAAAAA) : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: titleColor ?? (isDark ? Colors.white54 : Colors.grey.shade400),
        ),
        onTap: onTap,
      ),
    );
  }
}
