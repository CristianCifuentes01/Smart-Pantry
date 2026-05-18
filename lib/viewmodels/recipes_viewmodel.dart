import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/meal_model.dart';
import '../data/models/meal_detail_model.dart';
import '../data/services/api_service.dart';
import '../data/services/local_db_service.dart';
import '../data/services/translation_service.dart';

class RecipesViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocalDbService _localDb = LocalDbService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TranslationService _translationService = TranslationService();

  List<MealModel> _recipes = [];
  List<MealModel> get recipes => _recipes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 1. Buscar recetas escribiendo el ingrediente manualmente
  Future<void> searchRecipes(String ingredient) async {
    if (ingredient.isEmpty) return;
    
    _setLoading(true);
    try {
      // 1. Traducir el ingrediente buscado al inglés para la API (si no es local)
      String englishIngredient = ingredient;
      final localTranslation = _translateIngredient(ingredient);
      
      if (localTranslation != ingredient.toLowerCase()) {
        englishIngredient = localTranslation;
      } else {
        englishIngredient = await _translationService.translate(ingredient, from: 'es', to: 'en');
      }

      print("Buscando ingrediente traducido: $englishIngredient (original: $ingredient)");
      final rawRecipes = await _apiService.getRecipesByIngredient(englishIngredient);
      
      // 2. Traducir los nombres de las recetas al español en paralelo y con caché para un rendimiento ultra rápido
      final prefs = await SharedPreferences.getInstance();
      List<Future<MealModel>> translationFutures = rawRecipes.map((meal) async {
        final cachedName = prefs.getString('trans_name_${meal.id}');
        if (cachedName != null) {
          return MealModel(id: meal.id, name: cachedName, imageUrl: meal.imageUrl);
        } else {
          final translatedName = await _translationService.translate(meal.name, from: 'en', to: 'es');
          await prefs.setString('trans_name_${meal.id}', translatedName);
          return MealModel(id: meal.id, name: translatedName, imageUrl: meal.imageUrl);
        }
      }).toList();

      _recipes = await Future.wait(translationFutures);
    } catch (e) {
      _recipes = [];
      print("Error buscando recetas: $e");
    }
    _setLoading(false);
  }

  // --- DICCIONARIO BÁSICO ESPAÑOL -> INGLÉS ---
  // TheMealDB funciona principalmente en inglés. Esto ayuda a traducir
  // ingredientes comunes que tengamos en la despensa.
  final Map<String, String> _ingredientDictionary = {
    'pollo': 'chicken',
    'carne': 'beef',
    'cerdo': 'pork',
    'arroz': 'rice',
    'frijol': 'beans',
    'frijoles': 'beans',
    'tomate': 'tomato',
    'cebolla': 'onion',
    'papa': 'potato',
    'papas': 'potato',
    'leche': 'milk',
    'queso': 'cheese',
    'huevo': 'egg',
    'huevos': 'egg',
    'pescado': 'seafood',
    'atun': 'tuna',
    'pasta': 'pasta',
    'ajo': 'garlic',
    'manzana': 'apple',
    'platano': 'banana',
    'banana': 'banana',
    'harina': 'flour',
    'pan': 'bread',
    'azucar': 'sugar',
    'sal': 'salt',
    'mantequilla': 'butter',
    'salchicha': 'sausage',
  };

  String _translateIngredient(String name) {
    String lowerName = name.toLowerCase();
    for (var key in _ingredientDictionary.keys) {
      if (lowerName.contains(key)) {
        return _ingredientDictionary[key]!;
      }
    }
    // Si no está en el diccionario, toma la primera palabra
    return lowerName.split(' ').first;
  }

  // 2. Magia (RF-15): Sugerir recetas con lo que ya hay en la despensa
  Future<void> suggestFromPantry() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      // Leemos rápidamente qué tienes guardado en el teléfono (SQLite)
      final myProducts = await _localDb.getProductsByUser(user.uid);

      if (myProducts.isEmpty) {
        _recipes = [];
        _setLoading(false);
        return;
      }

      // Buscamos recetas probando los ingredientes uno a uno hasta encontrar algo
      List<MealModel> foundRecipes = [];
      for (var product in myProducts) {
        String translated = _translateIngredient(product.name);
        foundRecipes = await _apiService.getRecipesByIngredient(translated);
        
        // Si encontramos recibimos contenido, detenemos la búsqueda y las mostramos
        if (foundRecipes.isNotEmpty) {
          break;
        }
      }
      
      // Traducir los nombres de las recetas sugeridas al español en paralelo y con caché
      final prefs = await SharedPreferences.getInstance();
      List<Future<MealModel>> translationFutures = foundRecipes.map((meal) async {
        final cachedName = prefs.getString('trans_name_${meal.id}');
        if (cachedName != null) {
          return MealModel(id: meal.id, name: cachedName, imageUrl: meal.imageUrl);
        } else {
          final translatedName = await _translationService.translate(meal.name, from: 'en', to: 'es');
          await prefs.setString('trans_name_${meal.id}', translatedName);
          return MealModel(id: meal.id, name: translatedName, imageUrl: meal.imageUrl);
        }
      }).toList();

      _recipes = await Future.wait(translationFutures);

    } catch (e) {
      print("Error sugiriendo recetas: $e");
      _recipes = [];
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Avisa a la pantalla que debe redibujarse
  }

  // --- RF-15: Acción Cocinar (Detalles de la receta) ---
  Future<MealDetailModel?> getMealDetail(String mealId) async {
    try {
      print("Obteniendo detalles para mealId: $mealId");
      
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('trans_meal_$mealId');
      
      if (cachedJson != null) {
        print("Cargando detalle de receta traducido desde caché local");
        final decoded = json.decode(cachedJson);
        return MealDetailModel.fromJsonTranslated(decoded);
      }

      final detail = await _apiService.getMealDetail(mealId);
      if (detail == null) return null;

      // Traducir todos los campos de detalles al español en paralelo
      final nameEsp = await _translationService.translate(detail.name, from: 'en', to: 'es');
      final categoryEsp = await _translationService.translate(detail.category, from: 'en', to: 'es');
      final areaEsp = await _translationService.translate(detail.area, from: 'en', to: 'es');
      final instructionsEsp = await _translationService.translate(detail.instructions, from: 'en', to: 'es');
      
      // Traducir los ingredientes en paralelo
      final ingredientsEsp = await Future.wait(
        detail.ingredients.map((ing) => _translationService.translate(ing, from: 'en', to: 'es'))
      );

      final translatedDetail = MealDetailModel(
        id: detail.id,
        name: nameEsp,
        imageUrl: detail.imageUrl,
        category: categoryEsp,
        area: areaEsp,
        instructions: instructionsEsp,
        ingredients: ingredientsEsp,
      );

      // Guardar en la caché local para no consumir cuotas ni internet en futuras visitas
      await prefs.setString('trans_meal_$mealId', json.encode(translatedDetail.toJsonTranslated()));

      return translatedDetail;
    } catch (e) {
      print("Excepción en getMealDetail: $e");
      return null;
    }
  }

  // --- RF-16: Favoritos en Recetas ---
  Future<bool> isFavorite(String mealId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('fav_$mealId') ?? false;
  }

  Future<void> toggleFavorite(String mealId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getBool('fav_$mealId') ?? false;
    await prefs.setBool('fav_$mealId', !current);
    notifyListeners(); // Forzar actualización de UI en las tarjetas
  }
}