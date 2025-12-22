import pandas as pd

# === FILES ===
detail = pd.read_csv("Csv files/agribalyse-31-detail-par-etape.csv", sep=",", engine="python")
synth = pd.read_csv("Csv files/agribalyse-31-synthese.csv", sep=";", engine="python")

# === 1) Identify column names ===
name_fr = "Nom du Produit en Français"
name_en = "LCI Name"
code_col = "Code AGB"  # unique product key

# === 2) Compute CO₂ from detail file ===
co2_cols = [c for c in detail.columns if "Changement climatique" in c]
detail["co2_per_kg"] = detail[co2_cols].apply(pd.to_numeric, errors="coerce").fillna(0).sum(axis=1)

# === 3) Compute Water from detail file ===
water_cols = [c for c in detail.columns if "Épuisement des ressources eau" in c]
detail["water_L_per_kg"] = detail[water_cols].apply(pd.to_numeric, errors="coerce").fillna(0).sum(axis=1)

# Keep identification & impacts
detail_clean = detail[[code_col, name_fr, name_en, "co2_per_kg", "water_L_per_kg"]].copy()

# === 4) Extract Energy from synthèse file ===
energy_col = "Épuisement des ressources énergétiques"
synth[energy_col] = pd.to_numeric(synth[energy_col], errors="coerce").fillna(0)
synth_clean = synth[[code_col, energy_col]].copy()
synth_clean = synth_clean.rename(columns={energy_col: "energy_MJ_per_kg"})

# === 5) Merge datasets on Code AGB ===
merged = detail_clean.merge(synth_clean, on=code_col, how="left")

# === 6) Clean
merged = merged.rename(columns={
    name_fr: "ingredient_name_fr",
    name_en: "ingredient_name_en"
})
merged = merged.drop_duplicates(subset=["ingredient_name_fr"]).reset_index(drop=True)

# === 7) Save result
merged.to_csv("lca_final_french_english_co2_water_energy.csv", index=False)

print("✅ Final ACV dataset created:")
print("lca_final_french_english_co2_water_energy.csv")

print("\nExample preview:")
print(merged.head(10))
