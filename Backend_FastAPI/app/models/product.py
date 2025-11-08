from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime

class ProductParseRequest(BaseModel):
    barcode: str = Field(..., description="Code-barres GTIN du produit")
    image_url: Optional[str] = Field(None, description="URL de l'image du produit (optionnel)")
    image_base64: Optional[str] = Field(None, description="Image en base64 (optionnel)")

class ProductParseResponse(BaseModel):
    success: bool
    gtin: str
    product_data: Dict[str, Any]
    source: str  # "openfoodfacts", "ocr", "scraper", etc.
    message: Optional[str] = None

class BatchProductParseRequest(BaseModel):
    products: list[ProductParseRequest]

class NormalizedProductData(BaseModel):
    gtin: str
    name: Optional[str] = None
    brand: Optional[str] = None
    category: Optional[str] = None
    composition: Optional[list[str]] = None
    origin: Optional[str] = None
    packaging: Optional[Dict[str, Any]] = None
    nutritional_info: Optional[Dict[str, Any]] = None
    raw_data: Dict[str, Any]