import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  // Utilisez votre IP Wi-Fi
  static const String baseUrl = 'http://10.65.211.232:8000';
  
  Future<ProductParseResponse> parseProduct({
    required String barcode,
    String? imageBase64,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/product/parse');
      print('🔗 Requête vers: $url'); // Debug
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': barcode,
          if (imageBase64 != null) 'image_base64': imageBase64,
        }),
      );
      
      print('📡 Status Code: ${response.statusCode}'); // Debug
      print('📦 Response Body: ${response.body}'); // Debug
      
      if (response.statusCode == 200) {
        return ProductParseResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur: $e'); // Debug
      throw Exception('Erreur réseau: $e');
    }
  }
}