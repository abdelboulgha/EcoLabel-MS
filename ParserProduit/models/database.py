from sqlalchemy import Column, String, Integer, DateTime, JSON, Text
from sqlalchemy.sql import func
from database.connection import Base

class Product(Base):
    __tablename__ = "products"
    
    id = Column(Integer, primary_key=True, index=True)
    gtin = Column(String(14), unique=True, index=True, nullable=False)
    name = Column(String(255))
    brand = Column(String(100))
    category = Column(String(100))
    composition = Column(Text)
    origin = Column(String(100))
    packaging = Column(Text)
    raw_data = Column(JSON)  
    normalized_data = Column(JSON)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())