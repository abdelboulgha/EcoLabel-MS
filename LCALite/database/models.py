from sqlalchemy import Column, Integer, String, Float, JSON, DateTime
from sqlalchemy.sql import func

from database.connection import Base


class LCAResult(Base):
    __tablename__ = "lca_results"

    id = Column(Integer, primary_key=True, index=True)
    product_name = Column(String, nullable=False)

    total_co2_g = Column(Float, nullable=False)
    total_water_L = Column(Float, nullable=False)
    total_energy_MJ = Column(Float, nullable=False)

    ingredients_breakdown = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
