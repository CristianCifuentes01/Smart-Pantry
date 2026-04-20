class MealModel {
  final String id;
  final String name;
  final String imageUrl;

  MealModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  // Constructor que convierte el JSON de la API a nuestro objeto Dart
  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'Receta sin nombre',
      imageUrl: json['strMealThumb'] ?? '',
    );
  }
}