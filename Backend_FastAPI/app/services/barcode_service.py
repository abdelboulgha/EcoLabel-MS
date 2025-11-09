import requests
from typing import Optional, Dict, Any

class BarcodeService:
    """Service pour rechercher des produits par code-barres - Multi-sources"""
    
    def __init__(self):
        self.headers = {"User-Agent": "EcoLabel-MS/1.0"}
        
        # URLs des différentes bases de données
        self.apis = {
            "openfoodfacts": "https://world.openfoodfacts.org/api/v0/product",
            "openbeautyfacts": "https://world.openbeautyfacts.org/api/v0/product",
            "openproductfacts": "https://world.openproductfacts.org/api/v0/product",
        }
    
    def search_by_barcode(self, barcode: str) -> Optional[Dict[str, Any]]:
        """
        Recherche un produit par code-barres dans plusieurs sources
        Essaie dans l'ordre: Open Food Facts → Open Beauty Facts → Open Products Facts
        """
        # 1. Essayer Open Food Facts (produits alimentaires)
        print(f"🔍 Recherche dans Open Food Facts...")
        product_data = self._search_openfoodfacts(barcode)
        if product_data:
            print(f"✅ Trouvé dans Open Food Facts")
            return product_data
        
        # 2. Essayer Open Beauty Facts (cosmétiques, produits de beauté)
        print(f"🔍 Recherche dans Open Beauty Facts...")
        product_data = self._search_openbeautyfacts(barcode)
        if product_data:
            print(f"✅ Trouvé dans Open Beauty Facts")
            return product_data
        
        # 3. Essayer Open Products Facts (autres produits)
        print(f"🔍 Recherche dans Open Products Facts...")
        product_data = self._search_openproductfacts(barcode)
        if product_data:
            print(f"✅ Trouvé dans Open Products Facts")
            return product_data
        
        print(f"❌ Produit non trouvé dans aucune base de données")
        return None
    
    def _search_openfoodfacts(self, barcode: str) -> Optional[Dict[str, Any]]:
        """Recherche dans Open Food Facts"""
        try:
            url = f"{self.apis['openfoodfacts']}/{barcode}.json"
            response = requests.get(url, headers=self.headers, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            if data and data.get("status") == 1:
                return self._normalize_data(data, "openfoodfacts")
            return None
        except Exception as e:
            print(f"Erreur Open Food Facts: {e}")
            return None
    
    def _search_openbeautyfacts(self, barcode: str) -> Optional[Dict[str, Any]]:
        """Recherche dans Open Beauty Facts"""
        try:
            url = f"{self.apis['openbeautyfacts']}/{barcode}.json"
            response = requests.get(url, headers=self.headers, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            if data and data.get("status") == 1:
                return self._normalize_data(data, "openbeautyfacts")
            return None
        except Exception as e:
            print(f"Erreur Open Beauty Facts: {e}")
            return None
    
    def _search_openproductfacts(self, barcode: str) -> Optional[Dict[str, Any]]:
        """Recherche dans Open Products Facts"""
        try:
            url = f"{self.apis['openproductfacts']}/{barcode}.json"
            response = requests.get(url, headers=self.headers, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            if data and data.get("status") == 1:
                return self._normalize_data(data, "openproductfacts")
            return None
        except Exception as e:
            print(f"Erreur Open Products Facts: {e}")
            return None
    
    def _normalize_data(self, data: Dict[str, Any], source: str) -> Dict[str, Any]:
        """Normalise les données de n'importe quelle source Open Facts"""
        product_data = data.get("product", {})
        
        # Extraire le poids net
        net_weight_g = self._extract_net_weight(product_data)
        
        # Extraire le packaging
        packaging = self._extract_packaging(product_data)
        
        # Normaliser avec seulement les champs demandés
        normalized = {
            "gtin": product_data.get("code", ""),
            "name": product_data.get("product_name", "") or product_data.get("name", ""),
            "brand": product_data.get("brands", "") or product_data.get("brand", ""),
            "composition": self._extract_composition(product_data, source),
            "packaging": packaging,
            "netWeight_g": net_weight_g,
            "source": source  # Ajouter la source pour debug
        }
        
        return normalized
    
    def _extract_composition(self, product_data: Dict[str, Any], source: str) -> Optional[str]:
        """Extrait la composition selon la source"""
        # Pour Open Food Facts
        if source == "openfoodfacts":
            return product_data.get("ingredients_text", "")
        
        # Pour Open Beauty Facts (cosmétiques)
        if source == "openbeautyfacts":
            # Peut avoir: ingredients_text, ingredients_list, etc.
            return (
                product_data.get("ingredients_text", "") or
                product_data.get("ingredients_list", "") or
                ", ".join(product_data.get("ingredients", [])) if isinstance(product_data.get("ingredients"), list) else ""
            )
        
        # Pour Open Products Facts
        if source == "openproductfacts":
            return (
                product_data.get("ingredients_text", "") or
                product_data.get("composition", "") or
                product_data.get("ingredients", "")
            )
        
        return None
    
    def _extract_net_weight(self, product_data: Dict[str, Any]) -> Optional[float]:
        """Extrait le poids net en grammes"""
        # Méthode 1: net_weight_value (en grammes)
        if "net_weight_value" in product_data and product_data["net_weight_value"]:
            try:
                return float(product_data["net_weight_value"])
            except (ValueError, TypeError):
                pass
        
        # Méthode 2: quantity (format: "400g", "1 kg", etc.)
        if "quantity" in product_data and product_data["quantity"]:
            quantity = str(product_data["quantity"]).lower()
            import re
            numbers = re.findall(r'\d+\.?\d*', quantity)
            if numbers:
                try:
                    value = float(numbers[0])
                    if "kg" in quantity or "k" in quantity:
                        return value * 1000
                    elif "g" in quantity or "ml" in quantity:
                        return value
                    return value
                except (ValueError, TypeError):
                    pass
        
        # Méthode 3: net_weight
        if "net_weight" in product_data and product_data["net_weight"]:
            net_weight = str(product_data["net_weight"]).lower()
            import re
            numbers = re.findall(r'\d+\.?\d*', net_weight)
            if numbers:
                try:
                    value = float(numbers[0])
                    if "kg" in net_weight or "k" in net_weight:
                        return value * 1000
                    elif "g" in net_weight or "ml" in net_weight:
                        return value
                    return value
                except (ValueError, TypeError):
                    pass
        
        return None
    
    def _extract_packaging(self, product_data: Dict[str, Any]) -> Dict[str, Any]:
        """Extrait les informations d'emballage"""
        packaging = {}
        
        if "packaging" in product_data and product_data["packaging"]:
            packaging["type"] = product_data["packaging"]
        
        if "packaging_tags" in product_data and product_data["packaging_tags"]:
            packaging["tags"] = product_data["packaging_tags"]
        
        if "packaging_materials" in product_data and product_data["packaging_materials"]:
            packaging["materials"] = product_data["packaging_materials"]
        
        return packaging if packaging else {}