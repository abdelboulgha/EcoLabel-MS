from fastapi import FastAPI, Depends
from pydantic import BaseModel
from typing import List, Dict
import requests
import socket
from sqlalchemy.orm import Session
from database.connection import get_db, Base, engine
from database.models import ScoreHistory

# Create tables if not exist
Base.metadata.create_all(bind=engine)

# ---------- Pydantic Models ----------
class TotalImpacts(BaseModel):
    co2_g: float
    water_L: float
    energy_MJ: float


class IngredientImpact(BaseModel):
    ingredient: str
    mass_g: float
    co2_g: float
    water_L: float
    energy_MJ: float
    missing_factor: bool


class MS3Output(BaseModel):
    product_name: str
    total_impacts: TotalImpacts
    ingredients_breakdown: List[IngredientImpact]


class EcoScoreResponse(BaseModel):
    score_id: int
    product_name: str
    eco_score_numeric: float
    eco_score_letter: str
    confidence: float
    impacts_scores: Dict[str, float]
    total_impacts: TotalImpacts
    explanations: Dict[str, str]


# ---------- Scoring Helpers ----------
def score_co2(co2_g: float) -> float:
    if co2_g <= 100: return 100.0
    elif co2_g <= 300: return 90.0
    elif co2_g <= 500: return 80.0
    elif co2_g <= 800: return 65.0
    elif co2_g <= 1200: return 50.0
    return 35.0


def score_water(water_L: float) -> float:
    if water_L <= 10: return 100.0
    elif water_L <= 30: return 85.0
    elif water_L <= 60: return 70.0
    return 50.0


def score_energy(energy_MJ: float) -> float:
    if energy_MJ <= 5: return 100.0
    elif energy_MJ <= 15: return 80.0
    elif energy_MJ <= 30: return 60.0
    return 45.0


def numeric_to_letter(score: float) -> str:
    if score >= 90: return "A"
    elif score >= 75: return "B"
    elif score >= 60: return "C"
    elif score >= 40: return "D"
    return "E"


def compute_confidence(ingredients: List[IngredientImpact]) -> float:
    if not ingredients:
        return 0.5

    total = len(ingredients)
    missing = sum(1 for ing in ingredients if ing.missing_factor)
    raw_conf = 1 - (missing / total)

    return round(max(0.2, min(1.0, raw_conf)), 2)


def build_explanations(impacts: TotalImpacts, co2_score: float, water_score: float, energy_score: float):
    if co2_score >= 90:
        co2_exp = "Très faible impact climatique."
    elif co2_score >= 70:
        co2_exp = "Impact climatique modéré."
    else:
        co2_exp = "Impact climatique élevé."

    if water_score >= 90:
        water_exp = "Faible consommation d'eau."
    elif water_score >= 70:
        water_exp = "Consommation d'eau modérée."
    else:
        water_exp = "Consommation d'eau élevée."

    if energy_score >= 90:
        energy_exp = "Faible consommation d'énergie."
    elif energy_score >= 70:
        energy_exp = "Consommation d'énergie correcte."
    else:
        energy_exp = "Consommation d'énergie élevée."

    global_exp = "Le score global combine CO₂, eau et énergie de manière pondérée."

    return {
        "co2_contribution": co2_exp,
        "water_contribution": water_exp,
        "energy_contribution": energy_exp,
        "global_explanation": global_exp
    }

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
# ---------- FastAPI ----------
app = FastAPI(title="EcoLabel-MS4 – Service de Scoring")

@app.on_event("startup")
def startup():
    register_service("SCORING", 8004)


@app.post("/score/compute", response_model=EcoScoreResponse)
def compute_score(ms3_data: MS3Output, db: Session = Depends(get_db)):

    impacts = ms3_data.total_impacts

    co2_score = score_co2(impacts.co2_g)
    water_score = score_water(impacts.water_L)
    energy_score = score_energy(impacts.energy_MJ)

    eco_numeric = round(
        co2_score * 0.5 +
        water_score * 0.3 +
        energy_score * 0.2,
        1
    )

    eco_letter = numeric_to_letter(eco_numeric)

    confidence = compute_confidence(ms3_data.ingredients_breakdown)

    explanations = build_explanations(
        impacts=impacts,
        co2_score=co2_score,
        water_score=water_score,
        energy_score=energy_score
    )

    score_record = ScoreHistory(
        product_name=ms3_data.product_name,
        eco_score_numeric=eco_numeric,
        eco_score_letter=eco_letter,
        confidence=confidence,
        impacts_scores={
            "co2_score": co2_score,
            "water_score": water_score,
            "energy_score": energy_score
        },
        total_impacts=impacts.dict(),
        explanations=explanations
    )

    db.add(score_record)
    db.commit()
    db.refresh(score_record)

    return EcoScoreResponse(
        score_id=score_record.id,
        product_name=ms3_data.product_name,
        eco_score_numeric=eco_numeric,
        eco_score_letter=eco_letter,
        confidence=confidence,
        impacts_scores=score_record.impacts_scores,
        total_impacts=impacts,
        explanations=explanations
    )
@app.get("/health")
def health():
    return {"status": "UP"}
