class ProductModel {
  String? id;
  String? userId;
  final String barcode;
  final String name;
  final String imageUrl;
  final DateTime entryDate; // NUEVO: Fecha de registro
  final DateTime expiryDate;
  int synced; // NUEVO: Bandera de sincronización para SQLite (0 = no, 1 = sí)

  ProductModel({
    this.id,
    this.userId,
    required this.barcode,
    required this.name,
    required this.imageUrl,
    required this.entryDate, // NUEVO: Lo pedimos en el constructor
    required this.expiryDate,
    this.synced = 0, // Por defecto no está sincronizado
  });

  // Para enviar a Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'barcode': barcode,
      'name': name,
      'imageUrl': imageUrl,
      'entryDate': entryDate.toIso8601String(), // NUEVO: Lo preparamos para la nube
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  // Para enviar a SQLite localmente
  Map<String, dynamic> toLocalMap() {
    var map = toMap();
    map['id'] = id; // En local SÍ guardamos el ID como clave primaria
    map['synced'] = synced;
    return map;
  }

  // Para recibir de Firebase
  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      userId: map['userId'],
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? 'Desconocido',
      imageUrl: map['imageUrl'] ?? '',
      // NUEVO: Lo leemos de Firebase. Le ponemos una validación por si
      // lee un producto viejo que guardamos ayer y no tenía esta fecha.
      entryDate: map['entryDate'] != null
          ? DateTime.parse(map['entryDate'])
          : DateTime.now(),
      expiryDate: DateTime.parse(map['expiryDate']),
      synced: map.containsKey('synced') ? map['synced'] : 1, // Si viene de FB, asumimos que está sincronizado (1)
    );
  }
}
