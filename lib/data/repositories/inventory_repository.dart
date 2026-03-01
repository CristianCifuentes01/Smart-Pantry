import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class InventoryRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'pantry_items',
  );

  // Método addProduct(): Guardar el objeto en Firestore
  Future<void> addProduct(ProductModel product) async {
    try {
      await _collection.add(product.toMap());
      print("Producto guardado exitosamente");
    } catch (e) {
      print("Error guardando producto: $e");
      throw Exception("No se pudo guardar el producto");
    }
  }

  // Método getProducts(): Leer la lista en tiempo real
  Stream<List<ProductModel>> getProducts() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
