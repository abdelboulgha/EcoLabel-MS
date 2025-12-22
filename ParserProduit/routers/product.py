from fastapi import APIRouter, HTTPException, Body
from typing import List, Dict, Any
import json

from models.product import (
    ProductParseRequest,
    ProductParseResponse,
    BatchProductParseRequest
)
from services.barcode_service import BarcodeService
from services.ocr_service import OCRService
from services.scraper_service import ScraperService

router = APIRouter()
barcode_service = BarcodeService()
ocr_service = OCRService()
scraper_service = ScraperService()

def _filter_product_data(product_data: Dict[str, Any]) -> Dict[str, Any]:
    """Filtre les données pour ne garder que les champs demandés"""
    filtered = {
        "gtin": product_data.get("gtin", ""),
        "name": product_data.get("name"),
        "brand": product_data.get("brand"),
        "composition": product_data.get("composition"),
        "packaging": product_data.get("packaging", {}),
        "netWeight_g": product_data.get("netWeight_g"),
        "raw_text": product_data.get("raw_text")  # Inclure raw_text pour NLP
    }
    return filtered

@router.post("/parse", response_model=ProductParseResponse)
async def parse_product(
    request: ProductParseRequest,
    # db: Session = Depends(get_db)  # Commenté temporairement
):
    """
    Parse un produit à partir de son code-barres
    Retourne un JSON avec: gtin, name, brand, composition, packaging, netWeight_g
    MODE TEST: Les données ne sont PAS enregistrées en base de données
    """
    try:
        print(f"\n{'='*80}")
        print(f"🔍 Requête reçue - Code-barres: {request.barcode}")
        print(f"{'='*80}")
        
        # ============================================
        # PARTIE COMMENTÉE: Vérification en base de données
        # ============================================
        # existing_product = db.query(Product).filter(Product.gtin == request.barcode).first()
        # if existing_product:
        #     filtered_data = _filter_product_data(existing_product.normalized_data)
        #     response = ProductParseResponse(
        #         success=True,
        #         gtin=request.barcode,
        #         product_data=filtered_data,
        #         source="database"
        #     )
        #     print("\n📦 JSON RETOURNÉ (depuis la base de données):")
        #     print(json.dumps(response.dict(), indent=2, ensure_ascii=False))
        #     print(f"{'='*80}\n")
        #     return response
        
        # 1. Recherche via bases de données (Open Food Facts, Open Beauty Facts, etc.)
        print("🔎 Recherche via bases de données...")
        product_data = barcode_service.search_by_barcode(request.barcode)
        
        # Récupérer la source depuis les données retournées (si trouvé)
        if product_data:
            source = product_data.get("source", "unknown")
        else:
            source = None
        
        # 2. Si pas trouvé et image fournie, utiliser OCR
        if not product_data and request.image_base64:
            print("🔎 Tentative avec OCR...")
            ocr_text = ocr_service.extract_text_from_image(request.image_base64)
            if ocr_text:
                ocr_data = ocr_service.parse_product_info_from_text(ocr_text)
                product_data = {
                    "gtin": request.barcode,
                    **ocr_data
                }
                source = "ocr"
        
        # 3. Si toujours pas trouvé, essayer le scraping
        if not product_data:
            print("🔎 Tentative avec web scraping...")
            scraped_data = scraper_service.search_product_info(request.barcode)
            if scraped_data:
                product_data = scraped_data
                source = scraped_data.get("source", "scraper")
        
        if not product_data:
            print(f"\n❌ Produit non trouvé pour le code-barres: {request.barcode}")
            print(f"{'='*80}\n")
            raise HTTPException(
                status_code=404,
                detail=f"Produit avec code-barres {request.barcode} non trouvé"
            )
        
        # Filtrer les données pour ne garder que les champs demandés
        filtered_data = _filter_product_data(product_data)
        
        # Afficher les données dans la console
        print(f"\n📊 Données brutes extraites:")
        print(json.dumps(product_data, indent=2, ensure_ascii=False))
        print(f"\n✅ Données filtrées (format final):")
        print(json.dumps(filtered_data, indent=2, ensure_ascii=False))
        
        # ============================================
        # PARTIE COMMENTÉE: Sauvegarde en base de données
        # ============================================
        # new_product = Product(
        #     gtin=request.barcode,
        #     name=filtered_data.get("name"),
        #     brand=filtered_data.get("brand"),
        #     category=None,
        #     composition=filtered_data.get("composition"),
        #     origin=None,
        #     raw_data=product_data,
        #     normalized_data=filtered_data
        # )
        # db.add(new_product)
        # db.commit()
        # db.refresh(new_product)
        # print("💾 Données sauvegardées en base de données")
        
        response = ProductParseResponse(
            success=True,
            gtin=request.barcode,
            product_data=filtered_data,
            source=source
        )
        
        # Afficher le JSON final dans la console
        print(f"\n📦 JSON FINAL RETOURNÉ (source: {source}):")
        print(json.dumps(response.dict(), indent=2, ensure_ascii=False))
        print(f"{'='*80}\n")
        
        return response
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"\n❌ ERREUR: {str(e)}")
        print(f"{'='*80}\n")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

