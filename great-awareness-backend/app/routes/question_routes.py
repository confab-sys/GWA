from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import logging

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user_model import User
from app.models.question_model import Question, QuestionComment, QuestionLike, QuestionSave
from app.schemas.question_schema import (
    QuestionCreate, QuestionUpdate, QuestionResponse, QuestionListResponse,
    QuestionCommentCreate, QuestionCommentResponse, QuestionCommentListResponse,
    QuestionCategoryResponse, QuestionStatsResponse
)

router = APIRouter()
logger = logging.getLogger(__name__)

# Categories from the frontend
QA_CATEGORIES = ['All', 'Addiction', 'Trauma', 'Relationships', 'Anxiety', 'Depression']


@router.post("/questions", response_model=QuestionResponse)
async def create_question(
    question_data: QuestionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new question"""
    try:
        # Validate category
        if question_data.category not in QA_CATEGORIES[1:]:  # Skip 'All'
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid category. Must be one of: {QA_CATEGORIES[1:]}"
            )
        
        # Set author name based on anonymity
        author_name = "Anonymous User" if question_data.is_anonymous else current_user.username
        
        new_question = Question(
            title=question_data.title,
            category=question_data.category,
            content=question_data.content,
            has_image=question_data.has_image,
            image_path=question_data.image_path,
            author_name=author_name,
            is_anonymous=question_data.is_anonymous,
            user_id=current_user.id,
            status="published"
        )
        
        db.add(new_question)
        db.commit()
        db.refresh(new_question)
        
        logger.info(f"Question created by user {current_user.id}: {new_question.id}")
        return new_question.to_dict()
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating question: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create question"
        )


@router.get("/questions", response_model=QuestionListResponse)
async def get_questions(
    category: Optional[str] = Query(None, description="Filter by category"),
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(10, ge=1, le=100, description="Items per page"),
    search: Optional[str] = Query(None, description="Search in title and content"),
    db: Session = Depends(get_db)
):
    """Get questions with pagination and filtering"""
    try:
        query = db.query(Question).filter(Question.status == "published")
        
        # Filter by category
        if category and category != "All":
            if category not in QA_CATEGORIES:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid category. Must be one of: {QA_CATEGORIES}"
                )
            query = query.filter(Question.category == category)
        
        # Search functionality
        if search:
            search_term = f"%{search}%"
            query = query.filter(
                (Question.title.ilike(search_term)) | 
                (Question.content.ilike(search_term))
            )
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        questions = query.order_by(Question.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        
        # Convert to dict format
        questions_data = [question.to_dict() for question in questions]
        
        total_pages = (total + per_page - 1) // per_page
        
        return {
            "questions": questions_data,
            "total": total,
            "page": page,
            "per_page": per_page,
            "total_pages": total_pages
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching questions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch questions"
        )


@router.get("/questions/categories", response_model=List[QuestionCategoryResponse])
async def get_question_categories(db: Session = Depends(get_db)):
    """Get question categories with counts"""
    try:
        from sqlalchemy import func
        
        # Get category counts
        category_counts = db.query(
            Question.category,
            func.count(Question.id).label('count')
        ).filter(Question.status == "published").group_by(Question.category).all()
        
        # Convert to response format
        categories = [
            {"category": cat, "count": count}
            for cat, count in category_counts
        ]
        
        return categories
        
    except Exception as e:
        logger.error(f"Error fetching question categories: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch categories"
        )


@router.get("/questions/{question_id}", response_model=QuestionResponse)
async def get_question(
    question_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific question by ID"""
    try:
        question = db.query(Question).filter(
            Question.id == question_id,
            Question.status == "published"
        ).first()
        
        if not question:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Question not found"
            )
        
        return question.to_dict()
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching question {question_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch question"
        )


@router.put("/questions/{question_id}", response_model=QuestionResponse)
async def update_question(
    question_id: int,
    question_data: QuestionUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a question (only by the creator)"""
    try:
        question = db.query(Question).filter(
            Question.id == question_id,
            Question.user_id == current_user.id
        ).first()
        
        if not question:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Question not found or you don't have permission to edit it"
            )
        
        # Update fields if provided
        if question_data.title is not None:
            question.title = question_data.title
        if question_data.category is not None:
            if question_data.category not in QA_CATEGORIES[1:]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Invalid category. Must be one of: {QA_CATEGORIES[1:]}"
                )
            question.category = question_data.category
        if question_data.content is not None:
            question.content = question_data.content
        if question_data.has_image is not None:
            question.has_image = question_data.has_image
        if question_data.image_path is not None:
            question.image_path = question_data.image_path
        if question_data.status is not None:
            question.status = question_data.status
        
        db.commit()
        db.refresh(question)
        
        logger.info(f"Question updated by user {current_user.id}: {question_id}")
        return question.to_dict()
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error updating question {question_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update question"
        )


@router.delete("/questions/{question_id}")
async def delete_question(
    question_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a question (only by the creator or admin)"""
    try:
        question = db.query(Question).filter(Question.id == question_id).first()
        
        if not question:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Question not found"
            )
        
        # Check permission (creator or admin)
        if question.user_id != current_user.id and current_user.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to delete this question"
            )
        
        db.delete(question)
        db.commit()
        
        logger.info(f"Question deleted by user {current_user.id}: {question_id}")
        return {"message": "Question deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error deleting question {question_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete question"
        )


