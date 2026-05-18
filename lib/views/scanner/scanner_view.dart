import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/scanner_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/skeleton_loader.dart';

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
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: IconButton(
                  icon: Icon(
                    viewModel.manualEntryMode ? Icons.qr_code : Icons.edit_outlined,
                    color: AppColors.primary,
                  ),
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
              // ── Guía visual del scanner ──
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Esquinas decorativas
                      ..._buildCornerDecorations(),
                    ],
                  ),
                ),
              ),
              // Texto guía debajo del marco
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: const Text(
                      'Apunta al código de barras',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              if (viewModel.isLoading)
                Container(
                  color: AppColors.background.withOpacity(0.7),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCornerDecorations() {
    const cornerSize = 24.0;
    const cornerWidth = 4.0;
    const color = AppColors.primary;

    return [
      // Top-left
      Positioned(
        top: -2, left: -2,
        child: Container(width: cornerSize, height: cornerWidth, color: color),
      ),
      Positioned(
        top: -2, left: -2,
        child: Container(width: cornerWidth, height: cornerSize, color: color),
      ),
      // Top-right
      Positioned(
        top: -2, right: -2,
        child: Container(width: cornerSize, height: cornerWidth, color: color),
      ),
      Positioned(
        top: -2, right: -2,
        child: Container(width: cornerWidth, height: cornerSize, color: color),
      ),
      // Bottom-left
      Positioned(
        bottom: -2, left: -2,
        child: Container(width: cornerSize, height: cornerWidth, color: color),
      ),
      Positioned(
        bottom: -2, left: -2,
        child: Container(width: cornerWidth, height: cornerSize, color: color),
      ),
      // Bottom-right
      Positioned(
        bottom: -2, right: -2,
        child: Container(width: cornerSize, height: cornerWidth, color: color),
      ),
      Positioned(
        bottom: -2, right: -2,
        child: Container(width: cornerWidth, height: cornerSize, color: color),
      ),
    ];
  }

  void _showAddProductSheet(BuildContext context, ScannerViewModel viewModel, {bool isManual = false}) {
    // Si ya hay datos de un escaneo previo, los usamos, sino limpiamos para recibir datos reactivos
    if (!isManual && viewModel.scannedData != null) {
      _nameController.text = viewModel.scannedData!['name'] ?? '';
    } else {
      _nameController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Evitar cerrar por accidente y que la cámara quede pausada
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (context) {
        return Consumer<ScannerViewModel>(
          builder: (context, viewModel, child) {
            // Actualizar reactivamente el controlador del nombre cuando termine de cargar
            if (!viewModel.isLoading && viewModel.scannedData != null && _nameController.text.isEmpty) {
              _nameController.text = viewModel.scannedData!['name'] ?? '';
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle ──
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Título ──
                  Text(
                    viewModel.isLoading
                        ? 'Buscando producto...'
                        : (isManual ? 'Agregar Manualmente' : 'Producto Detectado'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Imagen o Skeleton del producto ──
                  if (viewModel.isLoading)
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const SkeletonImageLoader(
                          height: 120,
                          width: 120,
                        ),
                      ),
                    )
                  else if (!isManual && viewModel.scannedData?['image'] != null && viewModel.scannedData?['image'] != '')
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: CachedNetworkImage(
                            imageUrl: viewModel.scannedData!['image'],
                            height: 120,
                            width: 120,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const SkeletonImageLoader(
                              height: 120,
                              width: 120,
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 120,
                              width: 120,
                              color: AppColors.surface,
                              child: const Icon(Icons.fastfood, size: 48, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),

                  // ── Campo nombre o Skeleton ──
                  Text(
                    'Nombre del Producto',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  if (viewModel.isLoading)
                    const SkeletonImageLoader(
                      width: double.infinity,
                      height: 50,
                    )
                  else
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ej: Leche entera',
                        prefixIcon: Icon(Icons.shopping_basket_outlined),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Fecha de Vencimiento ──
                  const Text(
                    'Fecha de Vencimiento',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Botones de selección rápida o Skeleton
                  if (viewModel.isLoading)
                    const SkeletonImageLoader(
                      width: double.infinity,
                      height: 40,
                    )
                  else
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
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: IconButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 7)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                );
                                if (date != null) viewModel.setSelectedDate(date);
                              },
                              icon: const Icon(Icons.calendar_month, color: AppColors.primary, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!viewModel.isLoading && viewModel.selectedDate != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          '📅 ${DateFormat('dd/MM/yyyy').format(viewModel.selectedDate!)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Botones de acción ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            viewModel.reset();
                            _controller.start();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('CANCELAR'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading || viewModel.selectedDate == null || _nameController.text.isEmpty
                              ? null
                              : () async {
                                  final success = await viewModel.addProduct(
                                    _nameController.text,
                                    viewModel.scannedData?['image'] ?? '',
                                    viewModel.scannedData?['barcode'] ?? 'MANUAL',
                                  );
                                  if (success && context.mounted) {
                                    Navigator.pop(context); // Cierra bottom sheet
                                    _showSuccessAnimation(context);
                                    
                                    Future.delayed(const Duration(milliseconds: 1500), () {
                                      if (context.mounted) {
                                        Navigator.pop(context); // Cierra dialogo de exito
                                        Navigator.pop(context); // Vuelve al home
                                      }
                                    });
                                    viewModel.reset();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                            disabledForegroundColor: AppColors.background.withOpacity(0.5),
                          ),
                          child: const Text(
                            'GUARDAR',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
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

  void _showSuccessAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppColors.safe,
            size: 100,
          ),
        ).animate()
         .scale(duration: 500.ms, curve: Curves.easeOutBack)
         .fadeIn(duration: 400.ms)
         .then(delay: 500.ms)
         .fadeOut(duration: 300.ms),
      ),
    );
  }

  Widget _quickDateButton(BuildContext context, ScannerViewModel viewModel, String label, int days) {
    final bool isSelected = viewModel.selectedDate != null &&
        viewModel.selectedDate!.day == DateTime.now().add(Duration(days: days)).day;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.background : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) viewModel.setQuickExpiry(days);
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
      checkmarkColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
    );
  }
}
