from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class MilestoneBase(BaseModel):
    label: str
    duration_seconds: int
    icon_code: int
    color_hex: str
    description: str
    is_active: bool = True

class MilestoneCreate(MilestoneBase):
    pass

class MilestoneResponse(MilestoneBase):
    id: int
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    class Config:
        orm_mode = True

class MilestoneWithStatus(MilestoneResponse):
    is_unlocked: bool

class UserMilestoneResponse(BaseModel):
    id: int
    user_id: int
    milestone_id: int
    unlocked_at: datetime
    milestone: MilestoneResponse

    class Config:
        orm_mode = True
