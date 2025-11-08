import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductParseResponse product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final productData = product.productData;
    
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
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code-barres (GTIN)',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      product.gtin,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text('Source: ${product.source}'),
                      backgroundColor: Colors.green.shade100,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Nom du produit
            if (productData['name'] != null && productData['name'].toString().isNotEmpty)
              _buildInfoCard(
                context,
                'Nom du produit',
                productData['name'].toString(),
                Icons.shopping_bag,
              ),
            
            // Marque
            if (productData['brand'] != null && productData['brand'].toString().isNotEmpty)
              _buildInfoCard(
                context,
                'Marque',
                productData['brand'].toString(),
                Icons.branding_watermark,
              ),
            
            // Catégorie
            if (productData['category'] != null && productData['category'].toString().isNotEmpty)
              _buildInfoCard(
                context,
                'Catégorie',
                productData['category'].toString(),
                Icons.category,
              ),
            
            // Composition/Ingrédients
            if (productData['composition'] != null && productData['composition'].toString().isNotEmpty)
              _buildInfoCard(
                context,
                'Composition',
                productData['composition'].toString(),
                Icons.list,
              ),
            
            // Origine
            if (productData['origin'] != null && productData['origin'].toString().isNotEmpty)
              _buildInfoCard(
                context,
                'Origine',
                productData['origin'].toString(),
                Icons.public,
              ),
            
            // Emballage
            if (productData['packaging'] != null)
              _buildPackagingCard(context, productData['packaging']),
            
            // Informations nutritionnelles
            if (productData['nutritional_info'] != null)
              _buildNutritionCard(context, productData['nutritional_info']),
            
            // Données brutes (pour debug)
            ExpansionTile(
              title: const Text('Données brutes (Debug)'),
              leading: const Icon(Icons.code),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    productData.toString(),
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ],
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
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildPackagingCard(BuildContext context, dynamic packaging) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.inventory_2, color: Colors.green),
        title: const Text('Emballage'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: packaging is Map
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: packaging.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }).toList(),
                  )
                : Text(
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
      child: ExpansionTile(
        leading: const Icon(Icons.restaurant, color: Colors.green),
        title: const Text('Informations nutritionnelles'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: nutritionalInfo is Map
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: nutritionalInfo.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key.toString(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : Text(
                    nutritionalInfo.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
          ),
        ],
      ),
    );
  }
}