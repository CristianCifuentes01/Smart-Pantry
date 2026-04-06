import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/models/product_model.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final ApiService _apiService = ApiService();
  bool _isScanning = true; // Para evitar escanear 50 veces el mismo código

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Producto')),
      body: MobileScanner(
        onDetect: (capture) {
          if (!_isScanning) return;

          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              // ¡Código detectado! Pausamos y buscamos [cite: 103]
              _onCodeDetected(barcode.rawValue!);
              break;
            }
          }
        },
      ),
    );
  }

  void _onCodeDetected(String code) async {
    setState(() => _isScanning = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Buscando producto...')));

    final product = await _apiService.getProduct(code);
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(product != null ? '¡Encontrado!' : 'No encontrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Código: $code'),
            const SizedBox(height: 10),
            if (product != null) ...[
              Text(
                product['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (product['image'] != '')
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.network(product['image'], height: 100),
                ),
            ] else
              const Text('Este producto no está en la base de datos.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isScanning = true);
            },
            child: const Text('Cancelar'),
          ),
          if (product != null)
            ElevatedButton(
              onPressed: () async {
                // 1. Mostrar el calendario nativo
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(
                    const Duration(days: 7),
                  ), // Por defecto 1 semana
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(
                    const Duration(days: 1825),
                  ), // Hasta 5 años
                );

                if (pickedDate != null) {
                  // 2. Crear el modelo
                  final newProduct = ProductModel(
                    id: '', // ID temporal, Firestore generará uno nuevo
                    barcode: code,
                    name: product!['name'],
                    imageUrl: product['image'],
                    entryDate: DateTime.now(),
                    expiryDate: pickedDate,
                  );

                  // 3. Guardar en Firebase
                  try {
                    await InventoryRepository().addProduct(newProduct);
                    if (mounted) {
                      Navigator.pop(ctx); // Cierra el diálogo
                      Navigator.pop(context); // Vuelve a la pantalla principal
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Producto guardado en la despensa!'),
                        ),
                      );
                    }
                  } catch (e) {
                    print("Error: $e");
                    if (context.mounted) {
                      Navigator.pop(ctx); // Cierra el diálogo
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Asignar Fecha y Guardar'),
            ),
        ],
      ),
    );
  }
}
