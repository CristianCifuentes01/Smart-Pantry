import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/scanner_viewmodel.dart';
import 'package:intl/intl.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final TextEditingController _nameController = TextEditingController();
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _nameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScannerViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Escanear Producto'),
            actions: [
              IconButton(
                icon: Icon(viewModel.manualEntryMode ? Icons.qr_code : Icons.edit),
                onPressed: () {
                  viewModel.toggleManualEntry();
                  if (viewModel.manualEntryMode) {
                    _controller.stop();
                    _showAddProductSheet(context, viewModel, isManual: true);
                  } else {
                    _controller.start();
                  }
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  if (!viewModel.isScanning) return;

                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      // 1. Detener el escáner inmediatamente
                      _controller.stop();
                      
                      // 2. Notificar al viewmodel y mostrar la ventana
                      viewModel.onBarcodeDetected(barcode.rawValue!);
                      _showAddProductSheet(context, viewModel);
                      break;
                    }
                  }
                },
              ),
              // Guía visual del scanner
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (viewModel.isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddProductSheet(BuildContext context, ScannerViewModel viewModel, {bool isManual = false}) {
    // Si ya hay datos de un escaneo previo, los usamos
    if (!isManual && viewModel.scannedData != null) {
      _nameController.text = viewModel.scannedData!['name'] ?? '';
    } else if (isManual) {
      _nameController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Evitar cerrar por accidente y que la cámara quede pausada
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isManual ? 'Agregar Manualmente' : 'Producto Detectado',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (!isManual && viewModel.scannedData?['image'] != null && viewModel.scannedData?['image'] != '')
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      viewModel.scannedData!['image'],
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, size: 100),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_basket),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Fecha de Vencimiento:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Botones de selección rápida (RF-09)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _quickDateButton(context, viewModel, '3 días', 3),
                    const SizedBox(width: 8),
                    _quickDateButton(context, viewModel, '1 semana', 7),
                    const SizedBox(width: 8),
                    _quickDateButton(context, viewModel, '2 semanas', 14),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) viewModel.setSelectedDate(date);
                      },
                      icon: const Icon(Icons.calendar_month, color: Colors.green),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
              if (viewModel.selectedDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Seleccionado: ${DateFormat('dd/MM/yyyy').format(viewModel.selectedDate!)}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        viewModel.reset();
                        _controller.start();
                      },
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: viewModel.selectedDate == null || _nameController.text.isEmpty
                          ? null
                          : () async {
                              final success = await viewModel.addProduct(
                                _nameController.text,
                                viewModel.scannedData?['image'] ?? '',
                                viewModel.scannedData?['barcode'] ?? 'MANUAL',
                              );
                              if (success && context.mounted) {
                                Navigator.pop(context); // Cierra bottom sheet
                                Navigator.pop(context); // Vuelve al home
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('¡Producto agregado con éxito!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                viewModel.reset();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('GUARDAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ).then((_) {
      // Al cerrar por cualquier motivo, nos aseguramos de que el viewmodel sepa que puede volver a escanear
      // y reanudamos la cámara si no estamos en carga.
      if (!viewModel.isLoading) {
        viewModel.setScanning(true);
        _controller.start();
      }
    });
  }

  Widget _quickDateButton(BuildContext context, ScannerViewModel viewModel, String label, int days) {
    final bool isSelected = viewModel.selectedDate != null &&
        viewModel.selectedDate!.day == DateTime.now().add(Duration(days: days)).day;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) viewModel.setQuickExpiry(days);
      },
      selectedColor: Colors.green.withOpacity(0.2),
      checkmarkColor: Colors.green,
    );
  }
}