@router.post("/questions/{question_id}/like")
async def toggle_question_like(
    question_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Toggle like on a question"""
    try:
        question = db.query(Question).filter(Question.id == question_id).first()
        
        if not question:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Question not found"
            )
        
        # Check if already liked
        existing_like = db.query(QuestionLike).filter(
            QuestionLike.question_id == question_id,
            QuestionLike.user_id == current_user.id
        ).first()
        
        if existing_like:
            # Unlike
            db.delete(existing_like)
            question.likes_count = max(0, question.likes_count - 1)
            action = "unliked"
        else:
            # Like
            new_like = QuestionLike(
                question_id=question_id,
                user_id=current_user.id
            )
            db.add(new_like)
            question.likes_count += 1
            action = "liked"
        
        db.commit()
        
        logger.info(f"Question {action} by user {current_user.id}: {question_id}")
        return {
            "message": f"Question {action} successfully",
            "likes_count": question.likes_count,
            "is_liked": action == "liked"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error toggling like on question {question_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to toggle like"
        )


@router.post("/questions/{question_id}/save")
async def toggle_question_save(
    question_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Toggle save on a question"""
    try:
        question = db.query(Question).filter(Question.id == question_id).first()
        
        if not question:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Question not found"
            )
        
        # Check if already saved
        existing_save = db.query(QuestionSave).filter(
            QuestionSave.question_id == question_id,
            QuestionSave.user_id == current_user.id
        ).first()
        
        if existing_save:
            # Unsave
            db.delete(existing_save)
            question.saves_count = max(0, question.saves_count - 1)
            action = "unsaved"
        else:
            # Save
            new_save = QuestionSave(
                question_id=question_id,
                user_id=current_user.id
            )
            db.add(new_save)
            question.saves_count += 1
            action = "saved"
        
        db.commit()
        
        logger.info(f"Question {action} by user {current_user.id}: {question_id}")
        return {
            "message": f"Question {action} successfully",
            "saves_count": question.saves_count,
            "is_saved": action == "saved"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error toggling save on question {question_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to toggle save"
        )


@router.post("/questions/{question_id}/comments", response_model=QuestionCommentResponse)
async def create_question_comment(
    question_id: int,
    comment_data: QuestionCommentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a comment on a question"""
    try:
        question = db.query(Question).filter(Question.id == question_id).first()
        
        if not question:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Question not found"
            )
        
        new_comment = QuestionComment(
            question_id=question_id,
            user_id=current_user.id,
            text=comment_data.text,
            is_anonymous=comment_data.is_anonymous
        )
        
        db.add(new_comment)
        question.comments_count += 1
        db.commit()
        db.refresh(new_comment)
        
        logger.info(f"Comment created on question {question_id} by user {current_user.id}")
        return new_comment.to_dict()
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating comment on question {question_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create comment"
        )


@router.get("/questions/{question_id}/comments", response_model=QuestionCommentListResponse)
async def get_question_comments(
    question_id: int,
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Comments per page"),
    db: Session = Depends(get_db)
):
    """Get comments for a specific question"""
    try:
        question = db.query(Question).filter(Question.id == question_id).first()
        
        if not question:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Question not found"
            )
        
        query = db.query(QuestionComment).filter(QuestionComment.question_id == question_id)
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        comments = query.order_by(QuestionComment.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        
        # Convert to dict format
        comments_data = [comment.to_dict() for comment in comments]
        
        return {
            "comments": comments_data,
            "total": total
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching comments for question {question_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch comments"
        )


@router.get("/questions/categories", response_model=List[QuestionCategoryResponse])
async def get_question_categories(db: Session = Depends(get_db)):
    """Get question categories with counts"""
    try:
        from sqlalchemy import func
        
        # Get category counts
        category_counts = db.query(
            Question.category,
            func.count(Question.id).label('count')
        ).filter(Question.status == "published").group_by(Question.category).all()
        
        # Convert to response format
        categories = [
            {"category": cat, "count": count}
            for cat, count in category_counts
        ]
        
        return categories
        
    except Exception as e:
        logger.error(f"Error fetching question categories: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch categories"
        )


@router.get("/questions/stats", response_model=QuestionStatsResponse)
async def get_question_stats(db: Session = Depends(get_db)):
    """Get Q&A statistics"""
    try:
        from sqlalchemy import func
        
        # Total questions
        total_questions = db.query(Question).filter(Question.status == "published").count()
        
        # Total categories
        total_categories = db.query(Question.category).filter(Question.status == "published").distinct().count()
        
        # Most popular category
        most_popular = db.query(
            Question.category,
            func.count(Question.id).label('count')
        ).filter(Question.status == "published").group_by(Question.category).order_by(func.count(Question.id).desc()).first()
        
        most_popular_category = most_popular[0] if most_popular else "None"
        
        # Total comments
        total_comments = db.query(QuestionComment).join(Question).filter(Question.status == "published").count()
        
        # Total likes
        total_likes = db.query(QuestionLike).join(Question).filter(Question.status == "published").count()
        
        return {
            "total_questions": total_questions,
            "total_categories": total_categories,
            "most_popular_category": most_popular_category,
            "total_comments": total_comments,
            "total_likes": total_likes
        }
        
    except Exception as e:
        logger.error(f"Error fetching question stats: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch statistics"
        )