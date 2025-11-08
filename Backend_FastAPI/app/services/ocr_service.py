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
        # pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
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
        # Chercher la section ingrédients
        ingredients_patterns = [
            r'Ingrédients?[:\s]+(.*?)(?:\n\n|\n[A-Z]|$)',
            r'Composition[:\s]+(.*?)(?:\n\n|\n[A-Z]|$)',
        ]
        for pattern in ingredients_patterns:
            match = re.search(pattern, text, re.IGNORECASE | re.DOTALL)
            if match:
                return match.group(1).strip()
        return None
    
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