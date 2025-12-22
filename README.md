# EcoLabel-MS 🌱

Système de microservices pour l'analyse et le scoring écologique de produits alimentaires.

## 📹 Démonstration
https://github.com/user-attachments/assets/6f895f15-c030-46ab-bd9c-8dceeb78196e

## 📋 Description

EcoLabel-MS est une application mobile Flutter connectée à un système de microservices backend qui permet d'analyser les produits alimentaires et de calculer leur impact environnemental (score écologique). Le système utilise l'OCR, le traitement du langage naturel (NLP) avec BERT, et des bases de données LCA (Life Cycle Assessment) pour évaluer l'empreinte carbone, la consommation d'eau et d'énergie des produits.

## 🏗️ Architecture

Le projet est organisé en microservices avec service discovery via Consul :

- **Gateway** : API Gateway FastAPI qui route les requêtes vers les différents microservices
- **ParserProduit** : Service de parsing de produits (code-barres, OCR, scraping)
- **NLPIngredients** : Service NLP pour l'extraction d'ingrédients avec un modèle BERT fine-tuné
- **LCALite** : Service de calcul d'impact environnemental basé sur la base de données Agribalyse
- **Scoring** : Service de calcul de score écologique global
- **ecolabel_ms_flutter** : Application mobile Flutter

## 🚀 Installation

### Prérequis

- Docker et Docker Compose
- Python 3.9+
- Flutter SDK (pour l'application mobile)
- PostgreSQL (géré via Docker)

### Démarrage avec Docker Compose

```bash
# Démarrer tous les services
docker-compose up -d

# Vérifier les services
docker-compose ps
```

Les services seront disponibles sur :
- **Gateway** : http://localhost:8080
- **Consul UI** : http://localhost:8500
- **PostgreSQL** : localhost:5432

### Installation manuelle

#### Backend Services

```bash
# Installer les dépendances Python
pip install -r requirements.txt

# Pour chaque service
cd Gateway && pip install -r requirements.txt
cd ../NLPIngredients && pip install -r requirements.txt
cd ../ParserProduit && pip install -r requirements.txt
cd ../LCALite && pip install -r requirements.txt
cd ../Scoring && pip install -r requirements.txt
```

#### Application Flutter

```bash
cd ecolabel_ms_flutter

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

## 📁 Structure du Projet

```
EcoLabel-MS/
├── Gateway/              # API Gateway
├── NLPIngredients/       # Service NLP avec BERT
├── ParserProduit/        # Service de parsing produits
├── LCALite/             # Service LCA et impact environnemental
├── Scoring/             # Service de scoring
├── ecolabel_ms_flutter/ # Application mobile Flutter
├── Consul/              # Configuration Consul
├── docs/                # Documentation et vidéos
└── docker-compose.yml   # Configuration Docker Compose
```

## 🔧 Configuration

### Variables d'environnement

Chaque service nécessite une configuration de base de données :

```bash
DATABASE_URL=postgresql://ecolabel_user:ecolabel_pass@postgres:5432/ecolabel
```

### Configuration de l'application Flutter

Modifiez `ecolabel_ms_flutter/lib/services/api_service.dart` pour définir l'URL du backend :

```dart
static const String baseUrl = 'http://VOTRE_IP:8080';
```

## 📱 Fonctionnalités

- **Scan de code-barres** : Identification rapide des produits
- **OCR sur images** : Extraction d'informations depuis les photos de produits
- **Extraction d'ingrédients** : Détection automatique avec NLP/BERT
- **Analyse LCA** : Calcul d'impact environnemental (CO₂, eau, énergie)
- **Scoring écologique** : Note globale du produit

## 🛠️ Technologies Utilisées

### Backend
- **FastAPI** : Framework web Python
- **PostgreSQL** : Base de données relationnelle
- **Consul** : Service discovery et configuration
- **Transformers (Hugging Face)** : Modèles NLP BERT
- **SQLAlchemy** : ORM Python

### Frontend
- **Flutter** : Framework mobile multiplateforme
- **mobile_scanner** : Scan de code-barres
- **image_picker** : Sélection d'images

### Infrastructure
- **Docker** : Containerisation
- **Docker Compose** : Orchestration de services

## 📊 Base de Données

La base de données utilise les données Agribalyse pour les calculs LCA. Les tables principales incluent :

- Facteurs LCA (CO₂, eau, énergie)
- Ingredents canoniques
- Extractions NLP
- Produits parsés

## 🔍 API Endpoints

### Gateway (Port 8080)

- `GET /health` - Health check
- `POST /PARSER-PRODUIT/product/parse` - Parser un produit
- `POST /NLP-INGREDIENTS/extract` - Extraire les ingrédients
- `GET /LCA-LITE/factors/{ingredient}` - Obtenir les facteurs LCA
- `POST /SCORING/calculate` - Calculer le score écologique

## 🤝 Contribution


## 📝 Licence

Ce projet est sous licence MIT.

## 👥 Auteurs

Équipe EcoLabel-MS

## 🙏 Remerciements

- Agribalyse pour les données LCA
- Hugging Face pour les modèles Transformers
- La communauté Flutter

