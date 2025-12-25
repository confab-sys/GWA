from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from passlib.context import CryptContext
import jwt
from datetime import datetime, timedelta, timezone
# Import models in dependency order (Content before User due to relationships)
from app.models.content_model import Content
from app.models.user_model import User
from app.schemas.user_schema import UserCreate, UserResponse, UserLogin, Token, UserRegister
from app.core.database import get_db
from app.core.config import settings
from app.core.dependencies import get_current_user

router = APIRouter()
# Use pbkdf2_sha256 to avoid bcrypt 72-byte limitation issues
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=settings.access_token_expire_minutes))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.secret_key, algorithm="HS256")

@router.post("/register", response_model=UserResponse)
def register(user: UserRegister, db: Session = Depends(get_db)):
    # Strict single-identity validation
    
    # Check if email already exists
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Check if username already exists
    db_user = db.query(User).filter(User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already taken")
    
    # Check if phone number already exists and is verified
    if user.phone_number:
        db_user = db.query(User).filter(User.phone_number == user.phone_number, User.verified_otp.isnot(None)).first()
        if db_user:
            raise HTTPException(
                status_code=409, 
                detail="This phone number is already associated with a verified account. Please log in to your existing account."
            )
    
    # Check if device ID already exists and is registered
    if user.device_id_hash:
        db_user = db.query(User).filter(User.device_id_hash == user.device_id_hash).first()
        if db_user:
            raise HTTPException(
                status_code=409, 
                detail="This device is already registered to an existing account. Please log in to your existing account."
            )
    
    # Check if OTP is already verified for another account
    if user.verified_otp:
        db_user = db.query(User).filter(User.verified_otp == user.verified_otp).first()
        if db_user:
            raise HTTPException(
                status_code=409, 
                detail="This verification code is already associated with a verified account. Please log in to your existing account."
            )
    
    # Create new user with enhanced model
    hashed_password = get_password_hash(user.password)
    new_user = User(
        email=user.email,
        username=user.username,
        password_hash=hashed_password,
        first_name=user.first_name,
        last_name=user.last_name,
        phone_number=user.phone_number,
        county=user.county,
        status="active",
        role="user",
        is_verified=False,
        verified_otp=user.verified_otp,
        device_id_hash=user.device_id_hash
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Return user data as dict to match UserResponse schema
    return {
        "id": new_user.id,
        "email": new_user.email,
        "username": new_user.username,
        "first_name": new_user.first_name,
        "last_name": new_user.last_name,
        "phone_number": new_user.phone_number,
        "county": new_user.county,
        "status": new_user.status,
        "role": new_user.role,
        "is_verified": new_user.is_verified,
        "profile_image": new_user.profile_image,
        "created_at": new_user.created_at,
        "updated_at": new_user.updated_at,
        "last_login": new_user.last_login,
        "verified_otp": new_user.verified_otp,
        "device_id_hash": new_user.device_id_hash
    }

@router.post("/login", response_model=Token)
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if not db_user or not verify_password(user.password, db_user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    access_token = create_access_token({"sub": db_user.email})
    return {"access_token": access_token, "token_type": "bearer", "expires_in": settings.access_token_expire_minutes * 60}

@router.get("/verify")
def verify(token: str):
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=["HS256"])
        email = payload.get("sub")
        if email is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return {"email": email}
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

@router.get("/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return {
        "id": current_user.id,
        "email": current_user.email,
        "username": current_user.username,
        "first_name": current_user.first_name,
        "last_name": current_user.last_name,
        "phone_number": current_user.phone_number,
        "county": current_user.county,
        "status": current_user.status,
        "role": current_user.role,
        "is_verified": current_user.is_verified,
        "profile_image": current_user.profile_image,
        "created_at": current_user.created_at,
        "updated_at": current_user.updated_at,
        "last_login": current_user.last_login,
        "verified_otp": current_user.verified_otp,
        "device_id_hash": current_user.device_id_hash
    }

class ForgotPasswordRequest(BaseModel):
    email: str

@router.post("/forgot-password")
def forgot_password(request: ForgotPasswordRequest):
    # In a real app, send email here.
    return {"message": "If this email is registered, you will receive a password reset link."}
