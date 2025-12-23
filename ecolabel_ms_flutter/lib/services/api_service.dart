import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  // Utilisez votre IP Wi-Fi
  static const String baseUrl = 'http://192.168.11.229:8080';
  Future<ProductParseResponse> parseProduct({
    required String barcode,
    String? imageBase64,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/PARSER-PRODUIT/product/parse');
      print('🔗 Requête vers: $url');
      print('📤 Body: ${jsonEncode({'barcode': barcode})}');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': barcode,
          if (imageBase64 != null) 'image_base64': imageBase64,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Timeout après 30 secondes');
          throw Exception('Timeout: La requête a pris plus de 30 secondes');
        },
      );
      
      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body (premiers 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');
      
      if (response.statusCode == 200) {
        print('✅ Parsing de la réponse...');
        final parsed = ProductParseResponse.fromJson(jsonDecode(response.body));
        print('✅ Réponse parsée avec succès');
        return parsed;
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Erreur complète: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Nouvelle méthode pour parser depuis une image avec nom et poids
  Future<ProductParseResponse> parseProductFromImage({
    required String imageBase64,
    required String productName,
    required String productWeight,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/PARSER-PRODUIT/product/parse-from-image');
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

  // Méthode pour extraire les ingrédients avec NLP et obtenir le score complet
  Future<EcoScoreResponse> extractNLPWithScore({
    required String text,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/NLP-INGREDIENTS/nlp/extract');
      print('🔗 Requête NLP vers: $url');
      print('📝 Texte envoyé: $text');
      
      final requestBody = {
        'text': text,
      };
      print('📤 Body JSON: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('⏱️ Timeout NLP après 60 secondes');
          throw Exception('Timeout: La requête NLP a pris plus de 60 secondes');
        },
      );
      
      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Headers: ${response.headers}');
      print('📦 Response Body (raw): ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
          print('✅ JSON décodé avec succès');
          print('📊 Score ID: ${jsonResponse['score_id']}');
          print('📊 Product Name: ${jsonResponse['product_name']}');
          print('📊 Eco Score: ${jsonResponse['eco_score_numeric']} (${jsonResponse['eco_score_letter']})');
          
          return EcoScoreResponse.fromJson(jsonResponse);
        } catch (parseError) {
          print('❌ Erreur de parsing JSON: $parseError');
          print('❌ Response body était: ${response.body}');
          throw Exception('Erreur de parsing de la réponse: $parseError. Réponse: ${response.body}');
        }
      } else {
        final errorMessage = 'Erreur HTTP ${response.statusCode}: ${response.body}';
        print('❌ $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Erreur NLP complète: $e');
      print('❌ Type d\'erreur: ${e.runtimeType}');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur réseau NLP: $e');
    }
  }

  // Méthode pour extraire uniquement les ingrédients (sans score)
  Future<Map<String, dynamic>> extractNLP({
    required String text,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/NLP-INGREDIENTS/extract');
      print('🔗 Requête NLP extraction simple vers: $url');
      print('📝 Texte envoyé: $text');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
        }),
      );
      
      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur NLP: $e');
      throw Exception('Erreur réseau NLP: $e');
    }
  }

  // Méthode pour calculer le score écologique
  Future<EcoScoreResponse> computeEcoScore({
    required String productName,
    required Map<String, dynamic> ms3Data,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/SCORING/score/compute');
      print('🔗 Requête vers: $url');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ms3Data),
      );
      
      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return EcoScoreResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      throw Exception('Erreur réseau: $e');
    }
  }
}