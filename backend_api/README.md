# Factorio Mod Validator - Backend API

Production-ready REST API for Factorio mod validation with JWT authentication.

## Features

- **JWT Authentication**: Secure token-based authentication
- **User Management**: Registration, login, profile management
- **File Upload**: Secure Lua file and ZIP archive uploads
- **Validation Services**: Real-time mod validation
- **Rate Limiting**: Protection against abuse (100 requests/15 min)
- **Security**: Helmet.js security headers, CORS configuration
- **Logging**: Morgan HTTP request logging
- **Admin Panel**: User and system management

## Installation

```bash
npm install
```

## Configuration

Create a `.env` file:

```env
PORT=3001
JWT_SECRET=your-secret-key-change-in-production
UPLOAD_DIR=./uploads
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com
LUA_VALIDATOR_PATH=../tests/validation_engine.lua
NODE_ENV=production
```

## Running

### Development
```bash
npm run dev
```

### Production
```bash
npm start
```

### With PM2
```bash
pm2 start server.js --name factorio-api
```

## API Endpoints

### Authentication

#### Register
```bash
POST /api/auth/register
Content-Type: application/json

{
  "username": "user1",
  "password": "securepass",
  "email": "user@example.com"
}
```

#### Login
```bash
POST /api/auth/login
Content-Type: application/json

{
  "username": "user1",
  "password": "securepass"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "username": "user1",
    "email": "user@example.com",
    "role": "user"
  }
}
```

#### Get Profile
```bash
GET /api/auth/profile
Authorization: Bearer YOUR_TOKEN
```

### Validation

#### Validate Lua File
```bash
POST /api/validate/file
Authorization: Bearer YOUR_TOKEN
Content-Type: multipart/form-data

file: control.lua
```

#### Validate ZIP Archive
```bash
POST /api/validate/archive
Authorization: Bearer YOUR_TOKEN
Content-Type: multipart/form-data

archive: my-mod.zip
```

#### Get Validation History
```bash
GET /api/validate/history
Authorization: Bearer YOUR_TOKEN
```

### Admin (Admin role required)

#### List Users
```bash
GET /api/admin/users
Authorization: Bearer ADMIN_TOKEN
```

#### Delete User
```bash
DELETE /api/admin/users/:username
Authorization: Bearer ADMIN_TOKEN
```

#### System Statistics
```bash
GET /api/admin/stats
Authorization: Bearer ADMIN_TOKEN
```

### Health

#### Health Check
```bash
GET /api/health
```

#### API Documentation
```bash
GET /api/docs
```

## Default Credentials

```
Username: admin
Password: admin123
```

**⚠️ Change these in production!**

## Security Features

- JWT token authentication
- Password hashing with bcryptjs
- Rate limiting (100 requests per 15 minutes)
- Helmet.js security headers
- CORS configuration
- File type validation (.lua, .zip only)
- File size limits (50MB max)
- Request body size limits (10MB)

## Error Handling

All endpoints return JSON responses:

**Success:**
```json
{
  "message": "Operation successful",
  "data": {...}
}
```

**Error:**
```json
{
  "error": "Error description",
  "details": "Additional details (dev mode only)"
}
```

## HTTP Status Codes

- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing/invalid token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

## Rate Limiting

- Window: 15 minutes
- Max requests: 100 per IP
- Applies to: All `/api/` endpoints

## Testing

```bash
npm test
```

## Docker Deployment

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3001
CMD ["node", "server.js"]
```

```bash
docker build -t factorio-api .
docker run -p 3001:3001 -e JWT_SECRET=your-secret factorio-api
```

## License

MIT
