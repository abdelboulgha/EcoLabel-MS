import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  // Utilisez votre IP Wi-Fi
  static const String baseUrl = 'http://192.168.1.12:8080/PARSER-PRODUIT/product/parse-from-image';
  
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

  // Nouvelle méthode pour parser depuis une image avec nom et poids
  Future<ProductParseResponse> parseProductFromImage({
    required String imageBase64,
    required String productName,
    required String productWeight,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/product/parse-from-image');
      print('🔗 Requête vers: $url');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': imageBase64,
          'product_name': productName,
          'product_weight_g': int.parse(productWeight),
        }),
      );
      
      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return ProductParseResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      throw Exception('Erreur réseau: $e');
    }
  }
}