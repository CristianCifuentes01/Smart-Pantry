import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/services/api_service.dart';

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
    setState(() => _isScanning = false); // Pausar escáner

    // Mostrar mensaje de carga
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Buscando producto...')));

    // Llamar a la API [cite: 104]
    final product = await _apiService.getProduct(code);

    if (!mounted) return; // Seguridad de Flutter

    // Mostrar resultado
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga a usar el botón para cerrar
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
              setState(() => _isScanning = true); // Reactivar escáner
            },
            child: const Text('Seguir Escaneando'),
          ),
        ],
      ),
    );
  }
}
