from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserResponse(BaseModel):
    id: int
    email: str
    username: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone_number: Optional[str] = None
    county: Optional[str] = None
    role: str
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class TopQuestionResponse(BaseModel):
    question: str
    count: int
    category: str
    
    class Config:
        from_attributes = True

class AnalyticsResponse(BaseModel):
    total_users: int
    active_users: int
    inactive_users: int
    counties: int
    total_questions: int
    recent_questions: int
    
    class Config:
        from_attributes = True