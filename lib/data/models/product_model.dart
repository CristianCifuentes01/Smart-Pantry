class ProductModel {
  final String id;
  final String barcode;
  final String name;
  final String imageUrl;
  final DateTime entryDate;
  final DateTime expiryDate;
  final int quantity;
  final bool isConsumed;

  ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    required this.imageUrl,
    required this.entryDate,
    required this.expiryDate,
    this.quantity = 1,
    this.isConsumed = false,
  });

  // Convertir de JSON (Firebase/API) a Objeto Dart
  factory ProductModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ProductModel(
      id: documentId,
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? 'Producto Desconocido',
      imageUrl: json['imageUrl'] ?? '',
      entryDate: DateTime.parse(json['entryDate']),
      expiryDate: DateTime.parse(json['expiryDate']),
      quantity: json['quantity'] ?? 1,
      isConsumed: json['isConsumed'] ?? false,
    );
  }

  // Convertir de Objeto Dart a JSON (Para guardar en Firebase)
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'imageUrl': imageUrl,
      'entryDate': entryDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'isConsumed': isConsumed,
    };
  }
}
