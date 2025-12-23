import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  final ApiService apiService = ApiService();
  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetect(String barcode) async {
    if (isProcessing) return;
    
    setState(() => isProcessing = true);
    
    try {
      print('🔍 Début du scan pour le code-barres: $barcode');
      // Étape 1: Parser le produit depuis le code-barres
      print('📞 Appel parseProduct...');
      final response = await apiService.parseProduct(barcode: barcode);
      print('✅ parseProduct terminé avec succès');
      
      // Étape 2: Construire le texte pour NLP
      // Format exact comme dans Postman: "NomProduit , Poidsg, Composition"
      print('📦 Construction du texte NLP...');
      final productData = response.productData;
      print('📦 productData reçu: ${productData.keys.toList()}');
      
      // Extraire les données du produit
      // Utiliser uniquement le 'name' tel quel (il contient déjà le nom complet)
      final productName = productData['name']?.toString().trim() ?? '';
      final composition = productData['composition']?.toString().trim() ?? '';
      
      // Convertir le poids en entier (enlever les décimales si c'est un double)
      String? productWeightStr;
      final productWeight = productData['netWeight_g'];
      if (productWeight != null) {
        if (productWeight is double) {
          productWeightStr = productWeight.toInt().toString();
        } else if (productWeight is int) {
          productWeightStr = productWeight.toString();
        } else {
          productWeightStr = productWeight.toString().split('.').first; // Enlever les décimales
        }
      }
      
      print('📦 Données extraites: name="$productName", weight="$productWeightStr", composition="$composition"');
      
      // Construire le texte au format exact: "NomComplet Poidsg. Composition"
      // Exemple: "Vita-Weat Natural Ingredients 9 Grains Crispbread 250g. CRISPBREAD WHOLEGRAINS..."
      String nlpText = '';
      
      if (productName.isNotEmpty) {
        nlpText = productName;
        if (productWeightStr != null && productWeightStr.isNotEmpty) {
          nlpText += ' ${productWeightStr}g.';
        }
        if (composition.isNotEmpty) {
          nlpText += ' $composition';
        }
      } else if (composition.isNotEmpty) {
        // Si pas de nom, utiliser la composition avec le poids si disponible
        if (productWeightStr != null && productWeightStr.isNotEmpty) {
          nlpText = '${productWeightStr}g. $composition';
        } else {
          nlpText = composition;
        }
      }
      
      // Nettoyer les espaces multiples
      nlpText = nlpText.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      print('📝 Texte pour NLP (scanner): "$nlpText" (longueur: ${nlpText.length})');
      
      // Étape 3: Appeler NLP pour extraire les ingrédients et calculer le score complet
      if (nlpText.isNotEmpty) {
        print('🚀 Appel NLP en cours...');
        try {
          final ecoScoreResponse = await apiService.extractNLPWithScore(text: nlpText);
          print('✅ Réponse NLP complète reçue: Score ${ecoScoreResponse.ecoScoreNumeric} (${ecoScoreResponse.ecoScoreLetter})');
          print('✅ Score ID: ${ecoScoreResponse.scoreId}');
          print('✅ Confidence: ${ecoScoreResponse.confidence}');
          print('✅ Impacts scores: ${ecoScoreResponse.impactsScores}');
          print('✅ Total impacts: CO2=${ecoScoreResponse.totalImpacts.co2G}, Water=${ecoScoreResponse.totalImpacts.waterL}, Energy=${ecoScoreResponse.totalImpacts.energyMJ}');
          
          // Stocker le score complet dans productData
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
          
          print('💾 Score stocké dans productData: ${productData['eco_score']}');
        } catch (nlpError, stackTrace) {
          print('❌ Erreur NLP complète: $nlpError');
          print('📚 Stack trace: $stackTrace');
          // Afficher l'erreur à l'utilisateur mais continuer
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Avertissement NLP: $nlpError'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        print('⚠️ Texte NLP vide, impossible d\'appeler NLP');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avertissement: Pas assez d\'informations pour calculer le score écologique'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: response),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors du scan: $e');
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
        setState(() => isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de Produit'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _onBarcodeDetect(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}