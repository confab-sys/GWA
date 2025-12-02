from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user_model import User
from app.models.content_model import Content
from app.models.comment_model import Comment
from app.models.notification_model import Notification
from app.schemas.content_schema import ContentCreate, ContentUpdate, ContentResponse, ContentListResponse
from app.schemas.comment_schema import CommentCreate, CommentResponse, CommentListResponse
from datetime import datetime

router = APIRouter()

@router.post("/", response_model=ContentResponse, status_code=status.HTTP_201_CREATED)
async def create_content(
    content: ContentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create new content (requires authentication)"""
    # Check if user has permission to create content
    if not (current_user.is_admin or current_user.is_content_creator):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to create content"
        )
    
    # Create content
    db_content = Content(
        title=content.title,
        body=content.body,
        topic=content.topic,
        post_type=content.post_type,
        image_path=content.image_path,
        is_text_only=content.is_text_only,
        author_name=content.author_name,
        author_avatar=content.author_avatar,
        status=content.status,
        is_featured=content.is_featured,
        created_by=current_user.id,
        published_at=datetime.utcnow() if content.status == "published" else None
    )
    
    db.add(db_content)
    db.commit()
    db.refresh(db_content)
    
    # Create notification for the new content
    try:
        import logging
        logger = logging.getLogger(__name__)
        
        notification = Notification(
            notification_type="content",
            title=f"New {db_content.post_type} Content: {db_content.title}",
            body=db_content.body[:200] + "..." if len(db_content.body) > 200 else db_content.body,
            content_id=db_content.id,
            author_name=db_content.author_name or current_user.username,
            author_avatar=db_content.author_avatar or current_user.profile_image,
            user_id=current_user.id,  # Notify the creator (or change to followers later)
            is_read=False
        )
        db.add(notification)
        db.commit()
        logger.info(f"Notification created for content {db_content.id}")
    except Exception as e:
        logger.error(f"Failed to create notification for content {db_content.id}: {e}")
        # Don't fail the content creation if notification fails
    
    return db_content.to_dict()

@router.get("/", response_model=ContentListResponse)
async def get_contents(
    skip: int = Query(0, ge=0, description="Number of items to skip"),
    limit: int = Query(10, ge=1, le=100, description="Number of items to return"),
    topic: Optional[str] = Query(None, description="Filter by topic"),
    post_type: Optional[str] = Query(None, description="Filter by post type (text/image)"),
    status: Optional[str] = Query("published", description="Filter by status"),
    search: Optional[str] = Query(None, description="Search in title and body"),
    db: Session = Depends(get_db)
):
    """Get published content with optional filters"""
    query = db.query(Content)
    
    # Apply status filter (default to published)
    if status:
        query = query.filter(Content.status == status)
    
    # Apply topic filter
    if topic:
        query = query.filter(Content.topic == topic)
    
    # Apply post type filter
    if post_type:
        query = query.filter(Content.post_type == post_type)
    
    # Apply search filter
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            (Content.title.ilike(search_term)) | (Content.body.ilike(search_term))
        )
    
    # Order by creation date (newest first)
    query = query.order_by(Content.created_at.desc())
    
    # Get total count
    total = query.count()
    
    # Apply pagination
    contents = query.offset(skip).limit(limit).all()
    
    return ContentListResponse(
        items=[content.to_dict() for content in contents],
        total=total,
        page=skip // limit + 1,
        size=limit,
        has_next=(skip + limit) < total,
        has_prev=skip > 0
    )

@router.get("/{content_id}", response_model=ContentResponse)
async def get_content(
    content_id: int,
    db: Session = Depends(get_db)
):
    """Get specific content by ID"""
    content = db.query(Content).filter(Content.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Content not found"
        )
    return content.to_dict()

@router.put("/{content_id}", response_model=ContentResponse)
async def update_content(
    content_id: int,
    content_update: ContentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update content (requires authentication and ownership/admin role)"""
    content = db.query(Content).filter(Content.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Content not found"
        )
    
    # Check permissions
    if not (current_user.is_admin or content.created_by == current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to update this content"
        )
    
    # Update fields
    update_data = content_update.dict(exclude_unset=True)
    
    # Handle status change
    if "status" in update_data and update_data["status"] == "published" and content.status != "published":
        update_data["published_at"] = datetime.utcnow()
    
    for field, value in update_data.items():
        setattr(content, field, value)
    
    content.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(content)
    
    return content

@router.delete("/{content_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_content(
    content_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete content (requires authentication and ownership/admin role)"""
    content = db.query(Content).filter(Content.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Content not found"
        )
    
    # Check permissions
    if not (current_user.is_admin or content.created_by == current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to delete this content"
        )
    
    db.delete(content)
    db.commit()

@router.post("/{content_id}/like", response_model=ContentResponse)
async def like_content(
    content_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Like content (increment like count)"""
    content = db.query(Content).filter(Content.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Content not found"
        )
    
    content.likes_count += 1
    db.commit()
    db.refresh(content)
    
    return content

@router.post("/{content_id}/unlike", response_model=ContentResponse)
async def unlike_content(
    content_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Unlike content (decrement like count, minimum 0)"""
    content = db.query(Content).filter(Content.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Content not found"
        )
    
    content.likes_count = max(0, content.likes_count - 1)
    db.commit()
    db.refresh(content)
    
    return content


# Comment endpoints
@router.post("/{content_id}/comments", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
async def create_comment(
    content_id: int,
    comment: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a comment on content"""
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        logger.info(f"Creating comment for content {content_id} by user {current_user.id}")
        logger.info(f"Comment text: {comment.text}")
        
        # Verify content exists
        content = db.query(Content).filter(Content.id == content_id).first()
        if not content:
            logger.error(f"Content {content_id} not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Content not found"
            )
        
        logger.info(f"Content found: {content.title}")
        
        # Create new comment
        new_comment = Comment(
            content_id=content_id,
            user_id=current_user.id,
            text=comment.text
        )
        
        db.add(new_comment)
        logger.info("Comment added to session")
        
        # Increment comment count
        content.comments_count += 1
        logger.info(f"Comment count incremented to {content.comments_count}")
        
        db.commit()
        logger.info("Database committed")
        
        db.refresh(new_comment)
        logger.info("Comment refreshed")
        
        # Return dictionary to ensure proper serialization
        return {
            "id": new_comment.id,
            "content_id": new_comment.content_id,
            "user_id": new_comment.user_id,
            "text": new_comment.text,
            "created_at": new_comment.created_at,
            "updated_at": new_comment.updated_at,
            "user": {
                "id": current_user.id,
                "username": current_user.username,
                "email": current_user.email
            }
        }
        
    except Exception as e:
        logger.error(f"Error creating comment: {str(e)}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating comment: {str(e)}"
        )


@router.get("/{content_id}/comments", response_model=CommentListResponse)
async def get_comments(
    content_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Get comments for content"""
    # Verify content exists
    content = db.query(Content).filter(Content.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Content not found"
        )
    
    # Get comments with pagination
    query = db.query(Comment).filter(Comment.content_id == content_id)
    total = query.count()
    comments = query.order_by(Comment.created_at.desc()).offset(skip).limit(limit).all()
    
    return CommentListResponse(
        items=[comment.to_dict() for comment in comments],
        total=total,
        page=skip // limit + 1,
        size=limit,
        has_next=(skip + limit) < total,
        has_prev=skip > 0
    )


@router.delete("/{content_id}/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_comment(
    content_id: int,
    comment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete a comment (requires ownership or admin role)"""
    comment = db.query(Comment).filter(
        Comment.id == comment_id,
        Comment.content_id == content_id
    ).first()
    
    if not comment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comment not found"
        )
    
    # Check permissions
    if not (current_user.is_admin or comment.user_id == current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to delete this comment"
        )
    
    # Decrement comment count
    content = db.query(Content).filter(Content.id == content_id).first()
    if content:
        content.comments_count = max(0, content.comments_count - 1)
    
    db.delete(comment)
    db.commit()