import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import '../../core/utils/product_utils.dart';
import '../../data/services/notification_service.dart'; // Para notificaciones (RF-12)

class ProductDetailView extends StatefulWidget {
  final ProductModel product;

  const ProductDetailView({super.key, required this.product});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  late TextEditingController _nameController;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _expiryDate = widget.product.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = ProductUtils.getStatusColor(_expiryDate);
    final statusText = ProductUtils.getStatusText(_expiryDate);
    final daysText = ProductUtils.getDaysLeftText(_expiryDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Producto'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.urgent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.urgent.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.urgent,
                size: 18,
              ),
            ),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen del producto ──
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: widget.product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          widget.product.imageUrl,
                          height: 180,
                          width: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.fastfood,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.fastfood,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Nombre del producto (editable) ──
            Text(
              'Nombre del Producto',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // ── Tarjeta de Estado ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Icon(
                      statusText == 'Fresco'
                          ? Icons.check_circle_outline
                          : statusText == 'Atención'
                              ? Icons.visibility_outlined
                              : Icons.warning_amber_rounded,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          daysText,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Info Cards ──
            _buildInfoTile(
              icon: Icons.calendar_today_outlined,
              title: 'Fecha de Vencimiento',
              value: DateFormat('dd MMM yyyy').format(_expiryDate),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar, color: AppColors.primary, size: 22),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() {
                      _expiryDate = picked;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            _buildInfoTile(
              icon: Icons.qr_code,
              title: 'Código de Barras',
              value: widget.product.barcode.isEmpty ? 'N/A' : widget.product.barcode,
            ),

            const SizedBox(height: 32),

            // ── Botón Guardar ──
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_outlined),
              label: const Text(
                'GUARDAR CAMBIOS',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),

            // RF-12: Probar la notificación individual
            OutlinedButton.icon(
              onPressed: () async {
                await NotificationService()
                    .showInstantTestNotification(_nameController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notificación de prueba enviada'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('PROBAR ALERTA'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Seguro que deseas eliminar "${widget.product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.urgent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Cierra diálogo
              try {
                await Provider.of<InventoryViewModel>(context, listen: false)
                    .deleteProduct(widget.product.id!);
                if (context.mounted) {
                  Navigator.pop(context); // Vuelve a Home
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Producto eliminado'),
                        backgroundColor: AppColors.urgent),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'), backgroundColor: AppColors.urgent),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    final updatedProduct = ProductModel(
      id: widget.product.id,
      userId: widget.product.userId,
      barcode: widget.product.barcode,
      name: _nameController.text.trim(),
      imageUrl: widget.product.imageUrl,
      entryDate: widget.product.entryDate,
      expiryDate: _expiryDate,
      synced: widget.product.synced,
    );

    try {
      await Provider.of<InventoryViewModel>(context, listen: false)
          .updateProduct(updatedProduct);
      if (mounted) {
        Navigator.pop(context); // Vuelve a Home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Producto actualizado'),
              backgroundColor: AppColors.safe),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.urgent),
        );
      }
    }
  }
}
