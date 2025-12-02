from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class Notification(Base):
    __tablename__ = "notifications"
    
    # Primary key
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Notification fields
    notification_type = Column(String(20), nullable=False, index=True)  # like, comment, follow, etc.
    title = Column(String(255), nullable=False)
    body = Column(Text, nullable=False)
    
    # Optional linked content
    content_id = Column(Integer, ForeignKey("contents.id"), nullable=True)
    question_id = Column(Integer, ForeignKey("questions.id"), nullable=True)
    
    # Author information
    author_name = Column(String(100), nullable=False)
    author_avatar = Column(String(500), nullable=True)
    
    # User who receives the notification
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    is_read = Column(Boolean, default=False, nullable=False, index=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="notifications")
    content = relationship("Content", back_populates="notifications")
    question = relationship("Question", back_populates="notifications")