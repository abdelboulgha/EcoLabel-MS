import pandas as pd
import unidecode
import re

df = pd.read_csv("Csv files/lca_final_french_english_co2_water_energy.csv")

def make_canonical(name):
    # to lowercase
    text = name.lower().strip()

    # remove accents
    text = unidecode.unidecode(text)

    # remove parentheses content: oil (refined) → oil
    text = re.sub(r"\(.*?\)", "", text)

    # remove quotes / punctuation
    text = re.sub(r"[^a-zA-Z ]", "", text)

    # normalize spaces
    text = re.sub(r"\s+", " ", text).strip()

    # convert to underscore
    text = text.replace(" ", "_")

    return f"ingredient:{text}"

# create canonical ID column
df["ingredient_id"] = df["ingredient_name_en"].apply(make_canonical)

# keep only necessary columns at this stage
df = df[["ingredient_id", "ingredient_name_en", "ingredient_name_fr", "co2_per_kg", "water_L_per_kg", "energy_MJ_per_kg"]]

df.to_csv("lca_with_canonical_ids.csv", index=False)

print("✅ Canonical IDs assigned and saved to lca_with_canonical_ids.csv")
print(df.head(10))
