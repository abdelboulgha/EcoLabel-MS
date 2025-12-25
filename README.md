<h1 align="center">🌱 EcoLabel-MS</h1>

<p align="center">
  <strong>Système de Microservices pour l'Analyse et le Scoring Écologique de Produits Alimentaires</strong><br>
  <em>Application Mobile Flutter avec Backend Microservices</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.9+-blue?logo=python&logoColor=white" alt="Python"/>
  <img src="https://img.shields.io/badge/Flutter-3.9+-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white" alt="Docker"/>
  <img src="https://img.shields.io/badge/NLP-BERT-yellow?logo=huggingface&logoColor=white" alt="BERT"/>
</p>

<p align="center">
  <a href="#-à-propos">À propos</a> •
  <a href="#-fonctionnalités">Fonctionnalités</a> •
  <a href="#-architecture">Architecture</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-utilisation">Utilisation</a> •
  <a href="#-api">API</a> •
  <a href="#ci-cd-pipeline-jenkins">CI/CD</a> •
  <a href="#-équipe">Équipe</a>
</p>

---

## 📋 À propos

**EcoLabel-MS** est un système intelligent d'analyse et de scoring écologique pour produits alimentaires. Il permet d'évaluer l'impact environnemental des produits (empreinte carbone, consommation d'eau et d'énergie) grâce à l'analyse d'images, l'OCR, le traitement du langage naturel (NLP) avec BERT, et des bases de données LCA (Life Cycle Assessment) basées sur Agribalyse.

### 🎯 Objectifs

- ✅ Analyser les produits alimentaires via code-barres ou images
- ✅ Extraire automatiquement les ingrédients avec NLP/BERT
- ✅ Calculer l'impact environnemental (CO₂, eau, énergie)
- ✅ Fournir un score écologique global pour chaque produit
- ✅ Interface mobile intuitive et moderne

---

## 📹 Démonstration

https://github.com/user-attachments/assets/6f895f15-c030-46ab-bd9c-8dceeb78196e

---

## ✨ Fonctionnalités

| Module | Description | Technologie |
|--------|-------------|-------------|
| 📱 **Application Mobile** | Interface Flutter pour scan et analyse | Flutter / Dart |
| 🔍 **Parser Produit** | Parsing de produits (code-barres, OCR, scraping) | Python / FastAPI |
| 🤖 **NLP Ingredients** | Extraction d'ingrédients via BERT fine-tuné | Python / Transformers |
| 🌍 **LCA Lite** | Calcul d'impact environnemental (CO₂, eau, énergie) | Python / FastAPI |
| 📊 **Scoring** | Calcul de score écologique global | Python / FastAPI |
| 🚪 **API Gateway** | Routage et orchestration des microservices | Python / FastAPI |
| 🔄 **Service Discovery** | Découverte de services avec Consul | Consul |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   APPLICATION MOBILE (Flutter)                   │
│                        iOS / Android                             │
└─────────────────────────────┬───────────────────────────────────┘
                              │ HTTP/REST
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY (FastAPI)                       │
│                          Port: 8080                              │
└──────┬──────────┬──────────┬──────────┬──────────┬──────────────┘
       │          │          │          │          │
       ▼          ▼          ▼          ▼          ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Parser   │ │   NLP    │ │   LCA    │ │ Scoring  │ │ Consul   │
