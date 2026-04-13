import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product_model.dart';

class LocalDbService {
  // Patrón Singleton para asegurar que solo exista una conexión a la BD
  static final LocalDbService _instance = LocalDbService._internal();
  static Database? _database;

  factory LocalDbService() => _instance;

  LocalDbService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Busca la carpeta segura de la app en el celular
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'smartpantry.db');

    // Abre o crea la base de datos
    return await openDatabase(
      path,
      version: 3, // Subimos la versión a 3
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE pantry_items ADD COLUMN synced INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          try {
            await db.execute(
              'ALTER TABLE pantry_items ADD COLUMN entryDate TEXT DEFAULT ""',
            );
          } catch (e) {
            // Ignorar si la columna ya existe por alguna razón
          }
        }
      },
    );
  }

  // Se ejecuta solo la primera vez que se crea la BD
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pantry_items(
        id TEXT PRIMARY KEY,
        userId TEXT,
        barcode TEXT,
        name TEXT,
        imageUrl TEXT,
        entryDate TEXT,
        expiryDate TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // --- MÉTODOS CRUD LOCALES ---

  // 1. Insertar o actualizar producto
  Future<void> insertProduct(ProductModel product) async {
    final db = await database;
    await db.insert(
      'pantry_items',
      product.toLocalMap(), // NUEVO: Usamos toLocalMap para incluir ID y synced
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 2. Obtener productos de un usuario específico
  Future<List<ProductModel>> getProductsByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pantry_items',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      // Como a nivel local nosotros controlamos el ID, lo pasamos directamente
      return ProductModel.fromMap(maps[i], maps[i]['id'] ?? '');
    });
  }

  // 3. Eliminar producto local
  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('pantry_items', where: 'id = ?', whereArgs: [id]);
  }

  // 4. Obtener productos que no se han sincronizado con la nube (synced = 0)
  Future<List<ProductModel>> getUnsyncedProducts() async {
    final db = await database;
    final maps = await db.query(
      'pantry_items',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) {
      return ProductModel.fromMap(maps[i], maps[i]['id']?.toString() ?? '');
    });
  }

  // 5. Marcar una lista de IDs como sincronizados (synced = 1)
  Future<void> markAsSynced(List<String> ids) async {
    final db = await database;
    for (String id in ids) {
      await db.update(
        'pantry_items',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
