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
        """Normalise les données d'Open Food Facts avec seulement les champs demandés"""
        product_data = data.get("product", {})
        
        # Extraire le poids net en grammes
        net_weight_g = self._extract_net_weight(product_data)
        
        # Extraire le packaging
        packaging = self._extract_packaging(product_data)
        
        # Normaliser avec seulement les champs demandés
        normalized = {
            "gtin": product_data.get("code", ""),
            "name": product_data.get("product_name", ""),
            "brand": product_data.get("brands", ""),
            "composition": product_data.get("ingredients_text", ""),
            "packaging": packaging,
            "netWeight_g": net_weight_g
        }
        
        return normalized
    
    def _extract_net_weight(self, product_data: Dict[str, Any]) -> Optional[float]:
        """Extrait le poids net en grammes depuis les données Open Food Facts"""
        # Essayer différentes clés possibles pour le poids net
        # Open Food Facts peut avoir: quantity, net_weight, net_weight_value, etc.
        
        # Méthode 1: net_weight_value (en grammes)
        if "net_weight_value" in product_data and product_data["net_weight_value"]:
            try:
                return float(product_data["net_weight_value"])
            except (ValueError, TypeError):
                pass
        
        # Méthode 2: quantity (format: "400g", "1 kg", etc.)
        if "quantity" in product_data and product_data["quantity"]:
            quantity = str(product_data["quantity"]).lower()
            # Extraire les nombres et convertir en grammes
            import re
            numbers = re.findall(r'\d+\.?\d*', quantity)
            if numbers:
                try:
                    value = float(numbers[0])
                    # Si contient "kg" ou "k", convertir en grammes
                    if "kg" in quantity or "k" in quantity:
                        return value * 1000
                    # Si contient "g", c'est déjà en grammes
                    elif "g" in quantity:
                        return value
                    # Sinon, supposer que c'est en grammes
                    return value
                except (ValueError, TypeError):
                    pass
        
        # Méthode 3: net_weight (peut être en différentes unités)
        if "net_weight" in product_data and product_data["net_weight"]:
            net_weight = str(product_data["net_weight"]).lower()
            import re
            numbers = re.findall(r'\d+\.?\d*', net_weight)
            if numbers:
                try:
                    value = float(numbers[0])
                    if "kg" in net_weight or "k" in net_weight:
                        return value * 1000
                    elif "g" in net_weight:
                        return value
                    return value
                except (ValueError, TypeError):
                    pass
        
        return None
    
    def _extract_packaging(self, product_data: Dict[str, Any]) -> Dict[str, Any]:
        """Extrait les informations d'emballage"""
        packaging = {}
        
        # Type d'emballage
        if "packaging" in product_data and product_data["packaging"]:
            packaging["type"] = product_data["packaging"]
        
        # Tags d'emballage
        if "packaging_tags" in product_data and product_data["packaging_tags"]:
            packaging["tags"] = product_data["packaging_tags"]
        
        # Matériaux d'emballage
        if "packaging_materials" in product_data and product_data["packaging_materials"]:
            packaging["materials"] = product_data["packaging_materials"]
        
        # Si aucun packaging trouvé, retourner un dict vide
        if not packaging:
            packaging = {}
        
        return packaging