from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.wellness_model import Milestone, UserMilestone
from app.models.user_model import User
from app.schemas.wellness_schema import MilestoneResponse, MilestoneWithStatus, UserMilestoneResponse

router = APIRouter(
    prefix="/wellness",
    tags=["wellness"]
)

DEFAULT_MILESTONES = [
    {
        "label": "1 Day",
        "duration_seconds": 86400,
        "icon_code": 0xf55b, # fa-award
        "color_hex": "#4CAF50",
        "description": "Completed your first 24 hours of wellness."
    },
    {
        "label": "3 Days",
        "duration_seconds": 259200,
        "icon_code": 0xf091, # fa-trophy
        "color_hex": "#2196F3",
        "description": "Kept the streak alive for 3 days!"
    },
    {
        "label": "1 Week",
        "duration_seconds": 604800,
        "icon_code": 0xf005, # fa-star
        "color_hex": "#9C27B0",
        "description": "One full week of dedication."
    },
    {
        "label": "2 Weeks",
        "duration_seconds": 1209600,
        "icon_code": 0xf006, # fa-star-half-alt (approx)
        "color_hex": "#FF9800",
        "description": "Two weeks strong. You're building a habit."
    },
    {
        "label": "1 Month",
        "duration_seconds": 2592000,
        "icon_code": 0xf0a3, # fa-certificate
        "color_hex": "#E91E63",
        "description": "A whole month of wellness!"
    }
]

@router.post("/init", response_model=List[MilestoneResponse])
def initialize_milestones(db: Session = Depends(get_db)):
    """
    Seeds the database with the default milestones. 
    Idempotent: updates existing ones if they exist (based on duration).
    """
    results = []
    for m_data in DEFAULT_MILESTONES:
        existing = db.query(Milestone).filter(Milestone.duration_seconds == m_data["duration_seconds"]).first()
        if existing:
            # Update fields
            existing.label = m_data["label"]
            existing.icon_code = m_data["icon_code"]
            existing.color_hex = m_data["color_hex"]
            existing.description = m_data["description"]
            results.append(existing)
        else:
            new_milestone = Milestone(**m_data)
            db.add(new_milestone)
            results.append(new_milestone)
    
    db.commit()
    for r in results:
        db.refresh(r)
    return results

@router.get("/milestones", response_model=List[MilestoneWithStatus])
def get_milestones(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all milestones and status for the current user.
    """
    milestones = db.query(Milestone).filter(Milestone.is_active == True).order_by(Milestone.duration_seconds).all()
    
    # Get user's unlocked milestones
    user_milestones = db.query(UserMilestone).filter(UserMilestone.user_id == current_user.id).all()
    unlocked_ids = {um.milestone_id for um in user_milestones}
    
    response = []
    for m in milestones:
        m_resp = MilestoneWithStatus.from_orm(m)
        m_resp.is_unlocked = m.id in unlocked_ids
        response.append(m_resp)
        
    return response

@router.post("/unlock/{milestone_id}", response_model=UserMilestoneResponse)
def unlock_milestone(
    milestone_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Manually unlock a milestone for testing purposes.
    In production, this would be triggered by a background worker or event.
    """
    milestone = db.query(Milestone).filter(Milestone.id == milestone_id).first()
    if not milestone:
        raise HTTPException(status_code=404, detail="Milestone not found")
        
    existing = db.query(UserMilestone).filter(
        UserMilestone.user_id == current_user.id,
        UserMilestone.milestone_id == milestone_id
    ).first()
    
    if existing:
        return existing
        
    new_unlock = UserMilestone(user_id=current_user.id, milestone_id=milestone_id)
    db.add(new_unlock)
    db.commit()
    db.refresh(new_unlock)
    return new_unlock
