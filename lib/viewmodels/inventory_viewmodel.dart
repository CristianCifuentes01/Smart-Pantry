import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../data/repositories/inventory_repository.dart';

enum SortType { dateAsc, nameAsc, entryDateDesc }

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
      _applySorting();
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

  // Método para actualizar un producto (RF-13)
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _repository.updateProduct(product);
    } catch (e) {
      print("Error al actualizar (ViewModel): $e");
      rethrow;
    }
  }

  // --- RF-06 LÓGICA DE ORDENAMIENTO ---
  SortType _currentSort = SortType.dateAsc;
  SortType get currentSort => _currentSort;

  void setSortType(SortType type) {
    _currentSort = type;
    _applySorting();
    notifyListeners();
  }

  void _applySorting() {
    switch (_currentSort) {
      case SortType.dateAsc:
        _products.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case SortType.nameAsc:
        _products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortType.entryDateDesc:
        _products.sort((a, b) => b.entryDate.compareTo(a.entryDate));
        break;
    }
  }

  // --- RF-04 CONTADORES DASHBOARD ---
  int get urgentCount => _products.where((p) {
    final days = p.expiryDate.difference(DateTime.now()).inDays;
    return days <= 2; // Incluye vencidos (<0) y críticos (0-2)
  }).length;

  int get watchCount => _products.where((p) {
    final days = p.expiryDate.difference(DateTime.now()).inDays;
    return days > 2 && days <= 5;
  }).length;

  int get freshCount => _products.where((p) {
    final days = p.expiryDate.difference(DateTime.now()).inDays;
    return days > 5;
  }).length;
}
