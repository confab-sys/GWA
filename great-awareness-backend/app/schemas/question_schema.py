from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class QuestionCreate(BaseModel):
    """Schema for creating a new question"""
    title: str = Field(..., min_length=10, max_length=500, description="Question title/text")
    category: str = Field(..., description="Question category")
    content: str = Field(..., min_length=10, max_length=5000, description="Detailed question description")
    has_image: bool = Field(default=False, description="Whether question has an image")
    image_path: Optional[str] = Field(None, description="Path to question image")
    is_anonymous: bool = Field(default=False, description="Whether to post anonymously")


class QuestionUpdate(BaseModel):
    """Schema for updating a question"""
    title: Optional[str] = Field(None, min_length=10, max_length=500, description="Question title/text")
    category: Optional[str] = Field(None, description="Question category")
    content: Optional[str] = Field(None, min_length=10, max_length=5000, description="Detailed question description")
    has_image: Optional[bool] = Field(None, description="Whether question has an image")
    image_path: Optional[str] = Field(None, description="Path to question image")
    status: Optional[str] = Field(None, description="Question status")


class QuestionResponse(BaseModel):
    """Schema for question responses"""
    id: int
    title: str
    category: str
    content: str
    has_image: bool
    image_path: Optional[str]
    author_name: str
    is_anonymous: bool
    likes_count: int
    comments_count: int
    saves_count: int
    status: str
    is_featured: bool
    user_id: int
    created_at: datetime
    updated_at: datetime
    user: Optional[dict]
    
    class Config:
        from_attributes = True


class QuestionListResponse(BaseModel):
    """Schema for paginated question list"""
    questions: List[QuestionResponse]
    total: int
    page: int
    per_page: int
    total_pages: int


class QuestionCommentCreate(BaseModel):
    """Schema for creating a question comment"""
    text: str = Field(..., min_length=1, max_length=1000, description="Comment text")
    is_anonymous: bool = Field(default=False, description="Whether to comment anonymously")


class QuestionCommentResponse(BaseModel):
    """Schema for question comment responses"""
    id: int
    question_id: int
    user_id: int
    text: str
    is_anonymous: bool
    created_at: datetime
    updated_at: datetime
    user: Optional[dict]
    
    class Config:
        from_attributes = True


class QuestionCommentListResponse(BaseModel):
    """Schema for question comment list"""
    comments: List[QuestionCommentResponse]
    total: int


class QuestionCategoryResponse(BaseModel):
    """Schema for question categories"""
    category: str
    count: int


class QuestionStatsResponse(BaseModel):
    """Schema for question statistics"""
    total_questions: int
    total_categories: int
    most_popular_category: str
    total_comments: int
    total_likes: int