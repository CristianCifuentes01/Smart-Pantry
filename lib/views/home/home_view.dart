import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import '../../core/utils/product_utils.dart';
import '../scanner/scanner_view.dart';
import '../product_detail/product_detail_view.dart';
import 'package:intl/intl.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryViewModel>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Despensa')),
      body: Consumer<InventoryViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // --- RF-04 CONTADORES DASHBOARD ---
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCounter('Urgente', viewModel.urgentCount, Colors.red),
                    _buildCounter('Vigilancia', viewModel.watchCount, Colors.orange),
                    _buildCounter('Fresco', viewModel.freshCount, Colors.green),
                  ],
                ),
              ),

              // --- RF-06 FILTROS DE ORDENAMIENTO ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Inventario',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<SortType>(
                      value: viewModel.currentSort,
                      icon: const Icon(Icons.sort),
                      underline: Container(), // Sin línea debajo
                      onChanged: (SortType? newValue) {
                        if (newValue != null) {
                          viewModel.setSortType(newValue);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: SortType.dateAsc,
                          child: Text('Vencimiento'),
                        ),
                        DropdownMenuItem(
                          value: SortType.nameAsc,
                          child: Text('Nombre (A-Z)'),
                        ),
                        DropdownMenuItem(
                          value: SortType.entryDateDesc,
                          child: Text('Recientes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- LISTA DE PRODUCTOS ---
              Expanded(
                child: viewModel.products.isEmpty
                    ? const Center(
                        child: Text('Tu despensa está vacía. ¡Escanea algo!'),
                      )
                    : ListView.builder(
                        itemCount: viewModel.products.length,
                        itemBuilder: (context, index) {
                          final product = viewModel.products[index];
                          final statusColor = ProductUtils.getStatusColor(
                            product.expiryDate,
                          );
                          final formattedDate = DateFormat(
                            'dd MMM yyyy',
                          ).format(product.expiryDate);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: statusColor, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: product.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product.imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 50),
                                      ),
                                    )
                                  : const Icon(Icons.fastfood, size: 50),
                              title: Text(
                                product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Vence: $formattedDate\nCódigo: ${product.barcode}',
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailView(product: product),
                                  ),
                                );
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  _confirmDelete(context, viewModel, product);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerView()),
          );
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear'),
      ),
    );
  }

  Widget _buildCounter(String label, int count, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, InventoryViewModel viewModel, product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Consumir producto?'),
        content: Text(
          '¿Seguro que deseas eliminar "${product.name}" de tu despensa?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                await viewModel.deleteProduct(product.id!);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Producto consumido y eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
