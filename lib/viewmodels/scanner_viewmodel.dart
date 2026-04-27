import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/services/api_service.dart';

class ScannerViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final InventoryRepository _repository = InventoryRepository();

  bool _isLoading = false;
  bool _isScanning = true;
  bool _manualEntryMode = false;
  Map<String, dynamic>? _scannedData;
  DateTime? _selectedDate;

  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  bool get manualEntryMode => _manualEntryMode;
  Map<String, dynamic>? get scannedData => _scannedData;
  DateTime? get selectedDate => _selectedDate;

  void setScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void toggleManualEntry() {
    _manualEntryMode = !_manualEntryMode;
    _scannedData = null;
    notifyListeners();
  }

  Future<void> onBarcodeDetected(String code) async {
    if (!_isScanning) return;
    _isScanning = false;
    _isLoading = true;
    notifyListeners();

    try {
      final product = await _apiService.getProduct(code);
      if (product != null) {
        _scannedData = product;
        _scannedData!['barcode'] = code;
        _manualEntryMode = false;
      } else {
        _scannedData = {'barcode': code, 'name': '', 'image': ''};
        _manualEntryMode = true;
      }
    } catch (e) {
      print("Error in ScannerViewModel: $e");
      _manualEntryMode = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setQuickExpiry(int days) {
    _selectedDate = DateTime.now().add(Duration(days: days));
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<bool> addProduct(String name, String imageUrl, String barcode) async {
    if (_selectedDate == null) return false;

    final newProduct = ProductModel(
      id: '',
      barcode: barcode,
      name: name,
      imageUrl: imageUrl,
      entryDate: DateTime.now(),
      expiryDate: _selectedDate!,
    );

    try {
      await _repository.addProduct(newProduct);
      return true;
    } catch (e) {
      print("Error adding product: $e");
      return false;
    }
  }

  void reset() {
    _scannedData = null;
    _selectedDate = null;
    _isScanning = true;
    _manualEntryMode = false;
    notifyListeners();
  }
}
