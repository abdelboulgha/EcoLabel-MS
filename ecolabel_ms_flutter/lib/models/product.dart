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