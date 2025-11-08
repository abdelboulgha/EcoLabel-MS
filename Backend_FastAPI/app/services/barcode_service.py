import requests
from typing import Optional, Dict, Any

class BarcodeService:
    """Service pour rechercher des produits par code-barres"""
    
    def __init__(self):
        self.base_url = "https://world.openfoodfacts.org/api/v0/product"
        self.headers = {"User-Agent": "EcoLabel-MS/1.0"}
    
    def search_by_barcode(self, barcode: str) -> Optional[Dict[str, Any]]:
        """
        Recherche un produit par code-barres via Open Food Facts
        """
        try:
            url = f"{self.base_url}/{barcode}.json"
            response = requests.get(url, headers=self.headers, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            if data and data.get("status") == 1:
                return self._normalize_openfoodfacts_data(data)
            return None
        except Exception as e:
            print(f"Erreur lors de la recherche Open Food Facts: {e}")
            return None
    
    def _normalize_openfoodfacts_data(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Normalise les données d'Open Food Facts"""
        product_data = data.get("product", {})
        
        normalized = {
            "gtin": product_data.get("code", ""),
            "name": product_data.get("product_name", ""),
            "brand": product_data.get("brands", ""),
            "category": product_data.get("categories", ""),
            "composition": product_data.get("ingredients_text", ""),
            "origin": product_data.get("origins", ""),
            "packaging": {
                "type": product_data.get("packaging", ""),
                "recyclable": product_data.get("packaging_tags", [])
            },
            "nutritional_info": product_data.get("nutriments", {}),
            "raw_data": product_data
        }
        
        return normalized