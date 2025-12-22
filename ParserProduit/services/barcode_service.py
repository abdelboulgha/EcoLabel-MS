import requests
from typing import Optional, Dict, Any
import re

class BarcodeService:
    """Service pour rechercher des produits par code-barres - Multi-sources incluant pharmaceutiques"""
    
    def __init__(self):
        self.headers = {"User-Agent": "EcoLabel-MS/1.0"}
        
        # URLs des différentes bases de données
        self.apis = {
            "openfoodfacts": "https://world.openfoodfacts.org/api/v0/product",
            "openbeautyfacts": "https://world.openbeautyfacts.org/api/v0/product",
            "openproductfacts": "https://world.openproductsfacts.org/api/v0/product",
        }
    
    def search_by_barcode(self, barcode: str) -> Optional[Dict[str, Any]]:
        """
        Recherche un produit par code-barres dans plusieurs sources
        Ordre: Open Food Facts → Open Beauty Facts → Open Products Facts → Recherche générique
        """
        # 1. Essayer Open Food Facts (produits alimentaires)
        print(f"🔍 Recherche dans Open Food Facts...")
        product_data = self._search_openfoodfacts(barcode)
        if product_data:
            print(f"✅ Trouvé dans Open Food Facts")
            return product_data
        
        # 2. Essayer Open Beauty Facts (cosmétiques, produits de beauté, compléments)
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
        
        # 4. Essayer recherche générique (pour produits pharmaceutiques et autres)
        print(f"🔍 Recherche générique (produits pharmaceutiques, etc.)...")
        product_data = self._search_generic(barcode)
        if product_data:
            print(f"✅ Trouvé via recherche générique")
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
        """Recherche dans Open Beauty Facts (inclut compléments et certains pharmaceutiques)"""
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
        # Désactiver la vérification SSL si nécessaire (non recommandé en production)
        response = requests.get(url, headers=self.headers, timeout=10, verify=False)
        response.raise_for_status()
        
        data = response.json()
        if data and data.get("status") == 1:
            return self._normalize_data(data, "openproductfacts")
        return None
      except Exception as e:
        print(f"Erreur Open Products Facts: {e}")
        return None
    
    def _search_generic(self, barcode: str) -> Optional[Dict[str, Any]]:
        """
        Recherche générique pour produits pharmaceutiques et autres
        Utilise uniquement des sources gratuites
        """
        # Option 1: Recherche via UPC Item DB (gratuit, limité mais fonctionne)
        try:
            url = f"https://api.upcitemdb.com/prod/trial/lookup"
            params = {"upc": barcode}
            response = requests.get(url, params=params, headers=self.headers, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get("code") == "OK" and data.get("items"):
                    item = data["items"][0]
                    print(f"✅ Trouvé via UPC Item DB")
                    return self._normalize_upcitemdb_data(item, "upcitemdb")
        except Exception as e:
            print(f"Erreur UPC Item DB: {e}")
        
        # Option 2: Barcode Lookup (COMMENTÉ - nécessite clé API payante)
        # Décommentez seulement si vous avez une clé API
        # try:
        #     url = f"https://api.barcodelookup.com/v3/products"
        #     params = {
        #         "barcode": barcode,
        #         "formatted": "y",
        #         "key": "VOTRE_CLE_API_ICI"  # Nécessite inscription et clé API
        #     }
        #     response = requests.get(url, params=params, headers=self.headers, timeout=10)
        #     if response.status_code == 200:
        #         data = response.json()
        #         if data.get("products") and len(data["products"]) > 0:
        #             product = data["products"][0]
        #             return self._normalize_generic_data(product, "barcodelookup")
        # except Exception as e:
        #     print(f"Erreur Barcode Lookup: {e}")
        
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
            "source": source
        }
        
        return normalized
    
    def _normalize_generic_data(self, product: Dict[str, Any], source: str) -> Dict[str, Any]:
        """Normalise les données d'une API générique"""
        normalized = {
            "gtin": product.get("barcode_number", "") or product.get("barcode", ""),
            "name": product.get("product_name", "") or product.get("title", "") or product.get("name", ""),
            "brand": product.get("brand", "") or product.get("manufacturer", ""),
            "composition": product.get("ingredients", "") or product.get("description", ""),
            "packaging": self._extract_packaging_generic(product),
            "netWeight_g": self._extract_weight_generic(product),
            "source": source
        }
        return normalized
    
    def _normalize_upcitemdb_data(self, item: Dict[str, Any], source: str) -> Dict[str, Any]:
        """Normalise les données d'UPC Item DB"""
        normalized = {
            "gtin": item.get("upc", "") or item.get("ean", ""),
            "name": item.get("title", "") or item.get("description", ""),
            "brand": item.get("brand", "") or item.get("manufacturer", ""),
            "composition": item.get("description", ""),
            "packaging": {},
            "netWeight_g": None,
            "source": source
        }
        return normalized
    
    def _extract_composition(self, product_data: Dict[str, Any], source: str) -> Optional[str]:
        """Extrait la composition selon la source"""
        # Pour Open Food Facts
        if source == "openfoodfacts":
            return product_data.get("ingredients_text", "")
        
        # Pour Open Beauty Facts (cosmétiques, compléments, pharmaceutiques)
        if source == "openbeautyfacts":
            return (
                product_data.get("ingredients_text", "") or
                product_data.get("ingredients_list", "") or
                product_data.get("active_ingredients", "") or  # Pour produits pharmaceutiques
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
    
    def _extract_weight_generic(self, product: Dict[str, Any]) -> Optional[float]:
        """Extrait le poids depuis une source générique"""
        weight_str = product.get("weight", "") or product.get("size", "") or product.get("quantity", "")
        if weight_str:
            numbers = re.findall(r'\d+\.?\d*', str(weight_str).lower())
            if numbers:
                try:
                    value = float(numbers[0])
                    weight_lower = str(weight_str).lower()
                    if "kg" in weight_lower or "k" in weight_lower:
                        return value * 1000
                    elif "g" in weight_lower or "ml" in weight_lower:
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
    
    def _extract_packaging_generic(self, product: Dict[str, Any]) -> Dict[str, Any]:
        """Extrait le packaging depuis une source générique"""
        packaging = {}
        if product.get("packaging"):
            packaging["type"] = product["packaging"]
        return packaging