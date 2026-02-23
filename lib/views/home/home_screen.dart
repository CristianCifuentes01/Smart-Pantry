import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/inventory_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar productos al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryViewModel>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<InventoryViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Mi Despensa")),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: viewModel.products.length,
              itemBuilder: (context, index) {
                final product = viewModel.products[index];
                return Card(
                  // Usamos tu lógica de semáforo para el borde
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: viewModel.getStatusColor(product.expiryDate), 
                      width: 2
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.fastfood), // Aquí iría la imagen
                    title: Text(product.name),
                    subtitle: Text("Vence: ${product.expiryDate.toString().split(' ')[0]}"),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí navegaremos al escáner
          print("Abrir escáner");
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
