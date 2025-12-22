import socket

import requests
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import product
from database.connection import engine, Base

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
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
CONSUL_URL = "http://localhost:8500/v1/agent/service/register"

def register_service(name: str, port: int):
    payload = {
        "Name": name,
        "Address": socket.gethostbyname(socket.gethostname()),
        "Port": port,
        "Check": {
            "HTTP": f"http://localhost:{port}/health",
            "Interval": "10s"
        }
    }
    requests.put(CONSUL_URL, json=payload)
# Inclure les routes
@app.on_event("startup")
def startup():
    register_service("ms1-parser-produit", 8001)

app.include_router(product.router, prefix="/product", tags=["product"])
@app.get("/")
async def root():
    return {"message": "ParserProduit Service API", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "UP"}