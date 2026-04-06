import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NUEVO: Importamos Auth
import '../models/product_model.dart';

class InventoryRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'pantry_items',
  );

  // NUEVO: Instancia para saber quién está conectado
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addProduct(ProductModel product) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("No hay usuario autenticado");

      // Antes de guardar, le inyectamos el ID del usuario al producto
      product.userId = user.uid;

      await _collection.add(product.toMap());
      print("Producto guardado exitosamente");
    } catch (e) {
      print("Error guardando producto: $e");
      throw Exception("No se pudo guardar el producto");
    }
  }

  Stream<List<ProductModel>> getProducts() {
    final User? user = _auth.currentUser;
    // Si no hay sesión, devolvemos una lista vacía para que no colapse
    if (user == null) return const Stream.empty();

    // NUEVO: Agregamos un filtro (.where) a la consulta de Firebase
    return _collection
        .where('userId', isEqualTo: user.uid) // Solo trae MIS productos
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // Método para eliminar un producto
  Future<void> deleteProduct(String productId) async {
    try {
      // Buscamos el documento por su ID y lo borramos
      await _collection.doc(productId).delete();
      print("Producto eliminado exitosamente");
    } catch (e) {
      print("Error eliminando producto: $e");
      throw Exception("No se pudo eliminar el producto");
    }
  }
}
