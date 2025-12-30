from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class Milestone(Base):
    __tablename__ = "milestones"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    label = Column(String(100), nullable=False)
    duration_seconds = Column(Integer, nullable=False, unique=True)
    icon_code = Column(Integer, nullable=False) # FontAwesome code point
    color_hex = Column(String(20), nullable=False) # hex or name
    description = Column(Text, nullable=False)
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user_milestones = relationship("UserMilestone", back_populates="milestone")

class UserMilestone(Base):
    __tablename__ = "user_milestones"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    milestone_id = Column(Integer, ForeignKey("milestones.id"), nullable=False)
    unlocked_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", backref="milestones")
    milestone = relationship("Milestone", back_populates="user_milestones")
