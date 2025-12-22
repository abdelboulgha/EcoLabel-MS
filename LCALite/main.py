from fastapi import FastAPI, Depends
from pydantic import BaseModel
import re
from sqlalchemy.orm import Session

from database.connection import get_db, Base, engine
from database.models import LCAResult

import psycopg2  # kept for existing factor queries
import requests
import socket
# -------- Create tables --------
Base.metadata.create_all(bind=engine)

# -------- Request Model --------
class MS2Output(BaseModel):
    product_name: str
    weight: str
    ingredients: list[str]


# -------- Weight distribution --------
def estimate_ingredients_weight(total_weight_g, ingredients):
    n = len(ingredients)
    if n == 0:
        return {}

    raw_weights = [n - i for i in range(n)]
    total_raw = sum(raw_weights)

    return {
        ing: round((w / total_raw) * total_weight_g, 2)
        for ing, w in zip(ingredients, raw_weights)
    }


app = FastAPI(title="EcoLabel-MS3 LCA Calculator")


# -------- PostgreSQL helper for factors --------
def get_factor_db():
    return psycopg2.connect(
        host="localhost",
        database="lca_lite",
        user="postgres",
        password="123456"
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

@app.on_event("startup")
def startup():
    register_service("LCA-LITE", 8003)

@app.post("/lca/calc")
def calculate_lca(ms2: MS2Output, db: Session = Depends(get_db)):

    # STEP 1 — Extract weight
    match = re.match(r"(\d+)", ms2.weight.lower().strip())
    total_weight_g = int(match.group(1)) if match else 100

    # STEP 2 — Estimate ingredient masses
    ingredient_masses = estimate_ingredients_weight(total_weight_g, ms2.ingredients)

    # STEP 3 — Query factor database
    conn = get_factor_db()
    cursor = conn.cursor()

    total_co2 = 0.0
    total_water = 0.0
    total_energy = 0.0
    breakdown = []

    def normalize_to_db(ing: str):
        return "ingredient:" + ing.lower().strip().replace(" ", "_")

    for ing_name, mass_g in ingredient_masses.items():

        ing_id = normalize_to_db(ing_name)

        cursor.execute("""
            SELECT co2_per_kg, water_L_per_kg, energy_MJ_per_kg
            FROM lca_factors
            WHERE ingredient_id = %s
        """, (ing_id,))

        row = cursor.fetchone()

        if row:
            co2_per_kg, water_L_per_kg, energy_MJ_per_kg = map(float, row)
            missing = False
        else:
            co2_per_kg = water_L_per_kg = energy_MJ_per_kg = 0.0
            missing = True

        mass_kg = mass_g / 1000.0

        co2 = co2_per_kg * mass_kg
        water = water_L_per_kg * mass_kg
        energy = energy_MJ_per_kg * mass_kg

        total_co2 += co2
        total_water += water
        total_energy += energy

        breakdown.append({
            "ingredient": ing_name,
            "mass_g": mass_g,
            "co2_g": co2 * 1000,
            "water_L": water,
            "energy_MJ": energy,
            "missing_factor": missing
        })

    cursor.close()
    conn.close()

    total_impacts = {
        "co2_g": round(total_co2 * 1000, 3),
        "water_L": round(total_water, 3),
        "energy_MJ": round(total_energy, 3),
    }

    # -------- STEP 4 — Save results to PostgreSQL --------
    db_entry = LCAResult(
        product_name=ms2.product_name,
        total_co2_g=total_impacts["co2_g"],
        total_water_L=total_impacts["water_L"],
        total_energy_MJ=total_impacts["energy_MJ"],
        ingredients_breakdown=breakdown
    )

    db.add(db_entry)
    db.commit()
    db.refresh(db_entry)

    # -------- Return extended response with DB ID --------
    return {
        "lca_id": db_entry.id,
        "product_name": ms2.product_name,
        "total_impacts": total_impacts,
        "ingredients_breakdown": breakdown,
        "saved": True
    }
@app.get("/health")
def health():
    return {"status": "UP"}
