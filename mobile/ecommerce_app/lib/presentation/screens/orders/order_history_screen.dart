import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';
import 'package:ecommerce_app/core/utils/date_formatter.dart';
import 'package:ecommerce_app/domain/entities/order.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/empty_view.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser == null) {
        await authProvider.checkSavedSession();
      }
      final user = authProvider.currentUser;
      if (user != null && mounted) {
        context.read<OrderProvider>().loadOrders(user.customerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: user == null
              ? () async {}
              : () => orderProvider.loadOrders(user.customerId),
          child: _buildBody(orderProvider, user?.customerId),
        ),
      ),
    );
  }

  Widget _buildBody(OrderProvider provider, int? customerId) {
    if (provider.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 400,
            child: LoadingIndicator(message: 'Cargando historial...'),
          ),
        ],
      );
    }

    if (provider.status == ViewStatus.error) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: ErrorView(
              message:
                  provider.errorMessage ?? 'No se pudo cargar el historial.',
              onRetry: customerId != null
                  ? () => provider.loadOrders(customerId)
                  : null,
            ),
          ),
        ],
      );
    }

    if (provider.orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 400,
            child: EmptyView(
              message: 'Aún no has realizado ningún pedido.',
              icon: Icons.receipt_long_outlined,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: provider.orders.length,
      itemBuilder: (_, index) => _OrderCard(order: provider.orders[index]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  Color _statusColor() {
    switch (order.status.toLowerCase()) {
      case 'confirmado':
      case 'confirmed':
      case '3':
      case 'done':
      case '4':
        return AppColors.success;
      case 'cancelado':
      case 'cancelled':
      case '5':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.orderDetail,
            arguments: order,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor().withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.displayStatus,
                      style: TextStyle(
                        color: _statusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormatter.format(order.orderDate),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${order.itemsCount} producto(s)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.format(order.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias para compatibilidad con referencias a OrderListScreen
typedef OrderListScreen = OrderHistoryScreen;
