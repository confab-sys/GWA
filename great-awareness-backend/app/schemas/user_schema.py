from pydantic import BaseModel, EmailStr, validator, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    phone_number: Optional[str] = Field(None, max_length=20)
    county: Optional[str] = Field(None, max_length=100)
    verified_otp: Optional[str] = Field(None, max_length=6)
    device_id_hash: Optional[str] = Field(None, max_length=255)
    
    @validator('username')
    def validate_username(cls, v):
        if not v.isalnum() and '_' not in v:
            raise ValueError('Username must contain only letters, numbers, and underscores')
        return v.lower()

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=100)
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least one digit')
        if not any(char.isupper() for char in v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not any(char.islower() for char in v):
            raise ValueError('Password must contain at least one lowercase letter')
        return v

class UserUpdate(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr] = None
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    phone_number: Optional[str] = Field(None, max_length=20)
    county: Optional[str] = Field(None, max_length=100)
    profile_image: Optional[str] = Field(None, max_length=500)
    status: Optional[str] = Field(None, pattern="^(active|inactive|suspended)$")
    role: Optional[str] = Field(None, pattern="^(user|admin|content_creator)$")
    is_verified: Optional[bool] = None
    verified_otp: Optional[str] = Field(None, max_length=6)
    device_id_hash: Optional[str] = Field(None, max_length=255)
    
    @validator('username')
    def validate_username(cls, v):
        if v and not v.isalnum() and '_' not in v:
            raise ValueError('Username must contain only letters, numbers, and underscores')
        return v.lower() if v else v

class UserInDB(UserBase):
    id: int
    status: str
    role: str
    is_verified: bool
    profile_image: Optional[str]
    created_at: datetime
    updated_at: datetime
    last_login: Optional[datetime]
    first_name: Optional[str]
    last_name: Optional[str]
    phone_number: Optional[str]
    county: Optional[str]
    verified_otp: Optional[str]
    device_id_hash: Optional[str]
    
    class Config:
        from_attributes = True

class UserResponse(UserInDB):
    pass

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserRegister(UserCreate):
    """Extended user registration schema with device identification"""
    device_id_hash: Optional[str] = Field(None, max_length=255)
    verified_otp: Optional[str] = Field(None, max_length=6)

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int

class TokenData(BaseModel):
    email: Optional[str] = None