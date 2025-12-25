# GWA Cloudflare Backend Setup Guide

This document details the complete process of setting up the Great Awareness (GWA) backend infrastructure on Cloudflare Workers, D1, and R2.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Database Setup](#database-setup)
5. [Worker Configuration](#worker-configuration)
6. [API Endpoints](#api-endpoints)
7. [Authentication System](#authentication-system)
8. [Image Storage](#image-storage)
9. [Deployment Process](#deployment-process)
10. [Frontend Integration](#frontend-integration)
11. [Security Considerations](#security-considerations)
12. [Next Steps](#next-steps)

## Overview

The GWA backend has been migrated from a traditional Python/PostgreSQL stack to a serverless architecture using:
- **Cloudflare Workers** for API endpoints
- **Cloudflare D1** for SQLite-compatible database
- **Cloudflare R2** for object storage (images)

## Architecture

```
Frontend (Flutter)  <--->  Cloudflare Workers  <--->  D1 Database
                                    |
                                    v
                               R2 Buckets (Images)
```

## Prerequisites

- Node.js installed
- Wrangler CLI installed globally: `npm install -g wrangler`
- Cloudflare account with Workers, D1, and R2 enabled
- Authenticated Wrangler: `wrangler login`

## Database Setup

### 1. Create D1 Database

```bash
wrangler d1 create gwa-main-db
```

### 2. Database Schema

The complete schema is defined in `schema_full.sql` with the following tables:

- **users**: User accounts with authentication
- **contents**: Posts and articles
- **questions**: Q&A entries
- **comments**: User comments on content
- **question_comments**: Comments on questions
- **question_likes**: Like tracking for questions
- **question_saves**: Save tracking for questions
- **notifications**: User notifications

### 3. Apply Schema

```bash
wrangler d1 execute gwa-main-db --file=schema_full.sql
```

## Worker Configuration

### wrangler-main.toml

```toml
name = "gwa-main-worker"
main = "workers/main-worker.js"
compatibility_date = "2024-01-01"

[[d1_databases]]
binding = "DB"
database_name = "gwa-main-db"
database_id = "your-database-id"

[[r2_buckets]]
binding = "GWA_USERS_BUCKET"
bucket_name = "gwa-users"

[[r2_buckets]]
binding = "GWA_CONTENT_BUCKET"
bucket_name = "gwa-content"
```

## API Endpoints

### Authentication

#### User Signup
```http
POST /api/auth/signup
Content-Type: application/json

{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "message": "User created successfully"
}
```

#### User Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "token": "dummy-jwt-token-placeholder"
}
```

### Content Management

#### Get All Users
```http
GET /api/users
```

#### Get All Contents
```http
GET /api/contents
```

#### Create Content
```http
POST /api/contents
Content-Type: application/json

{
  "title": "My New Post",
  "body": "This is the content body...",
  "topic": "technology",
  "post_type": "text",
  "author_name": "johndoe"
}
```

#### Get All Questions
```http
GET /api/questions
```

### Image Management

#### Upload Profile Image
```http
POST /api/users/upload-profile
Content-Type: multipart/form-data

file: [image file]
user_id: [optional user ID]
```

**Response:**
```json
{
  "message": "Profile image uploaded successfully",
  "key": "user123-1735123456789.jpg",
  "url": "/api/images/profile/user123-1735123456789.jpg"
}
```

#### Upload Content Image
```http
POST /api/contents/upload-image
Content-Type: multipart/form-data

file: [image file]
```

**Response:**
```json
{
  "message": "Content image uploaded successfully",
  "key": "uuid-1234-5678.jpg",
  "url": "/api/images/content/uuid-1234-5678.jpg"
}
```

#### Serve Profile Image
```http
GET /api/images/profile/{key}
```

#### Serve Content Image
```http
GET /api/images/content/{key}
```

## Authentication System

### Password Security
- Uses **PBKDF2** with **SHA-256**
- **100,000 iterations**
- **16-byte random salt**
- Passwords stored as `salt:hash` format

### Implementation Details
```javascript
async function hashPassword(password, salt) {
  const keyMaterial = await crypto.subtle.importKey(
    "raw", 
    new TextEncoder().encode(password), 
    { name: "PBKDF2" }, 
    false, 
    ["deriveBits", "deriveKey"]
  );
  
  const key = await crypto.subtle.deriveKey(
    {
      name: "PBKDF2",
      salt: salt,
      iterations: 100000,
      hash: "SHA-256"
    },
    keyMaterial,
    { name: "AES-GCM", length: 256 },
    true,
    ["encrypt", "decrypt"]
  );
  
  return new Uint8Array(await crypto.subtle.exportKey("raw", key));
}
```

## Image Storage

### R2 Bucket Structure
- **gwa-users**: Stores user profile images
- **gwa-content**: Stores content/post images

### Image Key Generation
- **Profile images**: `{userId}-{timestamp}.{extension}` or `{uuid}.{extension}`
- **Content images**: `{uuid}.{extension}`

### CORS Configuration
All endpoints include proper CORS headers:
```javascript
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, HEAD, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};
```

## Deployment Process

### 1. Deploy Main Worker
```bash
cd great-awareness-backend
npx wrangler deploy --config=workers/wrangler-main.toml
```

### 2. Verify Deployment
Check the deployment output for:
- Worker URL
- Database bindings
- R2 bucket bindings

### 3. Test Endpoints
Use curl or Postman to test the endpoints:
```bash
# Test health endpoint
curl https://gwa-main-worker.aashardcustomz.workers.dev/api/health

# Test signup
curl -X POST https://gwa-main-worker.aashardcustomz.workers.dev/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"test123"}'
```

## Frontend Integration

### Flutter Integration Example
```dart
// Signup
final response = await http.post(
  Uri.parse('https://gwa-main-worker.aashardcustomz.workers.dev/api/auth/signup'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'username': username,
    'email': email,
    'password': password,
  }),
);

// Upload profile image
var request = http.MultipartRequest(
  'POST',
  Uri.parse('https://gwa-main-worker.aashardcustomz.workers.dev/api/users/upload-profile'),
);
request.files.add(await http.MultipartFile.fromPath('file', imagePath));
request.fields['user_id'] = userId;
```

## Security Considerations

### Current Implementation
- ✅ Password hashing with PBKDF2
- ✅ CORS headers configured
- ✅ Input validation on signup/login
- ✅ Error handling without exposing sensitive data

### TODO: Enhance Security
- [ ] Implement JWT token generation
- [ ] Add rate limiting
- [ ] Implement input sanitization
- [ ] Add request logging
- [ ] Implement proper session management

## Next Steps

### Immediate Priorities
1. **Implement JWT Authentication**: Replace the dummy token with real JWT signing
2. **User Profile Management**: Add endpoints for updating user profiles
3. **Content Creation**: Link content creation to authenticated users
4. **Image Association**: Link uploaded images to user/content records

### Future Enhancements
- [ ] Add email verification
- [ ] Implement password reset functionality
- [ ] Add role-based access control
- [ ] Implement caching strategies
- [ ] Add monitoring and analytics

## Files Created/Modified

### Backend Files
- `great-awareness-backend/workers/main-worker.js` - Main API worker
- `great-awareness-backend/workers/wrangler-main.toml` - Worker configuration
- `great-awareness-backend/workers/schema_full.sql` - Database schema

### Frontend Integration
- Update Flutter app to use new API endpoints
- Implement authentication flow
- Add image upload functionality

## Support

For issues or questions:
1. Check Cloudflare Workers dashboard for logs
2. Verify D1 database connections
3. Ensure R2 bucket permissions are correct
4. Test endpoints using curl/Postman before frontend integration

---

**Last Updated**: December 2024  
**Worker URL**: https://gwa-main-worker.aashardcustomz.workers.dev  
**Status**: ✅ Authentication system deployed and functional