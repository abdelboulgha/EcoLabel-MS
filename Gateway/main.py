import socket

from fastapi import FastAPI, Request
from proxy import proxy_request
import requests


app = FastAPI(title="EcoLabel API Gateway")
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

@app.on_event("startup")
def startup():
    register_service("GATEWAY", 8080)

# -------- ROUTES -------- #

@app.api_route("/PARSER-PRODUIT/{path:path}", methods=["GET", "POST"])
async def parser_gateway(path: str, request: Request):
    return await proxy_request("PARSER-PRODUIT", path, request)

@app.api_route("/NLP-INGREDIENTS/{path:path}", methods=["GET", "POST"])
async def nlp_gateway(path: str, request: Request):
    return await proxy_request("NLP-INGREDIENTS", path, request)

@app.api_route("/LCA-LITE/{path:path}", methods=["GET", "POST"])
async def lca_gateway(path: str, request: Request):
    return await proxy_request("LCA-LITE", path, request)

@app.api_route("/SCORING/{path:path}", methods=["GET", "POST"])
async def scoring_gateway(path: str, request: Request):
    return await proxy_request("SCORING", path, request)

# -------- HEALTH -------- #

@app.get("/health")
def health():
    return {"gateway": "UP"}
