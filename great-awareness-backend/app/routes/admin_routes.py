from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List, Optional
from datetime import datetime, timedelta
import logging

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user_model import User
from app.models.question_model import Question
from app.schemas.admin_schema import UserResponse, TopQuestionResponse, AnalyticsResponse

router = APIRouter(prefix="/admin", tags=["admin"])
logger = logging.getLogger(__name__)

@router.get("/users", response_model=List[UserResponse])
async def get_all_users(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all users (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    try:
        users = db.query(User).offset(skip).limit(limit).all()
        
        # Convert users to response format manually to handle is_active field
        user_responses = []
        for user in users:
            user_responses.append({
                "id": user.id,
                "email": user.email,
                "username": user.username,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "phone_number": user.phone_number,
                "county": user.county,
                "role": user.role,
                "is_active": user.is_active,  # This uses the property
                "created_at": user.created_at
            })
        
        return user_responses
    except Exception as e:
        logger.error(f"Error fetching users: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch users: {str(e)}"
        )

@router.get("/questions/top", response_model=List[TopQuestionResponse])
async def get_top_questions(
    limit: int = 5,
    days: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get top questions by frequency (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    try:
        # Get questions from the last N days and group by similar titles/categories
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        
        # Simple approach: get all questions and count similar ones
        questions = db.query(Question).filter(
            Question.created_at >= cutoff_date
        ).order_by(desc(Question.created_at)).all()
        
        # Group by category and count
        category_counts = {}
        for question in questions:
            category = question.category
            if category in category_counts:
                category_counts[category] += 1
            else:
                category_counts[category] = 1
        
        # Create top questions response
        top_questions = []
        for category, count in sorted(category_counts.items(), key=lambda x: x[1], reverse=True)[:limit]:
            # Get a sample question from this category
            sample_question = db.query(Question).filter(
                Question.category == category
            ).first()
            
            if sample_question:
                top_questions.append({
                    "question": sample_question.title,
                    "count": count,
                    "category": category
                })
        
        return top_questions
    except Exception as e:
        logger.error(f"Error fetching top questions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch top questions"
        )

@router.get("/analytics", response_model=AnalyticsResponse)
async def get_analytics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get admin analytics (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    try:
        # Get user statistics
        total_users = db.query(User).count()
        active_users = db.query(User).filter(User.is_active == True).count()
        inactive_users = total_users - active_users
        
        # Get unique counties
        counties_result = db.query(User.county).filter(User.county != None).distinct().count()
        
        # Get question statistics
        total_questions = db.query(Question).count()
        
        # Get recent activity (last 30 days)
        thirty_days_ago = datetime.utcnow() - timedelta(days=30)
        recent_questions = db.query(Question).filter(
            Question.created_at >= thirty_days_ago
        ).count()
        
        return {
            "total_users": total_users,
            "active_users": active_users,
            "inactive_users": inactive_users,
            "counties": counties_result,
            "total_questions": total_questions,
            "recent_questions": recent_questions
        }
    except Exception as e:
        logger.error(f"Error fetching analytics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch analytics"
        )