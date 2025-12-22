import pytesseract
from PIL import Image
import io
import base64
from typing import Optional, Dict, Any
import re

class OCRService:
    """Service pour l'extraction de texte via OCR"""
    
    def __init__(self):
        # Configurer le chemin Tesseract si nécessaire
        pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
        pass
    
    def extract_text_from_image(self, image_base64: str) -> Optional[str]:
        """Extrait le texte d'une image en base64"""
        try:
            image_data = base64.b64decode(image_base64)
            image = Image.open(io.BytesIO(image_data))
            text = pytesseract.image_to_string(image, lang='fra+eng')
            return text
        except Exception as e:
            print(f"Erreur OCR: {e}")
            return None
    
    def parse_product_info_from_text(self, text: str) -> Dict[str, Any]:
        """Parse les informations produit depuis le texte OCR"""
        info = {
            "name": self._extract_name(text),
            "brand": self._extract_brand(text),
            "composition": self._extract_ingredients(text),
            "origin": self._extract_origin(text),
            "raw_text": text
        }
        return info
    
    def _extract_name(self, text: str) -> Optional[str]:
        # Chercher le nom du produit (généralement en début de texte)
        lines = text.split('\n')
        for line in lines[:5]:
            if len(line) > 10 and len(line) < 100:
                return line.strip()
        return None
    
    def _extract_brand(self, text: str) -> Optional[str]:
        # Patterns pour identifier la marque
        brand_patterns = [
            r'Marque[:\s]+([A-Z][A-Za-z\s]+)',
            r'Brand[:\s]+([A-Z][A-Za-z\s]+)',
        ]
        for pattern in brand_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        return None
    
    def _extract_ingredients(self, text: str) -> Optional[str]:
        """
        Extrait la liste complète des ingrédients, même sur plusieurs lignes
        S'arrête seulement aux sections importantes suivantes
        """
        # Mots-clés qui indiquent la fin de la liste d'ingrédients
        stop_keywords = [
            r'\n\s*Contient\s',
            r'\n\s*Peut\s+contenir',
            r'\n\s*Conserver',
            r'\n\s*Storage',
            r'\n\s*Origine\s*[:]',
            r'\n\s*Pays\s+d\'origine',
            r'\n\s*Valeurs?\s+nutritionnelles?',
            r'\n\s*Nutrition\s+facts',
            r'\n\s*Poids\s*[:]',
            r'\n\s*Net\s+weight',
            r'\n\s*Marque\s*[:]',
            r'\n\s*Brand\s*[:]',
            r'\n\s*Prix\s*[:]',
            r'\n\s*Price\s*[:]',
        ]
        
        # Patterns pour trouver le début de la section ingrédients
        ingredients_patterns = [
            r'Ingrédients?\s*[:]\s*',
            r'Composition\s*[:]\s*',
            r'Liste\s+des\s+ingrédients\s*[:]\s*',
        ]
        
        # Chercher le début de la section ingrédients
        start_match = None
        start_pos = -1
        
        for pattern in ingredients_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                start_match = match
                start_pos = match.end()  # Position après "Ingrédients :"
                break
        
        if start_pos == -1:
            return None
        
        # Extraire le texte restant après "Ingrédients :"
        remaining_text = text[start_pos:]
        
        # Trouver où s'arrêter (première occurrence d'un stop keyword)
        stop_pos = len(remaining_text)  # Par défaut, prendre jusqu'à la fin
        
        for stop_pattern in stop_keywords:
            match = re.search(stop_pattern, remaining_text, re.IGNORECASE)
            if match:
                # Prendre la position la plus proche (la première qui apparaît)
                if match.start() < stop_pos:
                    stop_pos = match.start()
        
        # Extraire les ingrédients
        ingredients_text = remaining_text[:stop_pos].strip()
        
        # Nettoyer le texte :
        # - Remplacer les retours à la ligne multiples par des espaces
        # - Remplacer les retours à la ligne simples par des espaces
        # - Garder seulement un espace entre les mots
        ingredients_text = re.sub(r'\s+', ' ', ingredients_text)  # Multiples espaces → 1 espace
        ingredients_text = re.sub(r'\s*,\s*', ', ', ingredients_text)  # Nettoyer les virgules
        
        # Vérifier qu'on a quelque chose de valide
        if len(ingredients_text) < 3:
            return None
        
        return ingredients_text
    
    def _extract_origin(self, text: str) -> Optional[str]:
        # Chercher l'origine
        origin_patterns = [
            r'Origine[:\s]+([A-Z][A-Za-z\s,]+)',
            r'Pays d\'origine[:\s]+([A-Z][A-Za-z\s,]+)',
        ]
        for pattern in origin_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        return None