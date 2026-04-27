import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal_model.dart'; // NUEVO: Importamos el modelo de recetas
import '../models/meal_detail_model.dart';

class ApiService {
  
  // ==========================================
  // 1. MÓDULO DE ESCÁNER (OpenFoodFacts)
  // ==========================================
  // Documentación: 4.1 Servicio de Escaneo
  Future<Map<String, dynamic>?> getProduct(String barcode) async {
    // 1. Construimos la URL con el código escaneado
    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 2. Verificamos si el producto existe (status == 1)
        if (data['status'] == 1) {
          return {
            'name': data['product']['product_name'] ?? 'Nombre desconocido',
            'image': data['product']['image_url'] ?? '',
          };
        }
      }
    } catch (e) {
      print("Error conectando a la API de OpenFoodFacts: $e");
    }
    return null; // Si falla o no existe
  }


  // ==========================================
  // 2. MÓDULO DE RECETAS (TheMealDB)
  // ==========================================
  static const String _mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // RF-14: Buscar recetas sugeridas por ingrediente
  Future<List<MealModel>> getRecipesByIngredient(String ingredient) async {
    try {
      final url = Uri.parse('$_mealDbBaseUrl/filter.php?i=$ingredient');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Si la API no encuentra nada, devuelve una lista vacía
        if (data['meals'] == null) {
          return []; 
        }

        // Convertimos la lista de JSONs a una lista de objetos MealModel
        return (data['meals'] as List)
            .map((mealJson) => MealModel.fromJson(mealJson))
            .toList();
      } else {
        throw Exception('Error de servidor al buscar recetas');
      }
    } catch (e) {
      print("Error en ApiService (TheMealDB): $e");
      return []; // Si falla la red, evitamos que la app se caiga
    }
  }

  // RF-15: Obtener detalles e instrucciones de una receta
  Future<MealDetailModel?> getMealDetail(String mealId) async {
    try {
      final url = Uri.parse('$_mealDbBaseUrl/lookup.php?i=$mealId');
      print("Consultando detalle: $url");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return MealDetailModel.fromJson(data['meals'][0]);
        } else {
          print("No se encontraron platos para el ID: $mealId");
        }
      } else {
        print("Error de API: Código ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción en ApiService.getMealDetail: $e");
    }
    return null;
  }
}