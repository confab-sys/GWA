from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime

class NotificationBase(BaseModel):
    notification_type: str = Field(..., min_length=1, max_length=20)
    title: str = Field(..., min_length=1, max_length=255)
    body: str = Field(..., min_length=1)
    content_id: Optional[int] = None
    question_id: Optional[int] = None
    author_name: str = Field(..., min_length=1, max_length=100)
    author_avatar: Optional[str] = Field(None, max_length=500)
    
    @validator('notification_type')
    def validate_notification_type(cls, v):
        valid_types = ["like", "comment", "follow", "mention", "system", "post"]
        if v not in valid_types:
            raise ValueError(f'Notification type must be one of: {valid_types}')
        return v

class NotificationCreate(NotificationBase):
    user_id: int
    is_read: bool = False

class NotificationUpdate(BaseModel):
    is_read: Optional[bool] = None

class NotificationResponse(NotificationBase):
    id: int
    user_id: int
    is_read: bool
    created_at: datetime
    updated_at: datetime
    
    model_config = {"from_attributes": True}

class NotificationListResponse(BaseModel):
    items: list[NotificationResponse]
    total: int
    unread_count: int
    
    model_config = {"from_attributes": True}