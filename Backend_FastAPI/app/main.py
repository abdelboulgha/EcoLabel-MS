from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import product
from app.database.connection import engine, Base

# Créer les tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="ParserProduit Service",
    description="Service d'extraction et normalisation des données produits",
    version="1.0.0"
)

# CORS pour permettre les requêtes depuis Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifier l'origine Flutter
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclure les routes
app.include_router(product.router, prefix="/product", tags=["product"])

@app.get("/")
async def root():
    return {"message": "ParserProduit Service API", "version": "1.0.0"}

@app.get("/health")
async def health():
    return {"status": "healthy"}