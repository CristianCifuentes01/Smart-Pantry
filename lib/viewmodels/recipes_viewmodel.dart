import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/meal_model.dart';
import '../data/models/meal_detail_model.dart';
import '../data/services/api_service.dart';
import '../data/services/local_db_service.dart';

class RecipesViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocalDbService _localDb = LocalDbService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<MealModel> _recipes = [];
  List<MealModel> get recipes => _recipes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 1. Buscar recetas escribiendo el ingrediente manualmente
  Future<void> searchRecipes(String ingredient) async {
    if (ingredient.isEmpty) return;
    
    _setLoading(true);
    try {
      _recipes = await _apiService.getRecipesByIngredient(ingredient);
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
      
      _recipes = foundRecipes;

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
      final detail = await _apiService.getMealDetail(mealId);
      return detail;
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