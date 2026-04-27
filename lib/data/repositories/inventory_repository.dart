import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // NUEVO: Importamos Connectivity
import '../models/product_model.dart';
import '../services/local_db_service.dart';
import '../services/notification_service.dart';

class InventoryRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection('pantry_items');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Instanciamos nuestro servicio de SQLite
  final LocalDbService _localDb = LocalDbService(); 

  InventoryRepository() {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        // Ejecuta RNF-03 al recuperar conexión
        syncLocalToFirestore();
      }
    });
  }

  // --- RNF-03 Sincronización Firebase ---
  Future<void> syncLocalToFirestore() async {
    final unsynced = await _localDb.getUnsyncedProducts();
    if (unsynced.isEmpty) return; // No hay nada pendiente

    print("🔄 Sincronizando ${unsynced.length} productos con la nube...");
    final batch = FirebaseFirestore.instance.batch();
    
    List<String> validIds = [];

    for (var product in unsynced) {
      // Ignorar e intentar limpiar productos corruptos que resulten de pruebas anteriores
      if (product.id == null || product.id!.isEmpty) {
        print("⚠️ Producto corrupto local sin ID ignorado (será purgado de la base local).");
        _localDb.database.then((db) => db.delete('pantry_items', where: 'id IS NULL OR id = ?', whereArgs: ['']));
        continue;
      }
      
      final docRef = _collection.doc(product.id);
      batch.set(docRef, product.toMap());
      validIds.add(product.id!);
    }

    if (validIds.isEmpty) return;

    try {
      await batch.commit(); // Batch write (escritura en lote) optimizada
      // Marca todos como synced=1
      await _localDb.markAsSynced(validIds);
      print("✅ Sincronización offline exitosa");
    } catch (e) {
      print("❌ Error en la sincronización batched: $e");
    }
  }

  // --- 1. AGREGAR PRODUCTO ---
  Future<void> addProduct(ProductModel product) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("No hay usuario autenticado");

    product.userId = user.uid;

    // A. Generamos un ID único si el producto no lo tiene
    if (product.id == null || product.id!.isEmpty) {
      product.id = _collection.doc().id; // Usamos el generador de Firebase
    }

    // B. Guardamos SIEMPRE en SQLite primero (Súper rápido, a prueba de fallos de red)
    product.synced = 0; // Se marca como no sincronizado por defecto
    await _localDb.insertProduct(product);
    print("✅ Guardado en SQLite (Local)");

    // C. Intentamos sincronizar todo de inmediato (Si falla, quedará pendiente)
    syncLocalToFirestore();
    // Programamos la alarma de caducidad
    await NotificationService().scheduleExpiryNotification(product);
  }

  // --- 2. LEER PRODUCTOS (Estrategia Cache-First) ---
  // Usamos async* para poder emitir (yield) múltiples veces en un mismo Stream
  Stream<List<ProductModel>> getProducts() async* {
    final User? user = _auth.currentUser;
    if (user == null) yield [];

    // A. Emitir inmediatamente lo que hay en SQLite (Carga en milisegundos)
    final localProducts = await _localDb.getProductsByUser(user!.uid);
    yield localProducts;

    // B. Escuchar la nube y actualizar SQLite silenciosamente
    yield* _collection
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final cloudProducts = snapshot.docs.map((doc) {
        final p = ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // Mientras leemos de la nube, actualizamos la base local para que 
        // la próxima vez que abramos la app sin internet, tengamos lo más reciente.
        _localDb.insertProduct(p); 
        
        return p;
      }).toList();
      
      return cloudProducts; // Emitimos los datos frescos de la nube a la vista
    });
  }

  // --- 3. ELIMINAR PRODUCTO ---
  Future<void> deleteProduct(String productId) async {
    // A. Borrar localmente al instante
    await _localDb.deleteProduct(productId);
    
    // Cancelar la notificación programada
    await NotificationService().cancelNotification(productId);
    
    // B. Intentar borrar en la nube
    try {
      await _collection.doc(productId).delete();
    } catch (e) {
      print("⚠️ Sin internet: Borrado local, pendiente en la nube.");
    }
  }

  // --- 4. ACTUALIZAR PRODUCTO (RF-13) ---
  Future<void> updateProduct(ProductModel product) async {
    // 1. Guardar localmente primero (offline-first)
    product.synced = 0;
    await _localDb.insertProduct(product); // insertProduct usa ConflictAlgorithm.replace
    
    // 2. Reprogramar notificación si la fecha cambió o se activó
    await NotificationService().cancelNotification(product.id!);
    await NotificationService().scheduleExpiryNotification(product);

    // 3. Intentar sincronizar a la nube
    syncLocalToFirestore();
  }
}