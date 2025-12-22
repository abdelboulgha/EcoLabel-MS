from sqlalchemy import Column, Integer, String, DateTime, JSON, func

from database.connection import Base


class NERExtraction(Base):
    __tablename__ = "ner_extractions"

    id = Column(Integer, primary_key=True, index=True)
    raw_text = Column(String, nullable=False)
    product_name = Column(String, nullable=True)
    weight = Column(String, nullable=True)
    ingredients = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