│ Produit  │ │Ingredients│ │  Lite    │ │ Service  │ │ Discovery│
│  :8001   │ │  :8002   │ │  :8003   │ │  :8004   │ │  :8500   │
└────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────────┘
     │            │            │            │
     └────────────┴────────────┼────────────┘
                               │
       ┌───────────────────────┼───────────────────────┐
       ▼                       ▼                       ▼
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│  PostgreSQL  │       │   BERT NER   │       │  Agribalyse  │
│    :5432     │       │    Model     │       │   Database   │
└──────────────┘       └──────────────┘       └──────────────┘
```

### 📦 Microservices

| Service | Port | Langage | Framework | Description |
|---------|------|---------|-----------|-------------|
| API Gateway | 8080 | Python | FastAPI | Routage et orchestration |
| Parser Produit | 8001 | Python | FastAPI | Scan code-barres, OCR, scraping |
| NLP Ingredients | 8002 | Python | FastAPI + Transformers | Extraction d'ingrédients (BERT) |
| LCA Lite | 8003 | Python | FastAPI | Calcul impact environnemental |
| Scoring | 8004 | Python | FastAPI | Calcul score écologique |
| Consul | 8500 | - | Consul | Service discovery |
| PostgreSQL | 5432 | SQL | PostgreSQL | Base de données |

---

## 🚀 Installation

### Prérequis

- **Docker** 20+ et Docker Compose 2+
- **Python** 3.9+ (pour développement local)
- **Flutter SDK** 3.9+ (pour l'application mobile)
- **8 GB RAM** minimum (16 GB recommandé pour le modèle BERT)

### Étapes d'installation

1. **Cloner le dépôt**
```bash
git clone https://github.com/votre-username/EcoLabel-MS.git
cd EcoLabel-MS
```

2. **Lancer les services avec Docker Compose**
```bash
docker-compose up -d
```

3. **Vérifier les services**
```bash
docker-compose ps
```

4. **Installer l'application Flutter** (optionnel, pour développement)
```bash
cd ecolabel_ms_flutter
flutter pub get
flutter run
```

### Accès aux services

- 🌐 **API Gateway** : http://localhost:8080
- 🗄️ **Consul UI** : http://localhost:8500
- 📊 **PostgreSQL** : localhost:5432

---

## 💻 Utilisation

### Application Mobile

1. **Scanner un code-barres** : Utilisez l'appareil photo pour scanner le code-barres d'un produit
2. **Prendre une photo** : Photographiez l'emballage du produit pour analyse OCR
3. **Analyser** : L'application extrait les ingrédients et calcule l'impact environnemental
4. **Visualiser le score** : Consultez le score écologique et les détails (CO₂, eau, énergie)

### Exemple de Workflow

```
1. Scan code-barres → Parser Produit
2. Extraction texte (OCR) → NLP Ingredients
3. Identification ingrédients → LCA Lite
4. Calcul impact → Scoring
5. Affichage résultat → Application Mobile
```

---

## 📡 API

### Endpoints principaux

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/PARSER-PRODUIT/product/parse` | Parser un produit (code-barres) |
| `POST` | `/PARSER-PRODUIT/product/parse-from-image` | Parser un produit depuis une image |
| `POST` | `/NLP-INGREDIENTS/extract` | Extraire les ingrédients (NLP) |
| `GET` | `/LCA-LITE/factors/{ingredient}` | Obtenir les facteurs LCA d'un ingrédient |
| `POST` | `/SCORING/calculate` | Calculer le score écologique |
| `GET` | `/health` | Health check |

### Exemple d'appel API

```bash
# Parser un produit
curl -X POST http://localhost:8080/PARSER-PRODUIT/product/parse \
  -H "Content-Type: application/json" \
  -d '{"barcode": "3560070952934"}'

# Extraire les ingrédients
curl -X POST http://localhost:8080/NLP-INGREDIENTS/extract \
  -H "Content-Type: application/json" \
  -d '{"text": "Eau, sucre, acidifiant: acide citrique"}'
```

---

## 📁 Structure du Projet

```
EcoLabel-MS/
├── 📂 Gateway/                    # API Gateway (Python/FastAPI)
├── 📂 ParserProduit/              # Service de parsing (Python/FastAPI)
├── 📂 NLPIngredients/             # Service NLP (Python/FastAPI + BERT)
├── 📂 LCALite/                    # Service LCA (Python/FastAPI)
├── 📂 Scoring/                    # Service de scoring (Python/FastAPI)
├── 📂 ecolabel_ms_flutter/        # Application mobile (Flutter)
│   ├── 📂 lib/
│   │   ├── 📂 screens/            # Écrans de l'application
│   │   ├── 📂 services/           # Services API
│   │   ├── 📂 models/             # Modèles de données
│   │   └── 📂 widgets/            # Widgets réutilisables
│   └── 📄 pubspec.yaml            # Dépendances Flutter
├── 📂 Consul/                     # Configuration Consul
├── 📂 docs/                       # Documentation et vidéos
├── 📄 docker-compose.yml          # Orchestration Docker
└── 📄 README.md                   # Documentation
```

---

## 🔧 Configuration

### Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|--------|
| `DATABASE_URL` | URL de connexion PostgreSQL | `postgresql://ecolabel_user:ecolabel_pass@postgres:5432/ecolabel` |
| `CONSUL_URL` | URL du serveur Consul | `http://localhost:8500` |

### Configuration de l'application Flutter

Modifiez `ecolabel_ms_flutter/lib/services/api_service.dart` :

```dart
static const String baseUrl = 'http://VOTRE_IP:8080';
```

---

## 🛠️ Technologies Utilisées

