from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class CommentBase(BaseModel):
    text: str = Field(..., min_length=1, max_length=1000)


class CommentCreate(CommentBase):
    content_id: int


class CommentResponse(CommentBase):
    id: int
    content_id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
    user: dict  # User info for the comment
    
    model_config = {"from_attributes": True}


class CommentListResponse(BaseModel):
    items: list[CommentResponse]
    total: int
    page: int
    size: int
    has_next: bool
    has_prev: bool