@router.post("/parse/batch", response_model=List[ProductParseResponse])
async def parse_batch_products(
    request: BatchProductParseRequest,
    # db: Session = Depends(get_db)  # Commenté temporairement
):
    """Parse un lot de produits (MODE TEST: pas de sauvegarde en base)"""
    results = []
    for product_request in request.products:
        try:
            result = await parse_product(product_request)  # Retirer db
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

@router.post("/parse-from-image", response_model=ProductParseResponse)
async def parse_product_from_image(
    request: dict = Body(...),
):
    """
    Parse un produit à partir d'une image avec OCR
    L'utilisateur fournit le nom et le poids manuellement
    """
    try:
        print(f"\n{'='*80}")
        print(f"🖼️  Requête reçue - Analyse d'image avec OCR")
        print(f"{'='*80}")

        image_base64 = request.get('image_base64')
        product_name = request.get('product_name')
        product_weight_g = request.get('product_weight_g')

        if not image_base64:
            raise HTTPException(status_code=400, detail="Image base64 requise")
        if not product_name:
            raise HTTPException(status_code=400, detail="Nom du produit requis")
        if not product_weight_g:
            raise HTTPException(status_code=400, detail="Poids du produit requis")

        # Extraire le texte avec OCR
        print("🔎 Extraction de texte avec OCR...")
        ocr_text = ocr_service.extract_text_from_image(image_base64)

        if not ocr_text:
            raise HTTPException(status_code=400, detail="Impossible d'extraire le texte de l'image")

        # Parser les informations depuis le texte OCR
        ocr_data = ocr_service.parse_product_info_from_text(ocr_text)

        # Construire les données du produit avec les informations fournies
        product_data = {
            "gtin": "IMAGE_ONLY",  # Pas de code-barres pour les images
            "name": product_name,
            "brand": ocr_data.get("brand"),
            "composition": ocr_data.get("composition"),
            "origin": ocr_data.get("origin"),
            "netWeight_g": product_weight_g,
            "raw_text": ocr_text,
        }

        # Filtrer les données
        filtered_data = _filter_product_data(product_data)

        print(f"\n📊 Données extraites:")
        print(json.dumps(product_data, indent=2, ensure_ascii=False))
        print(f"\n✅ Données filtrées:")
        print(json.dumps(filtered_data, indent=2, ensure_ascii=False))

        response = ProductParseResponse(
            success=True,
            gtin="IMAGE_ONLY",
            product_data=filtered_data,
            source="ocr"
        )

        print(f"\n📦 JSON FINAL RETOURNÉ (source: ocr):")
        print(json.dumps(response.dict(), indent=2, ensure_ascii=False))
        print(f"{'='*80}\n")

        return response

    except HTTPException:
        raise
    except Exception as e:
        print(f"\n❌ ERREUR: {str(e)}")
        print(f"{'='*80}\n")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")

# ============================================
# ROUTE GET COMMENTÉE (nécessite la base de données)
# ============================================
# @router.get("/{gtin}")
# async def get_product(gtin: str, db: Session = Depends(get_db)):
#     """Récupère un produit par son GTIN"""
#     product = db.query(Product).filter(Product.gtin == gtin).first()
#     if not product:
#         raise HTTPException(status_code=404, detail="Produit non trouvé")
#     filtered_data = _filter_product_data(product.normalized_data)
#     
#     print(f"\n{'='*80}")
#     print(f"�� GET /product/{gtin} - JSON RETOURNÉ:")
#     print(json.dumps(filtered_data, indent=2, ensure_ascii=False))
#     print(f"{'='*80}\n")
#     
#     return filtered_data