### Backend
- **FastAPI** : Framework web Python moderne et performant
- **PostgreSQL** : Base de données relationnelle
- **Consul** : Service discovery et configuration distribuée
- **Transformers (Hugging Face)** : Bibliothèque NLP pour BERT
- **SQLAlchemy** : ORM Python
- **Pytesseract** : OCR pour extraction de texte
- **BeautifulSoup** : Parsing HTML pour scraping

### Frontend
- **Flutter** : Framework mobile multiplateforme
- **mobile_scanner** : Scan de code-barres
- **image_picker** : Sélection d'images
- **http** : Client HTTP pour les appels API

### Infrastructure
- **Docker** : Containerisation des services
- **Docker Compose** : Orchestration de services
- **Consul** : Service discovery

### Données
- **Agribalyse** : Base de données LCA pour l'impact environnemental
- **BERT MS2** : Modèle NLP fine-tuné pour extraction d'ingrédients

---

## 🔁 CI/CD Pipeline (Jenkins)

EcoLabel-MS intègre une **chaîne CI/CD complète** automatisée avec **Jenkins**, garantissant la qualité du code, l’analyse statique et le déploiement continu des microservices.

### 🛠️ Outils CI/CD utilisés

- **Jenkins** – Orchestration du pipeline CI/CD
- **GitHub Webhooks** – Déclenchement automatique à chaque push
- **SonarQube** – Analyse statique du code Python
- **Docker & Docker Compose** – Build et déploiement des microservices
- **Windows Jenkins Agent** – Exécution locale des jobs

---

### 🔄 Étapes du Pipeline

Le pipeline est défini dans un **Jenkinsfile** situé à la racine du projet et s’exécute selon les étapes suivantes :

1. **Clone Repository**
   - Clonage automatique du dépôt GitHub

2. **Prepare Model**
   - Copie locale du modèle NLP (BERT) non versionné
   - Injection du modèle dans le workspace Jenkins pour les microservices

3. **Python Quality & Tests (Parallèle)**
   - Installation des dépendances Python
   - Exécution des tests unitaires (`pytest`)
   - Validation par microservice :
     - Gateway
     - ParserProduit
     - NLPIngredients
     - LCALite
     - Scoring

4. **SonarQube Analysis (Parallèle)**
   - Analyse statique indépendante pour chaque microservice
   - Suivi de la qualité, dette technique et maintenabilité

5. **Docker Build & Deploy**
   - Build des images Docker
   - Déploiement automatisé via Docker Compose

---

### 📊 Visualisation du Pipeline

Le pipeline Jenkins offre une visualisation graphique claire, montrant l’exécution parallèle des microservices et l’état global du déploiement.

<img width="1897" height="908" alt="image" src="https://github.com/user-attachments/assets/c30d7b58-2b19-4d6c-9315-cce4eee00abe" />

---

## 📊 Base de Données

La base de données utilise les données **Agribalyse** pour les calculs LCA. Les tables principales incluent :

- **Facteurs LCA** : CO₂, eau, énergie par ingrédient
- **Ingrédients canoniques** : Mapping des ingrédients
- **Extractions NLP** : Historique des extractions d'ingrédients
- **Produits parsés** : Informations sur les produits analysés
- **Scores** : Historique des scores écologiques

---

## 🛡️ Sécurité

- ✅ **Validation des entrées** : Vérification des données utilisateur
- ✅ **Isolation des services** : Conteneurisation Docker
- ✅ **Service discovery sécurisé** : Consul pour la gestion des services
- ✅ **Gestion des erreurs** : Gestion robuste des exceptions

---

## 👥 Équipe

<table>
  <tr>
    <td align="center"><strong>Abdelillah Boulgha</strong></td>
    <td align="center"><strong>Ahmed Elhamri</strong></td>
    <td align="center"><strong>Fatimazohra Lamzoghi</strong></td>
    <td align="center"><strong>Ouarda Azizi</strong></td>
  </tr>
</table>

**École Marocaine des Sciences de l'Ingénieur (EMSI)**  
📆 Année académique 2024-2025

---

## 📝 Licence

Ce projet est développé dans un cadre académique. Tous droits réservés.

---

## 🙏 Remerciements

- **Agribalyse** pour les données LCA
- **Hugging Face** pour les modèles Transformers
- **La communauté Flutter** pour le support et les ressources
- **Open Food Facts** pour les données produits

---

<p align="center">
  <sub>Développé par l'équipe EcoLabel-MS</sub>
</p>
