import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

# Configuration de la base de données
DB_CONFIG = {
    "host": "localhost",
    "database": "lca_lite",
    "user": "postgres",
    "password": "123456"
}

# Chemin vers le fichier CSV
CSV_FILE = "Csv files/lca_factors_import_unique.csv"

def create_table_if_not_exists(cursor):
    """Crée la table lca_factors si elle n'existe pas"""
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS lca_factors (
            ingredient_id VARCHAR(255) PRIMARY KEY,
            co2_per_kg FLOAT NOT NULL,
            water_L_per_kg FLOAT NOT NULL,
            energy_MJ_per_kg FLOAT NOT NULL
        )
    """)
    print("✅ Table lca_factors créée/vérifiée")

def import_csv_to_db():
    """Importe les données du CSV dans la base de données"""
    try:
        # Lire le CSV
        print(f"📖 Lecture du fichier: {CSV_FILE}")
        df = pd.read_csv(CSV_FILE)
        print(f"✅ {len(df)} lignes lues")
        
        # Se connecter à la base de données
        print("🔌 Connexion à la base de données...")
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Créer la table si nécessaire
        create_table_if_not_exists(cursor)
        conn.commit()
        
        # Préparer les données pour l'insertion
        # Convertir le DataFrame en liste de tuples
        data_tuples = [
            (row['ingredient_id'], 
             float(row['co2_per_kg']), 
             float(row['water_L_per_kg']), 
             float(row['energy_MJ_per_kg']))
            for _, row in df.iterrows()
        ]
        
        # Insérer les données (avec gestion des doublons)
        print("📥 Insertion des données...")
        insert_query = """
            INSERT INTO lca_factors (ingredient_id, co2_per_kg, water_L_per_kg, energy_MJ_per_kg)
            VALUES %s
            ON CONFLICT (ingredient_id) 
            DO UPDATE SET 
                co2_per_kg = EXCLUDED.co2_per_kg,
                water_L_per_kg = EXCLUDED.water_L_per_kg,
                energy_MJ_per_kg = EXCLUDED.energy_MJ_per_kg
        """
        
        execute_values(cursor, insert_query, data_tuples)
        conn.commit()
        
        # Vérifier le nombre de lignes insérées
        cursor.execute("SELECT COUNT(*) FROM lca_factors")
        count = cursor.fetchone()[0]
        print(f"✅ Import terminé! {len(data_tuples)} lignes insérées/mises à jour")
        print(f"📊 Total dans la base: {count} lignes")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        if 'conn' in locals():
            conn.rollback()
            conn.close()
        raise

if __name__ == "__main__":
    import_csv_to_db()