from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# DATABASE_URL = os.getenv(
#     "DATABASE_URL",
#     "postgresql://user:1234@localhost:5432/ecolabel_db"
# )

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://parser_user:parser_pass@postgres-parser:5432/parser_db"
)

engine = create_engine(DATABASE_URL, echo=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()