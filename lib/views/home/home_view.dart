import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import '../../core/utils/product_utils.dart';
import '../scanner/scanner_view.dart';
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
    // Usamos addPostFrameCallback para asegurarnos de que el context está disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Le pedimos al ViewModel que cargue los productos, sin escuchar cambios aquí.
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
          if (viewModel.products.isEmpty) {
            return const Center(
              child: Text('Tu despensa está vacía. ¡Escanea algo!'),
            );
          }

          final products = viewModel.products;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
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
                      ? Image.network(
                          product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.fastfood, size: 50),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Vence: $formattedDate\nCódigo: ${product.barcode}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      // 1. Mostrar diálogo de confirmación
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Consumir producto?'),
                          content: Text(
                            '¿Seguro que deseas eliminar "${product.name}" de tu despensa?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx), // Solo cierra la ventana
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () async {
                                try {
                                  // 2. Si dice que sí, llamamos al viewmodel
                                  // Usamos product.id! porque sabemos que viene de Firebase y tiene ID
                                  await viewModel.deleteProduct(product.id!);
                                  if (context.mounted) {
                                    Navigator.pop(ctx); // Cierra la ventana

                                    // Opcional: Mostrar un mensajito de éxito
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Producto consumido y eliminado'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(ctx); // Cierra la ventana en caso de error también para no atascar al usuario
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
                    },
                  ),
                ),
              );
            },
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
}
