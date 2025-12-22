import pandas as pd

df = pd.read_csv("Csv files/lca_factors_import.csv")

# Remove duplicates, keep the first occurrence
df_unique = df.drop_duplicates(subset=["ingredient_id"], keep="first")

df_unique.to_csv("lca_factors_import_unique.csv", index=False)

print("✅ Created file without duplicates: lca_factors_import_unique.csv")
print("Previous count:", len(df))
print("New count:", len(df_unique))
