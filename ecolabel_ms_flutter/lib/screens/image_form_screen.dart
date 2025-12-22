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
      
      // Priorité 1: Utiliser raw_text s'il est disponible (texte OCR brut)
      String? nlpText = productData['raw_text']?.toString();
      
      // Priorité 2: Construire le texte à partir des données extraites
      if (nlpText == null || nlpText.isEmpty) {
        final productName = productData['name']?.toString() ?? _nameController.text.trim();
        final productWeight = productData['netWeight_g']?.toString() ?? _weightController.text.trim();
        final composition = productData['composition']?.toString() ?? '';
        
        // Construire le texte au format attendu par NLP
        // Format: "NomProduit Poids. ingrédient1, ingrédient2, ..."
        nlpText = '$productName ${productWeight}g.';
        if (composition.isNotEmpty) {
          nlpText += ' $composition';
        }
      }

      print('📝 Texte pour NLP: $nlpText');

      // Étape 3: Appeler NLP pour extraire les ingrédients
      try {
        final nlpResponse = await _apiService.extractNLP(text: nlpText);
        print('✅ Réponse NLP: $nlpResponse');
        
        // Enrichir les données du produit avec les résultats NLP
        if (nlpResponse['ingredients'] != null) {
          productData['nlp_ingredients'] = nlpResponse['ingredients'];
          productData['nlp_product_name'] = nlpResponse['product_name'];
          productData['nlp_weight'] = nlpResponse['weight'];
        }
      } catch (nlpError) {
        print('⚠️ Erreur NLP (continuons quand même): $nlpError');
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
