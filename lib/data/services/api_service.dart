import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Documentación: 4.1 Servicio de Escaneo
  Future<Map<String, dynamic>?> getProduct(String barcode) async {
    // 1. Construimos la URL con el código escaneado [cite: 69]
    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 2. Verificamos si el producto existe (status == 1) [cite: 74]
        if (data['status'] == 1) {
          return {
            'name': data['product']['product_name'] ?? 'Nombre desconocido',
            'image': data['product']['image_url'] ?? '',
          };
        }
      }
    } catch (e) {
      print("Error conectando a la API: $e");
    }
    return null; // Si falla o no existe
  }
}
