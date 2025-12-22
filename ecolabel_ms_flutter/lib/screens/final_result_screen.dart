import 'package:flutter/material.dart';
import '../models/product.dart';

class FinalResultScreen extends StatelessWidget {
  final EcoScoreResponse ecoScore;
  final ProductParseResponse? productInfo;

  const FinalResultScreen({
    super.key,
    required this.ecoScore,
    this.productInfo,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = ecoScore.getScoreColor();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat Écologique'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareDialog(context),
            tooltip: 'Partager',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec le score principal
            _buildScoreHeader(context, scoreColor),
            
            // Barre de confiance
            _buildConfidenceBar(context),
            
            // Impacts environnementaux
            _buildImpactsSection(context),
            
            // Scores détaillés
            _buildDetailedScores(context),
            
            // Explications
            _buildExplanationsSection(context),
            
            // Informations produit (si disponibles)
            if (productInfo != null) _buildProductInfo(context),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader(BuildContext context, Color scoreColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.8),
            scoreColor,
          ],
        ),
      ),
      child: Column(
        children: [
          // Nom du produit
          if (ecoScore.productName.isNotEmpty)
            Text(
              ecoScore.productName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          if (ecoScore.productName.isNotEmpty) const SizedBox(height: 16),
          
          // Score lettre (grand)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                ecoScore.ecoScoreLetter,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Score numérique
          Text(
            '${ecoScore.ecoScoreNumeric.toStringAsFixed(1)} / 100',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Badge de qualité
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getScoreLabel(ecoScore.ecoScoreNumeric),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Niveau de Confiance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: ecoScore.confidence,
            backgroundColor: Colors.blue.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${(ecoScore.confidence * 100).toStringAsFixed(0)}% - ${_getConfidenceLabel(ecoScore.confidence)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Impacts Environnementaux',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          
          // CO2
          _buildImpactCard(
            context,
            'Émissions CO₂',
            '${ecoScore.totalImpacts.co2G.toStringAsFixed(1)} g',
            Icons.cloud,
            Colors.orange,
            ecoScore.totalImpacts.co2G,
            1200, // max value for reference
          ),
          
          // Eau
          _buildImpactCard(
            context,
            'Consommation d\'Eau',
            '${ecoScore.totalImpacts.waterL.toStringAsFixed(1)} L',
            Icons.water_drop,
            Colors.blue,
            ecoScore.totalImpacts.waterL,
            60, // max value for reference
          ),
          
          // Énergie
          _buildImpactCard(
            context,
            'Consommation d\'Énergie',
            '${ecoScore.totalImpacts.energyMJ.toStringAsFixed(1)} MJ',
            Icons.bolt,
            Colors.amber,
            ecoScore.totalImpacts.energyMJ,
            30, // max value for reference
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    double current,
    double max,
  ) {
    final percentage = (current / max).clamp(0.0, 1.0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedScores(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scores Détaillés',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildScoreRow(
                    'Score CO₂',
                    ecoScore.impactsScores['co2_score'] ?? 0.0,
                    Colors.orange,
                  ),
                  const Divider(),
                  _buildScoreRow(
                    'Score Eau',
                    ecoScore.impactsScores['water_score'] ?? 0.0,
                    Colors.blue,
                  ),
                  const Divider(),
                  _buildScoreRow(
                    'Score Énergie',
                    ecoScore.impactsScores['energy_score'] ?? 0.0,
                    Colors.amber,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, double score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${score.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          
          if (ecoScore.explanations['co2_contribution'] != null)
            _buildExplanationCard(
              context,
              'Impact Climatique',
              ecoScore.explanations['co2_contribution']!,
              Icons.cloud,
              Colors.orange,
            ),
          
          if (ecoScore.explanations['water_contribution'] != null)
            _buildExplanationCard(
              context,
              'Consommation d\'Eau',
              ecoScore.explanations['water_contribution']!,
              Icons.water_drop,
              Colors.blue,
            ),
          
          if (ecoScore.explanations['energy_contribution'] != null)
            _buildExplanationCard(
              context,
              'Consommation d\'Énergie',
              ecoScore.explanations['energy_contribution']!,
              Icons.bolt,
              Colors.amber,
            ),
          
          if (ecoScore.explanations['global_explanation'] != null)
            _buildExplanationCard(
              context,
              'Explication Globale',
              ecoScore.explanations['global_explanation']!,
              Icons.info,
              Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(
    BuildContext context,
    String title,
    String explanation,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    explanation,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
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

  Widget _buildProductInfo(BuildContext context) {
    if (productInfo == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations Produit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.green),
              title: const Text('Code-barres (GTIN)'),
              subtitle: Text(
                productInfo!.gtin,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Très Bon';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Moyen';
    return 'À Améliorer';
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence >= 0.8) return 'Très Fiable';
    if (confidence >= 0.6) return 'Fiable';
    if (confidence >= 0.4) return 'Modéré';
    return 'Faible';
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager le Résultat'),
        content: const Text(
          'Fonctionnalité de partage à venir. Vous pourrez partager le score écologique du produit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

