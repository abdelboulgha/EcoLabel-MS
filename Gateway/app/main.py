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
    register_service("api-gateway", 8080)

# -------- ROUTES -------- #

@app.api_route("/parser/{path:path}", methods=["GET", "POST"])
async def parser_gateway(path: str, request: Request):
    return await proxy_request("ms1-parser-produit", path, request)

@app.api_route("/nlp/{path:path}", methods=["GET", "POST"])
async def nlp_gateway(path: str, request: Request):
    return await proxy_request("ms2-nlp-ingredients", path, request)

@app.api_route("/lca/{path:path}", methods=["GET", "POST"])
async def lca_gateway(path: str, request: Request):
    return await proxy_request("ms3-lca-lite", path, request)

@app.api_route("/score/{path:path}", methods=["GET", "POST"])
async def scoring_gateway(path: str, request: Request):
    return await proxy_request("ms4-scoring", path, request)

# -------- HEALTH -------- #

@app.get("/health")
def health():
    return {"gateway": "UP"}
