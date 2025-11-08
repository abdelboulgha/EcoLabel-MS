import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductParseResponse product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final productData = product.productData;
    
    // Afficher les données dans la console pour debug
    print('📦 Données reçues:');
    print(jsonEncode(productData));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Produit'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showJsonDialog(context),
            tooltip: 'Voir JSON',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec GTIN
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            
            // Informations principales
            _buildSectionTitle('Informations Principales'),
            if (productData['name'] != null && productData['name'].toString().isNotEmpty)
              _buildInfoCard(context, 'Nom du produit', productData['name'].toString(), Icons.shopping_bag),
            
            if (productData['brand'] != null && productData['brand'].toString().isNotEmpty)
              _buildInfoCard(context, 'Marque', productData['brand'].toString(), Icons.branding_watermark),
            
            if (productData['category'] != null && productData['category'].toString().isNotEmpty)
              _buildInfoCard(context, 'Catégorie', productData['category'].toString(), Icons.category),
            
            if (productData['origin'] != null && productData['origin'].toString().isNotEmpty)
              _buildInfoCard(context, 'Origine', productData['origin'].toString(), Icons.public),
            
            // Composition/Ingrédients
            if (productData['composition'] != null && productData['composition'].toString().isNotEmpty)
              _buildCompositionCard(context, productData['composition']),
            
            // Emballage
            if (productData['packaging'] != null)
              _buildPackagingCard(context, productData['packaging']),
            
            // Informations nutritionnelles
            if (productData['nutritional_info'] != null)
              _buildNutritionCard(context, productData['nutritional_info']),
            
            // Données brutes (JSON formaté)
            _buildRawDataCard(context, productData),
            
            // Toutes les autres données
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
                        product.gtin,
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
                  label: Text('Source: ${product.source}'),
                  backgroundColor: Colors.green.shade100,
                ),
                if (product.success)
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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildCompositionCard(BuildContext context, dynamic composition) {
    String compositionText = composition.toString();
    bool isLong = compositionText.length > 200;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.list, color: Colors.white),
        ),
        title: const Text(
          'Composition / Ingrédients',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: isLong 
          ? const Text('Appuyez pour voir tout', style: TextStyle(fontSize: 12))
          : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SelectableText(
              compositionText,
              style: Theme.of(context).textTheme.bodyMedium,
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
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.inventory_2, color: Colors.white),
        ),
        title: const Text(
          'Emballage',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: packaging is Map
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: packaging.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatKey(entry.key.toString()),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: _buildValueWidget(entry.value),
                            ),
                          ],
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
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(Icons.restaurant, color: Colors.white),
        ),
        title: const Text(
          'Informations Nutritionnelles',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: nutritionalInfo is Map
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: nutritionalInfo.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatKey(entry.key.toString()),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                entry.value.toString(),
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildRawDataCard(BuildContext context, Map<String, dynamic> productData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.grey.shade100,
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.code, color: Colors.white),
        ),
        title: const Text(
          'Données Brutes (JSON)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('Format JSON structuré', style: TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _formatJson(productData),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDataCard(BuildContext context, Map<String, dynamic> productData) {
    // Afficher toutes les autres clés qui n'ont pas été affichées
    final displayedKeys = {'name', 'brand', 'category', 'composition', 'origin', 'packaging', 'nutritional_info', 'gtin', 'raw_data'};
    final otherKeys = productData.keys.where((key) => !displayedKeys.contains(key)).toList();
    
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
          'Autres Données',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${otherKeys.length} champ(s) supplémentaire(s)', style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: otherKeys.map((key) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatKey(key),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildValueWidget(productData[key]),
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

  void _showJsonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Données JSON Complètes'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              _formatJson(product.productData),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              // Copier dans le presse-papier (nécessite package clipboard)
              Navigator.pop(context);
            },
            child: const Text('Copier'),
          ),
        ],
      ),
    );
  }
}