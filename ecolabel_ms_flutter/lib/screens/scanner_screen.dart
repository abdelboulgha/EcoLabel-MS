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
      final response = await apiService.parseProduct(barcode: barcode);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: response),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => isProcessing = false);
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