import 'package:flutter/material.dart';

class ProductParseRequest {
  final String barcode;
  final String? imageBase64;
  
  ProductParseRequest({required this.barcode, this.imageBase64});
  
  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    if (imageBase64 != null) 'image_base64': imageBase64,
  };
}

class ProductParseResponse {
  final bool success;
  final String gtin;
  final Map<String, dynamic> productData;
  final String source;
  final String? message;
  
  ProductParseResponse({
    required this.success,
    required this.gtin,
    required this.productData,
    required this.source,
    this.message,
  });
  
  factory ProductParseResponse.fromJson(Map<String, dynamic> json) {
    return ProductParseResponse(
      success: json['success'],
      gtin: json['gtin'],
      productData: json['product_data'] as Map<String, dynamic>,
      source: json['source'],
      message: json['message'],
    );
  }
}

// Modèles pour le résultat final (EcoScore)
class TotalImpacts {
  final double co2G;
  final double waterL;
  final double energyMJ;
  
  TotalImpacts({
    required this.co2G,
    required this.waterL,
    required this.energyMJ,
  });
  
  factory TotalImpacts.fromJson(Map<String, dynamic> json) {
    return TotalImpacts(
      co2G: (json['co2_g'] ?? 0.0).toDouble(),
      waterL: (json['water_L'] ?? json['water_l'] ?? 0.0).toDouble(),
      energyMJ: (json['energy_MJ'] ?? json['energy_mj'] ?? 0.0).toDouble(),
    );
  }
}

class IngredientImpact {
  final String ingredient;
  final double massG;
  final double co2G;
  final double waterL;
  final double energyMJ;
  final bool missingFactor;
  
  IngredientImpact({
    required this.ingredient,
    required this.massG,
    required this.co2G,
    required this.waterL,
    required this.energyMJ,
    required this.missingFactor,
  });
  
  factory IngredientImpact.fromJson(Map<String, dynamic> json) {
    return IngredientImpact(
      ingredient: json['ingredient'] ?? '',
      massG: (json['mass_g'] ?? 0.0).toDouble(),
      co2G: (json['co2_g'] ?? 0.0).toDouble(),
      waterL: (json['water_L'] ?? json['water_l'] ?? 0.0).toDouble(),
      energyMJ: (json['energy_MJ'] ?? json['energy_mj'] ?? 0.0).toDouble(),
      missingFactor: json['missing_factor'] ?? false,
    );
  }
}

class EcoScoreResponse {
  final int scoreId;
  final String productName;
  final double ecoScoreNumeric;
  final String ecoScoreLetter;
  final double confidence;
  final Map<String, double> impactsScores;
  final TotalImpacts totalImpacts;
  final Map<String, String> explanations;
  
  EcoScoreResponse({
    required this.scoreId,
    required this.productName,
    required this.ecoScoreNumeric,
    required this.ecoScoreLetter,
    required this.confidence,
    required this.impactsScores,
    required this.totalImpacts,
    required this.explanations,
  });
  
  factory EcoScoreResponse.fromJson(Map<String, dynamic> json) {
    return EcoScoreResponse(
      scoreId: json['score_id'] ?? 0,
      productName: json['product_name'] ?? '',
      ecoScoreNumeric: (json['eco_score_numeric'] ?? 0.0).toDouble(),
      ecoScoreLetter: json['eco_score_letter'] ?? 'E',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      impactsScores: Map<String, double>.from(
        (json['impacts_scores'] ?? {}).map(
          (key, value) => MapEntry(key, (value ?? 0.0).toDouble()),
        ),
      ),
      totalImpacts: TotalImpacts.fromJson(json['total_impacts'] ?? {}),
      explanations: Map<String, String>.from(json['explanations'] ?? {}),
    );
  }
  
  // Méthode pour obtenir la couleur du score
  Color getScoreColor() {
    if (ecoScoreNumeric >= 90) return Colors.green;
    if (ecoScoreNumeric >= 75) return Colors.lightGreen;
    if (ecoScoreNumeric >= 60) return Colors.yellow;
    if (ecoScoreNumeric >= 40) return Colors.orange;
    return Colors.red;
  }
}