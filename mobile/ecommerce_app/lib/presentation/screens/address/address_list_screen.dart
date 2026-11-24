import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/infrastructure/models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/address/add_edit_address_modal.dart';
import '../../widgets/common/empty_view.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<AddressProvider>().loadAddresses();
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Dirección'),
        content: Text('¿Estás seguro de que deseas eliminar la dirección "${address.title}"?'),
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(this.context);
      final success = await this.context.read<AddressProvider>().deleteAddress(address.id);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Dirección eliminada exitosamente.'
                : 'No se pudo eliminar la dirección.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();
    final addresses = addressProvider.addresses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Direcciones'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(
          'Nueva Dirección',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => AddEditAddressModal.show(context),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<AddressProvider>().loadAddresses(),
          child: _buildBody(context, addressProvider, addresses),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AddressProvider provider,
    List<AddressModel> addresses,
  ) {
    if (provider.isLoading && addresses.isEmpty) {
      return const LoadingIndicator(message: 'Cargando direcciones...');
    }

    if (provider.status == ViewStatus.error && addresses.isEmpty) {
      return ErrorView(
        message: provider.errorMessage ?? 'Ocurrió un error al cargar las direcciones.',
        onRetry: () => provider.loadAddresses(),
      );
    }

    if (addresses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          const EmptyView(
            message: 'No tienes direcciones de entrega registradas.\nAgrega una para recibir tus compras.',
            icon: Icons.location_off_outlined,
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => AddEditAddressModal.show(context),
              icon: const Icon(Icons.add_location_alt_outlined, size: 20),
              label: const Text(
                'Agregar Dirección',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return _buildAddressCard(context, address);
      },
    );
  }

  Widget _buildAddressCard(BuildContext context, AddressModel address) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: address.isDefault
            ? const BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: address.isDefault
                        ? AppColors.primary.withAlpha(30)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: address.isDefault ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Predeterminada',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      AddEditAddressModal.show(context, address: address);
                    } else if (val == 'delete') {
                      _confirmDelete(context, address);
                    } else if (val == 'default') {
                      await context.read<AddressProvider>().setDefaultAddress(address.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Hacer predeterminada'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.signpost_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address.street,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_city_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${address.city}${address.stateOrProvince.isNotEmpty ? ", ${address.stateOrProvince}" : ""}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (address.reference != null && address.reference!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ref: ${address.reference}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  address.phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: () => AddEditAddressModal.show(context, address: address),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.error,
                  ),
                  onPressed: () => _confirmDelete(context, address),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
