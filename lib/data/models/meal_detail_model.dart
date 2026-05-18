class MealDetailModel {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String area;
  final String instructions;
  final List<String> ingredients;

  MealDetailModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.area,
    required this.instructions,
    required this.ingredients,
  });

  factory MealDetailModel.fromJson(Map<String, dynamic> json) {
    List<String> ingredientsList = [];
    
    // TheMealDB API uses keys like strIngredient1 to strIngredient20
    for (int i = 1; i <= 20; i++) {
      String? ingredient = json['strIngredient$i'];
      String? measure = json['strMeasure$i'];
      
      if (ingredient != null && ingredient.trim().isNotEmpty) {
        String item = measure != null && measure.trim().isNotEmpty
            ? '${measure.trim()} ${ingredient.trim()}'
            : ingredient.trim();
        ingredientsList.add(item);
      }
    }

    return MealDetailModel(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'Receta sin nombre',
      imageUrl: json['strMealThumb'] ?? '',
      category: json['strCategory'] ?? 'Desconocida',
      area: json['strArea'] ?? 'Desconocida',
      instructions: json['strInstructions'] ?? 'Sin instrucciones.',
      ingredients: ingredientsList,
    );
  }

  // Constructor para reconstruir el modelo a partir de datos ya traducidos y guardados en caché
  factory MealDetailModel.fromJsonTranslated(Map<String, dynamic> json) {
    return MealDetailModel(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'Receta sin nombre',
      imageUrl: json['strMealThumb'] ?? '',
      category: json['strCategory'] ?? 'Desconocida',
      area: json['strArea'] ?? 'Desconocida',
      instructions: json['strInstructions'] ?? 'Sin instrucciones.',
      ingredients: List<String>.from(json['ingredients'] ?? []),
    );
  }

  // Convierte el modelo a un mapa JSON optimizado para almacenar la versión traducida localmente
  Map<String, dynamic> toJsonTranslated() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strMealThumb': imageUrl,
      'strCategory': category,
      'strArea': area,
      'strInstructions': instructions,
      'ingredients': ingredients,
    };
  }
}
