from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base


class Question(Base):
    __tablename__ = "questions"
    
    # Primary key
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Question fields
    title = Column(String(500), nullable=False, index=True)  # Question title/text
    category = Column(String(100), nullable=False, index=True)  # Addiction, Trauma, etc.
    
    # Content and media
    content = Column(Text, nullable=False)  # Detailed question description
    has_image = Column(Boolean, default=False, nullable=False)
    image_path = Column(String(500), nullable=True)
    
    # Author information
    author_name = Column(String(100), nullable=False)
    is_anonymous = Column(Boolean, default=False, nullable=False)  # Allow anonymous questions
    
    # Engagement metrics
    likes_count = Column(Integer, default=0, nullable=False)
    comments_count = Column(Integer, default=0, nullable=False)
    saves_count = Column(Integer, default=0, nullable=False)
    
    # Status and visibility
    status = Column(String(20), default="published", nullable=False, index=True)  # published, draft, archived, reported
    is_featured = Column(Boolean, default=False, nullable=False, index=True)
    
    # Foreign keys
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    user = relationship("User", backref="questions")
    comments = relationship("QuestionComment", back_populates="question", cascade="all, delete-orphan")
    likes = relationship("QuestionLike", back_populates="question", cascade="all, delete-orphan")
    saves = relationship("QuestionSave", back_populates="question", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Question(id={self.id}, title='{self.title[:50]}...', category='{self.category}', status='{self.status}')>"
    
    def to_dict(self):
        """Convert question to dictionary (safe for API responses)"""
        return {
            "id": self.id,
            "title": self.title,
            "category": self.category,
            "content": self.content,
            "has_image": self.has_image,
            "image_path": self.image_path,
            "author_name": self.author_name,
            "is_anonymous": self.is_anonymous,
            "likes_count": self.likes_count,
            "comments_count": self.comments_count,
            "saves_count": self.saves_count,
            "status": self.status,
            "is_featured": self.is_featured,
            "user_id": self.user_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "user": {
                "id": self.user.id,
                "username": self.user.username,
                "email": self.user.email,
                "profile_image": self.user.profile_image
            } if self.user else None
        }


class QuestionComment(Base):
    __tablename__ = "question_comments"
    
    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("questions.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    text = Column(Text, nullable=False)
    is_anonymous = Column(Boolean, default=False, nullable=False)  # Allow anonymous comments
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationships
    question = relationship("Question", back_populates="comments")
    user = relationship("User")
    
    def to_dict(self):
        return {
            "id": self.id,
            "question_id": self.question_id,
            "user_id": self.user_id,
            "text": self.text,
            "is_anonymous": self.is_anonymous,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "user": {
                "id": self.user.id,
                "username": self.user.username,
                "email": self.user.email,
                "profile_image": self.user.profile_image
            } if self.user and not self.is_anonymous else None
        }


class QuestionLike(Base):
    __tablename__ = "question_likes"
    
    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("questions.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    question = relationship("Question", back_populates="likes")
    user = relationship("User")
    
    # Ensure unique likes per user per question
    __table_args__ = (UniqueConstraint('question_id', 'user_id', name='_question_user_uc'),)
    
    def to_dict(self):
        return {
            "id": self.id,
            "question_id": self.question_id,
            "user_id": self.user_id,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }


class QuestionSave(Base):
    __tablename__ = "question_saves"
    
    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("questions.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    question = relationship("Question", back_populates="saves")
    user = relationship("User")
    
    # Ensure unique saves per user per question
    __table_args__ = (UniqueConstraint('question_id', 'user_id', name='_question_save_user_uc'),)
    
    def to_dict(self):
        return {
            "id": self.id,
            "question_id": self.question_id,
            "user_id": self.user_id,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }