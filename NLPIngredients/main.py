from service_discovery import discover
from fastapi import FastAPI, Depends
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForTokenClassification
import torch
import re
import requests
import socket
import os

from sqlalchemy.orm import Session
from database.connection import get_db, Base, engine
from database.models import NERExtraction

# MODEL_PATH = "bert_ms2_ner_model"
MODEL_PATH = os.getenv("MODEL_PATH", "/models/bert")

# Create tables
Base.metadata.create_all(bind=engine)

# Load tokenizer and model
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)
model = AutoModelForTokenClassification.from_pretrained(MODEL_PATH)
id2label = model.config.id2label

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

app = FastAPI(title="EcoLabel-MS2 NLP API")


class NLPInput(BaseModel):
    text: str

@app.on_event("startup")
def startup():
    register_service("NLP-INGREDIENTS", 8002)
@app.get("/debug/model")
def debug_model():
    return {
        "model_path": MODEL_PATH,
        "model_loaded": model is not None,
        "num_labels": model.config.num_labels,
        "labels": model.config.id2label
    }

@app.post("/extract")
def extract_entities(input: NLPInput, db: Session = Depends(get_db)):

    text = input.text

    # Tokenization
    encoded = tokenizer(
        text,
        return_tensors="pt",
        return_offsets_mapping=True,
        truncation=True
    )

    with torch.no_grad():
        outputs = model(**{k: v for k, v in encoded.items() if k != "offset_mapping"})

    preds = torch.argmax(outputs.logits, dim=-1).squeeze().tolist()
    offsets = encoded["offset_mapping"].squeeze().tolist()

    # Reconstruct entities
    entities = []
    current = None

    for pred_id, (start, end) in zip(preds, offsets):
        if start == end == 0:
            continue

        label = id2label[pred_id]

        if label == "O":
            if current:
                entities.append(current)
                current = None
            continue

        prefix, ent_type = label.split("-")

        if prefix == "B":
            if current:
                entities.append(current)
            current = {"label": ent_type, "start": start, "end": end}

        elif prefix == "I" and current and current["label"] == ent_type:
            current["end"] = end

        else:
            if current:
                entities.append(current)
            current = None

    if current:
        entities.append(current)

    # Extract fields
    product = None
    weight = None
    ingredients = []

    for ent in entities:
        span = text[ent["start"]:ent["end"]].strip()

        if ent["label"] == "PRODUCT":
            product = span

        elif ent["label"] == "WEIGHT":
            weight = span

        elif ent["label"] == "ING":
            # Split merged ingredients
            parts = re.split(r"[;,]+", span)
            for p in parts:
                p = p.strip()
                if len(p) > 1:
                    ingredients.append(p)

    # Remove duplicates
    ingredients = list(dict.fromkeys(ingredients))

    # Save to database
    db_entry = NERExtraction(
        raw_text=text,
        product_name=product,
        weight=weight,
        ingredients=ingredients
    )
    db.add(db_entry)
    db.commit()
    db.refresh(db_entry)

    return {
        "id": db_entry.id,
        "product_name": product,
        "weight": weight,
        "ingredients": ingredients
    }

@app.post("/nlp/extract")
def analyze_pipeline(input: NLPInput, db: Session = Depends(get_db)):

    # STEP 1 — NLP extraction (reuse existing logic)
    extraction = extract_entities(input, db)

    # STEP 2 — Call LCA
    lca_url = discover("LCA-LITE")
    lca_response = requests.post(
        f"{lca_url}/lca/calc",
        json={
            "product_name": extraction["product_name"],
            "weight": extraction["weight"],
            "ingredients": extraction["ingredients"]
        }
    ).json()

    # STEP 3 — Call Scoring
    scoring_url = discover("SCORING")
    score_response = requests.post(
        f"{scoring_url}/score/compute",
        json=lca_response
    ).json()

    # STEP 4 — Aggregate result
    # return {
    #     "product_name": extraction["product_name"],
    #     "ingredients": extraction["ingredients"],
    #     "lca": lca_response,
    #     "score": score_response
    # }
    return score_response

@app.get("/health")
def health():
    return {"status": "UP"}
