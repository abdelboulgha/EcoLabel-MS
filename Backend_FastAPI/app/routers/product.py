from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
from app.database.connection import get_db
from app.models.product import (
    ProductParseRequest,
    ProductParseResponse,
    BatchProductParseRequest,
    NormalizedProductData
)
from app.models.database import Product
from app.services.barcode_service import BarcodeService
from app.services.ocr_service import OCRService
from app.services.scraper_service import ScraperService

router = APIRouter()
barcode_service = BarcodeService()
ocr_service = OCRService()
scraper_service = ScraperService()

@router.post("/parse", response_model=ProductParseResponse)
async def parse_product(
    request: ProductParseRequest,
    db: Session = Depends(get_db)
):
    """
    Parse un produit à partir de son code-barres
    """
    try:
        # 1. Vérifier si le produit existe déjà en base
        existing_product = db.query(Product).filter(Product.gtin == request.barcode).first()
        if existing_product:
            return ProductParseResponse(
                success=True,
                gtin=request.barcode,
                product_data=existing_product.normalized_data,
                source="database"
            )
        
        # 2. Recherche via Open Food Facts
        product_data = barcode_service.search_by_barcode(request.barcode)
        source = "openfoodfacts"
        
        # 3. Si pas trouvé et image fournie, utiliser OCR
        if not product_data and request.image_base64:
            ocr_text = ocr_service.extract_text_from_image(request.image_base64)
            if ocr_text:
                ocr_data = ocr_service.parse_product_info_from_text(ocr_text)
                product_data = {
                    "gtin": request.barcode,
                    **ocr_data
                }
                source = "ocr"
        
        # 4. Si toujours pas trouvé, essayer le scraping
        if not product_data:
            scraped_data = scraper_service.search_product_info(request.barcode)
            if scraped_data:
                product_data = scraped_data
                source = "scraper"
        
        if not product_data:
            raise HTTPException(
                status_code=404,
                detail=f"Produit avec code-barres {request.barcode} non trouvé"
            )
        
        # 5. Sauvegarder en base de données
        new_product = Product(
            gtin=request.barcode,
            name=product_data.get("name"),
            brand=product_data.get("brand"),
            category=product_data.get("category"),
            composition=product_data.get("composition"),
            origin=product_data.get("origin"),
            raw_data=product_data,
            normalized_data=product_data
        )
        db.add(new_product)
        db.commit()
        db.refresh(new_product)
        
        return ProductParseResponse(
            success=True,
            gtin=request.barcode,
            product_data=product_data,
            source=source
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@router.post("/parse/batch", response_model=List[ProductParseResponse])
async def parse_batch_products(
    request: BatchProductParseRequest,
    db: Session = Depends(get_db)
):
    """Parse un lot de produits"""
    results = []
    for product_request in request.products:
        try:
            result = await parse_product(product_request, db)
            results.append(result)
        except Exception as e:
            results.append(ProductParseResponse(
                success=False,
                gtin=product_request.barcode,
                product_data={},
                source="error",
                message=str(e)
            ))
    return results

@router.get("/{gtin}")
async def get_product(gtin: str, db: Session = Depends(get_db)):
    """Récupère un produit par son GTIN"""
    product = db.query(Product).filter(Product.gtin == gtin).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produit non trouvé")
    return product.normalized_data