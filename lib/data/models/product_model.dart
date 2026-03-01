class ProductModel {
  String? id;
  final String barcode;
  final String name;
  final String imageUrl;
  final DateTime entryDate;
  final DateTime expiryDate;

  ProductModel({
    this.id,
    required this.barcode,
    required this.name,
    required this.imageUrl,
    required this.entryDate,
    required this.expiryDate,
  });

  // Para enviar a Firebase
  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'imageUrl': imageUrl,
      'entryDate': entryDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  // Para recibir de Firebase
  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? 'Desconocido',
      imageUrl: map['imageUrl'] ?? '',
      entryDate: map['entryDate'] != null 
          ? DateTime.parse(map['entryDate']) 
          : DateTime.now(),
      expiryDate: DateTime.parse(map['expiryDate']),
    );
  }
}
