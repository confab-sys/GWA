from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime

class ContentBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    body: str = Field(..., min_length=1)
    topic: str = Field(..., min_length=1, max_length=100)
    post_type: str = Field(default="text", pattern="^(text|image)$")
    image_path: Optional[str] = Field(None, max_length=500)
    author_name: str = Field(default="Admin", max_length=100)
    author_avatar: Optional[str] = Field(None, max_length=500)
    
    @validator('body')
    def validate_body(cls, v):
        if len(v.strip()) < 10:
            raise ValueError('Content body must be at least 10 characters long')
        return v.strip()
    
    @validator('title')
    def validate_title(cls, v):
        if len(v.strip()) < 5:
            raise ValueError('Title must be at least 5 characters long')
        return v.strip()

class ContentCreate(ContentBase):
    is_text_only: bool = Field(default=True)
    status: str = Field(default="published", pattern="^(published|draft|archived)$")
    is_featured: bool = Field(default=False)

class ContentUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    body: Optional[str] = Field(None, min_length=1)
    topic: Optional[str] = Field(None, min_length=1, max_length=100)
    post_type: Optional[str] = Field(None, pattern="^(text|image)$")
    image_path: Optional[str] = Field(None, max_length=500)
    author_name: Optional[str] = Field(None, max_length=100)
    author_avatar: Optional[str] = Field(None, max_length=500)
    status: Optional[str] = Field(None, pattern="^(published|draft|archived)$")
    is_featured: Optional[bool] = None
    
    @validator('body')
    def validate_body(cls, v):
        if v is not None and len(v.strip()) < 10:
            raise ValueError('Content body must be at least 10 characters long')
        return v.strip() if v else v
    
    @validator('title')
    def validate_title(cls, v):
        if v is not None and len(v.strip()) < 5:
            raise ValueError('Title must be at least 5 characters long')
        return v.strip() if v else v

class ContentResponse(ContentBase):
    id: int
    is_text_only: bool
    likes_count: int
    comments_count: int
    status: str
    is_featured: bool
    created_at: datetime
    updated_at: datetime
    published_at: Optional[datetime]
    created_by: Optional[int]
    
    model_config = {"from_attributes": True}

class ContentListResponse(BaseModel):
    items: list[ContentResponse]
    total: int
    page: int
    size: int
    has_next: bool
    has_prev: bool