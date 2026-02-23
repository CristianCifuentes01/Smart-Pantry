import 'package:flutter/material.dart';
import '../data/models/product_model.dart';

class InventoryViewModel extends ChangeNotifier {
  // Lista de productos (Estado)
  List<ProductModel> _products = [];
  bool _isLoading = false;

  // Getters para que la UI lea los datos
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  // Lógica: Simulación de carga (Luego conectaremos Firebase aquí)
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners(); // Avisa a la UI que muestre el spinner de carga

    await Future.delayed(Duration(seconds: 2)); // Simula espera de red

    // Datos de prueba
    _products = [
      ProductModel(
        id: '1',
        barcode: '770123',
        name: 'Leche Deslactosada',
        imageUrl: 'https://world.openfoodfacts.org/images/products/generic.jpg',
        entryDate: DateTime.now(),
        expiryDate: DateTime.now().add(Duration(days: 3)), // Vence en 3 días
      ),
    ];

    _isLoading = false;
    notifyListeners(); // Avisa a la UI que ya hay datos
  }
  
  // Lógica del Semáforo (Tu requerimiento clave)
  Color getStatusColor(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return Colors.red;        // Vencido
    if (daysLeft <= 2) return Colors.orange;    // Crítico
    if (daysLeft <= 5) return Colors.yellow;    // Atención
    return Colors.green;                        // Fresco
  }
}
