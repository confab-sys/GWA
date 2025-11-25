from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class Content(Base):
    __tablename__ = "contents"
    
    # Primary key
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Content fields
    title = Column(String(255), nullable=False, index=True)
    body = Column(Text, nullable=False)
    topic = Column(String(100), nullable=False, index=True)
    
    # Content type and media
    post_type = Column(String(20), default="text", nullable=False)  # text, image
    image_path = Column(String(500), nullable=True)
    is_text_only = Column(Boolean, default=True, nullable=False)
    
    # Author information
    author_name = Column(String(100), nullable=False, default="Admin")
    author_avatar = Column(String(500), nullable=True)
    
    # Engagement metrics
    likes_count = Column(Integer, default=0, nullable=False)
    comments_count = Column(Integer, default=0, nullable=False)
    
    # Status and visibility
    status = Column(String(20), default="published", nullable=False, index=True)  # published, draft, archived
    is_featured = Column(Boolean, default=False, nullable=False, index=True)
    
    # Foreign key to user (for tracking who created the content)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    published_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    creator = relationship("User", back_populates="created_contents")
    comments = relationship("Comment", back_populates="content", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Content(id={self.id}, title='{self.title}', topic='{self.topic}', status='{self.status}')>"
    
    def to_dict(self):
        """Convert content to dictionary (safe for API responses)"""
        return {
            "id": self.id,
            "title": self.title,
            "body": self.body,
            "topic": self.topic,
            "post_type": self.post_type,
            "image_path": self.image_path,
            "is_text_only": self.is_text_only,
            "author_name": self.author_name,
            "author_avatar": self.author_avatar,
            "likes_count": self.likes_count,
            "comments_count": self.comments_count,
            "status": self.status,
            "is_featured": self.is_featured,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "published_at": self.published_at.isoformat() if self.published_at else None,
            "created_by": self.created_by,
        }