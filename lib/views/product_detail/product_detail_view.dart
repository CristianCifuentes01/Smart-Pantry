import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    final daysLeft = _expiryDate.difference(DateTime.now()).inDays;
    String statusText = daysLeft < 0 ? 'Vencido' : 'Fresco';
    if (daysLeft >= 0 && daysLeft <= 2) {
      statusText = 'Crítico';
    } else if (daysLeft > 2 && daysLeft <= 5) {
      statusText = 'Atención';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Producto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: widget.product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        widget.product.imageUrl,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) =>
                            const Icon(Icons.fastfood, size: 100),
                      ),
                    )
                  : const Icon(Icons.fastfood, size: 100),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Estado',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$statusText ($daysLeft días)'),
              trailing: CircleAvatar(backgroundColor: statusColor, radius: 10),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha de Vencimiento',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_expiryDate)),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar, color: Colors.green),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
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
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Código de Barras',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(widget.product.barcode.isEmpty
                  ? 'N/A'
                  : widget.product.barcode),
              trailing: const Icon(Icons.qr_code),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('GUARDAR CAMBIOS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // RF-12: Probar la notificación individual
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
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
                icon: const Icon(Icons.notifications_active),
                label: const Text('PROBAR ALERTA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                        backgroundColor: Colors.redAccent),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
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
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
