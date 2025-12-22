from sqlalchemy import Column, Integer, String, Float, JSON, DateTime
from sqlalchemy.sql import func
from database.connection import Base

class ScoreHistory(Base):
    __tablename__ = "score_history"

    id = Column(Integer, primary_key=True, index=True)

    product_name = Column(String, nullable=False)

    eco_score_numeric = Column(Float, nullable=False)
    eco_score_letter = Column(String(1), nullable=False)
    confidence = Column(Float, nullable=False)

    impacts_scores = Column(JSON, nullable=False)
    total_impacts = Column(JSON, nullable=False)
    explanations = Column(JSON, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
