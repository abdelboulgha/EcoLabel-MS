import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class ImageFormScreen extends StatefulWidget {
  final String imageBase64;
  final String imagePath;

  const ImageFormScreen({
    super.key,
    required this.imageBase64,
    required this.imagePath,
  });

  @override
  State<ImageFormScreen> createState() => _ImageFormScreenState();
}

class _ImageFormScreenState extends State<ImageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _apiService = ApiService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _processImage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Étape 1: Parser l'image avec OCR
      final parseResponse = await _apiService.parseProductFromImage(
        imageBase64: widget.imageBase64,
        productName: _nameController.text.trim(),
        productWeight: _weightController.text.trim(),
      );

      // Étape 2: Extraire le texte pour NLP
      final productData = parseResponse.productData;
      
      // Construire le texte pour NLP en utilisant les valeurs saisies par l'utilisateur
      // Format exact: "Nom Marque, Poidsg, Composition"
      // Exemple: "Lait Jaouda, 450g, Lait frais pasteurisé demi-écrémé..."
      
      // Utiliser le nom saisi par l'utilisateur ou celui du produit tel quel
      // (le 'name' contient déjà le nom complet, pas besoin d'ajouter la brand)
      String productName = _nameController.text.trim().isNotEmpty 
          ? _nameController.text.trim() 
          : (productData['name']?.toString().trim() ?? '');
      
      final productWeight = _weightController.text.trim().isNotEmpty
          ? _weightController.text.trim()
          : (productData['netWeight_g']?.toString() ?? '100');
      
      // Priorité 1: Utiliser la composition si disponible
      String? composition = productData['composition']?.toString().trim();
      
      // Priorité 2: Utiliser raw_text comme fallback pour les ingrédients
      if ((composition == null || composition.isEmpty) && productData['raw_text'] != null) {
        final rawText = productData['raw_text']?.toString().trim() ?? '';
        composition = rawText;
      }
      
      // Convertir le poids en entier (enlever les décimales si nécessaire)
      String weightStr = productWeight;
      if (weightStr.contains('.')) {
        weightStr = weightStr.split('.').first;
      }
      
      // Construire le texte au format exact: "NomComplet Poidsg. Composition"
      // Exemple: "Vita-Weat Natural Ingredients 9 Grains Crispbread 250g. CRISPBREAD WHOLEGRAINS..."
      String nlpText = '';
      
      if (productName.isNotEmpty) {
        nlpText = productName;
        if (weightStr.isNotEmpty) {
          nlpText += ' ${weightStr}g.';
        }
        if (composition != null && composition.isNotEmpty) {
          nlpText += ' $composition';
        }
      } else if (composition != null && composition.isNotEmpty) {
        // Si pas de nom, utiliser la composition avec le poids
        nlpText = '${weightStr}g. $composition';
      } else {
        nlpText = '$productName ${weightStr}g.';
      }
      
      // Nettoyer les espaces multiples
      nlpText = nlpText.replaceAll(RegExp(r'\s+'), ' ').trim();

      print('📝 Texte pour NLP (image): "$nlpText" (longueur: ${nlpText.length})');

      // Étape 3: Appeler NLP pour extraire les ingrédients et calculer le score complet
      try {
        final ecoScoreResponse = await _apiService.extractNLPWithScore(text: nlpText);
        print('✅ Réponse NLP complète reçue: Score ${ecoScoreResponse.ecoScoreNumeric} (${ecoScoreResponse.ecoScoreLetter})');
        
        // Stocker le score complet dans productData pour utilisation ultérieure
        productData['eco_score'] = {
          'score_id': ecoScoreResponse.scoreId,
          'product_name': ecoScoreResponse.productName,
          'eco_score_numeric': ecoScoreResponse.ecoScoreNumeric,
          'eco_score_letter': ecoScoreResponse.ecoScoreLetter,
          'confidence': ecoScoreResponse.confidence,
          'impacts_scores': ecoScoreResponse.impactsScores,
          'total_impacts': {
            'co2_g': ecoScoreResponse.totalImpacts.co2G,
            'water_L': ecoScoreResponse.totalImpacts.waterL,
            'energy_MJ': ecoScoreResponse.totalImpacts.energyMJ,
          },
          'explanations': ecoScoreResponse.explanations,
        };
        
        // Stocker aussi les ingrédients extraits pour l'affichage
        // Les ingrédients sont dans la réponse mais on peut les extraire depuis les données du produit
        // ou les obtenir séparément si nécessaire
      } catch (nlpError) {
        print('⚠️ Erreur NLP (continuons quand même): $nlpError');
        // Afficher l'erreur à l'utilisateur mais continuer
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Avertissement NLP: $nlpError'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        // On continue même si NLP échoue
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: parseResponse),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations du Produit'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Aperçu de l'image
              Card(
                elevation: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(widget.imagePath),
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Instructions
              const Text(
                'Veuillez remplir les informations suivantes :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Champ Nom du produit
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du produit *',
                  hintText: 'Ex: Chocolat noir 70%',
                  prefixIcon: const Icon(Icons.shopping_bag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le nom du produit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Champ Poids
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Poids (en grammes) *',
                  hintText: 'Ex: 250',
                  prefixIcon: const Icon(Icons.scale),
                  suffixText: 'g',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le poids du produit';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Bouton Analyser
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processImage,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    _isProcessing ? 'Traitement en cours...' : 'Analyser l\'image',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Note
              // Container(
              //   padding: const EdgeInsets.all(12),
              //   decoration: BoxDecoration(
              //     color: Colors.blue.shade50,
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(color: Colors.blue.shade200),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(Icons.info_outline, color: Colors.blue.shade700),
              //       const SizedBox(width: 8),
              //       Expanded(
              //         child: Text(
              //           'L\'image sera analysée avec OCR pour extraire les ingrédients.',
              //           style: TextStyle(
              //             fontSize: 12,
              //             color: Colors.blue.shade900,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
