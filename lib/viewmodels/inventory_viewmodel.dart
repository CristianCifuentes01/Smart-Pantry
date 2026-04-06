import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../data/repositories/inventory_repository.dart';

class InventoryViewModel extends ChangeNotifier {
  final InventoryRepository _repository = InventoryRepository();

  // Lista de productos (Estado)
  List<ProductModel> _products = [];
  bool _isLoading = false;

  // Getters para que la UI lea los datos
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  // Lógica: Carga real desde Firebase
  Future<void> loadProducts() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners(); // Avisa a la UI que muestre el spinner de carga

    _repository.getProducts().listen((productsList) {
      _products = productsList;
      _isLoading = false;
      notifyListeners(); // Avisa a la UI que ya hay datos
    }, onError: (error) {
      print("Error cargando productos: $error");
      _isLoading = false;
      notifyListeners();
    });
  }
  
  // Lógica del Semáforo (Tu requerimiento clave)
  Color getStatusColor(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return Colors.red;        // Vencido
    if (daysLeft <= 2) return Colors.orange;    // Crítico
    if (daysLeft <= 5) return Colors.yellow;    // Atención
    return Colors.green;                        // Fresco
  }
  // Método para eliminar un producto
  Future<void> deleteProduct(String productId) async {
    try {
      await _repository.deleteProduct(productId);
    } catch (e) {
      print("Error al eliminar (ViewModel): $e");
      rethrow;
    }
  }
}
