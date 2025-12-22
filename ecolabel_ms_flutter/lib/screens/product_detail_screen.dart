import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/product.dart';
import '../services/api_service.dart';
import 'final_result_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductParseResponse product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isCalculatingScore = false;

  @override
  Widget build(BuildContext context) {
    final productData = widget.product.productData;
    
    // Afficher les données dans la console pour debug
    print('📦 Données reçues:');
    print(jsonEncode(productData));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Produit'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec GTIN
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            
            // Bouton pour voir le score écologique
            _buildEcoScoreButton(context),
            const SizedBox(height: 16),
            
            // Informations principales du produit
            _buildSectionTitle('📦 Informations du Produit'),
            if (productData['name'] != null && productData['name'].toString().isNotEmpty)
              _buildInfoCard(context, 'Nom du produit', productData['name'].toString(), Icons.shopping_bag),
            
            if (productData['brand'] != null && productData['brand'].toString().isNotEmpty)
              _buildInfoCard(context, 'Marque', productData['brand'].toString(), Icons.branding_watermark),
            
            if (productData['category'] != null && productData['category'].toString().isNotEmpty)
              _buildInfoCard(context, 'Catégorie', productData['category'].toString(), Icons.category),
            
            if (productData['netWeight_g'] != null)
              _buildInfoCard(
                context,
                'Poids net',
                '${productData['netWeight_g']} g',
                Icons.scale,
              ),
            
            if (productData['origin'] != null && productData['origin'].toString().isNotEmpty)
              _buildInfoCard(context, 'Origine', productData['origin'].toString(), Icons.public),
            
            // Ingrédients et composition
            if (productData['nlp_ingredients'] != null || 
                (productData['composition'] != null && productData['composition'].toString().isNotEmpty))
              _buildSectionTitle('🧪 Ingrédients et Composition'),
            
            // Ingrédients extraits par NLP (priorité)
            if (productData['nlp_ingredients'] != null)
              _buildNLPIngredientsCard(context, productData['nlp_ingredients']),
            
            // Composition complète
            if (productData['composition'] != null && productData['composition'].toString().isNotEmpty)
              _buildCompositionCard(context, productData['composition']),
            
            // Informations nutritionnelles
            if (productData['nutritional_info'] != null)
              _buildSectionTitle('🍎 Informations Nutritionnelles'),
            if (productData['nutritional_info'] != null)
              _buildNutritionCard(context, productData['nutritional_info']),
            
            // Emballage
            if (productData['packaging'] != null)
              _buildSectionTitle('📦 Emballage'),
            if (productData['packaging'] != null)
              _buildPackagingCard(context, productData['packaging']),
            
            // Toutes les autres données importantes
            _buildAllDataCard(context, productData),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code-barres (GTIN)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.gtin,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
                  label: Text('Source: ${widget.product.source}'),
                  backgroundColor: Colors.green.shade100,
                ),
                if (widget.product.success)
                  const Chip(
                    avatar: Icon(Icons.done, size: 18, color: Colors.green),
                    label: Text('Succès'),
                    backgroundColor: Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.green.shade700, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionCard(BuildContext context, dynamic composition) {
    String compositionText = composition.toString();
    bool isLong = compositionText.length > 150;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.list, color: Colors.orange, size: 24),
        ),
        title: const Text(
          'Composition Complète',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: isLong 
          ? const Text('Appuyez pour voir la composition complète', style: TextStyle(fontSize: 12))
          : null,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: SelectableText(
              compositionText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagingCard(BuildContext context, dynamic packaging) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2, color: Colors.blue, size: 24),
        ),
        title: const Text(
          'Informations d\'Emballage',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: packaging is Map
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: packaging.entries.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatKey(entry.key.toString()),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: _buildValueWidget(entry.value),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : SelectableText(
                    packaging.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(BuildContext context, dynamic nutritionalInfo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.restaurant, color: Colors.purple, size: 24),
        ),
        title: const Text(
          'Valeurs Nutritionnelles',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: nutritionalInfo is Map
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: nutritionalInfo.entries.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatKey(entry.key.toString()),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  entry.value.toString(),
                                  textAlign: TextAlign.end,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : SelectableText(
                    nutritionalInfo.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNLPIngredientsCard(BuildContext context, dynamic nlpIngredients) {
    List<String> ingredients = [];
    
    if (nlpIngredients is List) {
      ingredients = nlpIngredients.map((e) => e.toString()).toList();
    } else if (nlpIngredients is String) {
      ingredients = nlpIngredients.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    
    if (ingredients.isEmpty) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepOrange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.science, color: Colors.deepOrange, size: 24),
        ),
        title: const Text(
          'Ingrédients Identifiés',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${ingredients.length} ingrédient(s) détecté(s) par analyse intelligente',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ingredients.map((ingredient) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepOrange.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.shade50,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.deepOrange.shade700),
                      const SizedBox(width: 6),
                      Text(
                        ingredient,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.deepOrange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDataCard(BuildContext context, Map<String, dynamic> productData) {
    // Afficher toutes les autres clés qui n'ont pas été affichées
    final displayedKeys = {
      'name', 'brand', 'category', 'composition', 'origin', 'packaging', 
      'nutritional_info', 'gtin', 'raw_data', 'raw_text', 'netWeight_g',
      'nlp_ingredients', 'nlp_product_name', 'nlp_weight'
    };
    final otherKeys = productData.keys
        .where((key) => !displayedKeys.contains(key) && 
                       productData[key] != null && 
                       productData[key].toString().isNotEmpty)
        .toList();
    
    if (otherKeys.isEmpty) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.info_outline, color: Colors.white),
        ),
        title: const Text(
          'Informations Supplémentaires',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${otherKeys.length} information(s) supplémentaire(s)', style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: otherKeys.map((key) {
                final value = productData[key];
                // Ne pas afficher les valeurs complexes ou vides
                if (value == null || 
                    (value is Map && value.isEmpty) || 
                    (value is List && value.isEmpty)) {
                  return const SizedBox.shrink();
                }
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 1,
                  child: ListTile(
                    title: Text(
                      _formatKey(key),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: _buildValueWidget(value),
                    ),
                  ),
                );
              }).where((widget) => widget is! SizedBox || (widget as SizedBox).child != null).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueWidget(dynamic value) {
    if (value is Map) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatJson(value),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
      );
    } else if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('• ${entry.value}'),
          );
        }).toList(),
      );
    } else {
      return SelectableText(
        value.toString(),
        style: const TextStyle(fontSize: 14),
      );
    }
  }

  String _formatKey(String key) {
    // Formater les clés pour un affichage plus lisible
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty 
            ? '' 
            : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatJson(dynamic data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      return data.toString();
    }
  }


  Widget _buildEcoScoreButton(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: InkWell(
        onTap: _isCalculatingScore ? null : _calculateEcoScore,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voir le Score Écologique',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isCalculatingScore
                          ? 'Calcul en cours...'
                          : 'Analyser l\'impact environnemental',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isCalculatingScore)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.green,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _calculateEcoScore() async {
    setState(() => _isCalculatingScore = true);

    try {
      final productData = widget.product.productData;
      
      // Préparer les données MS3 pour le scoring
      // On essaie d'extraire les données depuis productData ou on utilise des valeurs par défaut
      final productName = productData['name']?.toString() ?? 
                         productData['product_name']?.toString() ?? 
                         'Produit';
      
      // Extraire les ingrédients depuis la composition
      final composition = productData['composition']?.toString() ?? '';
      final ingredientsBreakdown = _extractIngredientsBreakdown(composition);
      
      // Calculer les impacts totaux (si disponibles dans productData, sinon valeurs par défaut)
      final totalImpacts = _extractTotalImpacts(productData);
      
      // Préparer les données MS3
      final ms3Data = {
        'product_name': productName,
        'total_impacts': {
          'co2_g': totalImpacts['co2_g'] ?? 500.0,
          'water_L': totalImpacts['water_L'] ?? 30.0,
          'energy_MJ': totalImpacts['energy_MJ'] ?? 15.0,
        },
        'ingredients_breakdown': ingredientsBreakdown,
      };
      
      // Appeler le service de scoring
      final ecoScore = await _apiService.computeEcoScore(
        productName: productName,
        ms3Data: ms3Data,
      );
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinalResultScreen(
              ecoScore: ecoScore,
              productInfo: widget.product,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du calcul du score: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCalculatingScore = false);
      }
    }
  }

  List<Map<String, dynamic>> _extractIngredientsBreakdown(String composition) {
    // Si la composition est vide, retourner une liste vide
    if (composition.isEmpty) {
      return [];
    }
    
    // Essayer de parser la composition comme une liste d'ingrédients
    // Format attendu: liste d'objets avec ingredient, mass_g, etc.
    // Pour l'instant, on crée une structure basique
    try {
      // Si c'est déjà une liste JSON
      if (composition.trim().startsWith('[')) {
        final parsed = jsonDecode(composition);
        if (parsed is List) {
          return parsed.map((item) => item as Map<String, dynamic>).toList();
        }
      }
    } catch (e) {
      // Si ce n'est pas du JSON, on traite comme une chaîne simple
    }
    
    // Si c'est une chaîne simple, on crée une structure basique
    // En production, vous devriez parser cela avec NLP
    final ingredients = composition.split(',').map((ing) => ing.trim()).where((ing) => ing.isNotEmpty).toList();
    
    if (ingredients.isEmpty) {
      return [];
    }
    
    // Créer une structure basique pour chaque ingrédient
    final totalIngredients = ingredients.length;
    final avgMass = 100.0 / totalIngredients; // Répartir 100g entre les ingrédients
    
    return ingredients.map((ingredient) {
      return {
        'ingredient': ingredient,
        'mass_g': avgMass,
        'co2_g': 0.0, // Sera calculé par LCA
        'water_L': 0.0,
        'energy_MJ': 0.0,
        'missing_factor': true, // Indique que les facteurs ne sont pas disponibles
      };
    }).toList();
  }

  Map<String, double> _extractTotalImpacts(Map<String, dynamic> productData) {
    // Essayer d'extraire les impacts depuis productData
    final impacts = <String, double>{};
    
    // Chercher dans différentes clés possibles
    if (productData['total_impacts'] != null) {
      final totalImpacts = productData['total_impacts'] as Map<String, dynamic>;
      impacts['co2_g'] = (totalImpacts['co2_g'] ?? 0.0).toDouble();
      impacts['water_L'] = (totalImpacts['water_L'] ?? totalImpacts['water_l'] ?? 0.0).toDouble();
      impacts['energy_MJ'] = (totalImpacts['energy_MJ'] ?? totalImpacts['energy_mj'] ?? 0.0).toDouble();
    } else {
      // Valeurs par défaut si non disponibles
      impacts['co2_g'] = 500.0;
      impacts['water_L'] = 30.0;
      impacts['energy_MJ'] = 15.0;
    }
    
    return impacts;
  }
}