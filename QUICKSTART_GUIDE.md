# 🚀 Kheti Sahayak - Quick Start Guide

## ⚡ Get Started in 5 Minutes

This guide will help you quickly set up and run the Kheti Sahayak agricultural platform.

---

## 📋 Prerequisites

Ensure you have the following installed:

| Requirement | Version | Check Command |
|------------|---------|---------------|
| **Java** | 17+ | `java -version` |
| **Maven** | 3.6+ | `mvn -version` |
| **PostgreSQL** | 14+ | `psql --version` |
| **Redis** | 6.2+ | `redis-cli --version` |
| **Node.js** | 18+ | `node --version` |
| **Git** | Latest | `git --version` |

---

## 🔧 Installation Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/automotiv/khetisahayak.git
cd khetisahayak
```

### Step 2: Set Up PostgreSQL Database

```bash
# Start PostgreSQL service
# Windows:
net start postgresql-x64-14

# Linux/Mac:
sudo systemctl start postgresql
# or
brew services start postgresql

# Create database
createdb kheti_sahayak

# Or using psql:
psql -U postgres
CREATE DATABASE kheti_sahayak;
\q
```

### Step 3: Set Up Redis Cache

```bash
# Start Redis server
# Windows (if installed):
redis-server

# Linux/Mac:
sudo systemctl start redis
# or
brew services start redis

# Verify Redis is running:
redis-cli ping
# Should return: PONG
```

### Step 4: Configure Environment Variables

Create application-local.yml or set environment variables:

```bash
# Set environment variables (Linux/Mac)
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=kheti_sahayak
export DB_USER=postgres
export DB_PASSWORD=your_password
export REDIS_HOST=localhost
export REDIS_PORT=6379
export JWT_SECRET=your-secure-jwt-secret-key
export ML_SERVICE_URL=http://localhost:8000
export WEATHER_API_KEY=your-openweathermap-api-key

# Or create a .env file in kheti_sahayak_spring_boot/
```

### Step 5: Build and Run Spring Boot Backend

```bash
cd kheti_sahayak_spring_boot

# Install dependencies and run database migrations
./mvnw clean install

# Run the application
./mvnw spring-boot:run

# Or run the JAR directly:
# ./mvnw package
# java -jar target/kheti-sahayak-0.0.1-SNAPSHOT.jar
```

The backend should now be running at http://localhost:8080

### Step 6: Verify Backend is Running

```bash
# Health check
curl http://localhost:8080/api/health

# Should return:
# {"status":"UP","message":"OK","timestamp":"2025-10-01T..."}
```

### Step 7: Access API Documentation

Open your browser and navigate to:

**Swagger UI:** http://localhost:8080/api-docs

You can now:
- ✅ View all available endpoints
- ✅ Test APIs interactively
- ✅ See request/response examples
- ✅ Understand authentication requirements

### Step 8: Run Frontend (Optional)

```bash
# In a new terminal
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev

# Frontend will be available at http://localhost:5173
```

---

## 🧪 Quick Test - Verify All Features

### 1. Test Health Check

```bash
curl http://localhost:8080/api/health
```

**Expected Response:**
```json
{
  "status": "UP",
  "message": "OK",
  "timestamp": "2025-10-01T...",
  "checks": {
    "database": "UP",
    "redis": "UP"
  }
}
```

### 2. Test Educational Content

```bash
# Get all educational content
curl http://localhost:8080/api/education/content

# Get featured content
curl http://localhost:8080/api/education/content/featured

# Get categories
curl http://localhost:8080/api/education/categories

# Search content
curl "http://localhost:8080/api/education/content/search?q=rice"
```

### 3. Test Weather Service

```bash
# Get weather for a location
curl "http://localhost:8080/api/weather?latitude=19.9975&longitude=73.7898"

# Get 5-day forecast
curl "http://localhost:8080/api/weather/forecast?latitude=19.9975&longitude=73.7898"
```

### 4. Test User Registration

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "9876543210",
    "fullName": "Test Farmer",
    "primaryCrop": "Rice",
    "state": "Maharashtra",
    "district": "Nashik",
    "farmSize": 2.5,
    "userType": "FARMER"
  }'
```

### 5. Test Authentication Flow

```bash
# Step 1: Register and get OTP
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"mobileNumber":"9876543210","fullName":"Test Farmer"}'

# Step 2: Verify OTP (use OTP from response or logs)
curl -X POST http://localhost:8080/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"mobileNumber":"9876543210","otp":"123456"}'

# Step 3: Use the JWT token for authenticated requests
TOKEN="<your-jwt-token-here>"
curl http://localhost:8080/api/notifications \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🗄️ Database Verification

### Check Tables Created

```bash
# Connect to database
psql -U postgres -d kheti_sahayak

# List all tables
\dt

# You should see:
# users
# products
# marketplace_orders
# order_items
# crop_diagnosis
# treatment_steps
# educational_content
# content_tags
# notifications

# Check sample data
SELECT * FROM educational_content LIMIT 5;
SELECT * FROM notifications WHERE user_id = 1;

# Exit
\q
```

---

## 🎯 Available Endpoints

### **Public Endpoints (No Authentication Required):**

- `GET /` - API information
- `GET /api/health` - Health check
- `GET /api-docs` - Swagger documentation
- `GET /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/weather` - Weather data
- `GET /api/education/content/**` - Educational content (read-only)
- `GET /api/education/categories` - Content categories

### **Authenticated Endpoints (JWT Token Required):**

#### Authentication & Profile
- `GET/PUT /api/auth/profile` - User profile management

#### Crop Diagnostics
- `POST /api/diagnostics/upload` - Upload crop image for diagnosis
- `GET /api/diagnostics` - Get diagnostic history
- `POST /api/diagnostics/{id}/expert-review` - Request expert review

#### Marketplace
- `GET /api/marketplace/products` - Browse products
- `POST /api/marketplace/products` - Create product listing
- `GET /api/marketplace/my-products` - Seller's products

#### Educational Content
- `POST /api/education/content/{id}/like` - Like content
- `POST /api/education/content/{id}/unlike` - Unlike content
- `POST /api/education/content` - Create content (Admin only)

#### Notifications
- `GET /api/notifications` - Get all notifications
- `GET /api/notifications/unread` - Get unread notifications
- `GET /api/notifications/urgent` - Get urgent notifications
- `POST /api/notifications/{id}/read` - Mark as read
- `POST /api/notifications/read-all` - Mark all as read

---

## 🐛 Troubleshooting

### Issue: Database Connection Failed

**Solution:**
```bash
# Check if PostgreSQL is running
pg_isready -h localhost -p 5432

# Start PostgreSQL
# Windows:
net start postgresql-x64-14
# Linux/Mac:
sudo systemctl start postgresql

# Verify connection
psql -U postgres -d kheti_sahayak -c "SELECT 1;"
```

### Issue: Redis Connection Failed

**Solution:**
```bash
# Check if Redis is running
redis-cli ping

# Start Redis
# Windows:
redis-server
# Linux/Mac:
sudo systemctl start redis

# Test connection
redis-cli
> ping
> exit
```

### Issue: Port 8080 Already in Use

**Solution:**
```bash
# Find process using port 8080
# Windows:
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Linux/Mac:
lsof -ti:8080 | xargs kill -9

# Or change port in application.yml:
# server.port: 8081
```

### Issue: Maven Build Fails

**Solution:**
```bash
# Clean Maven cache
./mvnw clean

# Rebuild with dependencies
./mvnw clean install -U

# Skip tests if needed
./mvnw clean install -DskipTests
```

### Issue: Database Migration Fails

**Solution:**
```bash
# Drop and recreate database
dropdb kheti_sahayak
createdb kheti_sahayak

# Run application again - Flyway will migrate automatically
./mvnw spring-boot:run
```

---

## 📊 Development Tools

### Access Swagger UI
**URL:** http://localhost:8080/api-docs

Features:
- Interactive API testing
- Request/response examples
- Authentication testing
- Schema documentation

### Access Database Admin (Optional)

If running with Docker Compose:
```bash
docker-compose up -d

# Access Adminer at http://localhost:8081
# Server: postgres
# Username: postgres
# Password: postgres
# Database: kheti_sahayak
```

### Monitor Application Logs

```bash
# View application logs
tail -f logs/spring-boot-application.log

# Or in console:
./mvnw spring-boot:run
```

### Redis Monitoring

```bash
# Connect to Redis CLI
redis-cli

# Monitor commands
> MONITOR

# Check keys
> KEYS *

# Get OTP for a user (if stored)
> GET otp:9876543210
```

---

## 🔑 Authentication Flow

### 1. Register New User

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "9876543210",
    "fullName": "Ramesh Kumar",
    "primaryCrop": "Rice",
    "state": "Maharashtra",
    "district": "Nashik",
    "farmSize": 2.5,
    "userType": "FARMER"
  }'
```

### 2. Verify OTP

```bash
# Check application logs or Redis for OTP
# In production, OTP would be sent via SMS

curl -X POST http://localhost:8080/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "9876543210",
    "otp": "123456"
  }'

# Response includes JWT token:
# {
#   "success": true,
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "user": {...}
# }
```

### 3. Use JWT Token

```bash
# Store the token
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Make authenticated requests
curl http://localhost:8080/api/notifications \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🧪 Sample Data

The application comes with sample data for testing:

### Educational Content (5 articles)
- Rice cultivation in Kharif season
- Organic pest control for vegetables
- Drip irrigation techniques
- Soil health management
- PM-KISAN scheme application guide

### Notifications (5 sample notifications)
- Heavy rainfall alert
- Government scheme announcement
- Rice price update
- Irrigation reminder
- Pest alert

### Access Sample Data

```bash
# Educational content
curl http://localhost:8080/api/education/content

# After authentication, notifications
curl http://localhost:8080/api/notifications \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🚀 Next Steps

### For Developers:
1. ✅ Explore API documentation at `/api-docs`
2. ✅ Read `IMPLEMENTATION_SUMMARY.md` for architecture details
3. ✅ Check `README.md` for comprehensive documentation
4. ✅ Review code in `kheti_sahayak_spring_boot/src/main/java`
5. ✅ Run tests: `./mvnw test`

### For Testing:
1. ✅ Test all public endpoints
2. ✅ Test authentication flow
3. ✅ Test educational content CRUD
4. ✅ Test notification system
5. ✅ Test weather integration
6. ✅ Test marketplace features

### For Deployment:
1. ✅ Review `DEPLOYMENT_GUIDE.md`
2. ✅ Set up production database
3. ✅ Configure environment variables
4. ✅ Set up SSL certificates
5. ✅ Configure monitoring

---

## 📞 Getting Help

- 📖 **Documentation:** [GitHub Wiki](https://github.com/automotiv/khetisahayak/wiki)
- 🐛 **Issues:** [GitHub Issues](https://github.com/automotiv/khetisahayak/issues)
- 💬 **Community:** [Discussions](https://github.com/automotiv/khetisahayak/discussions)
- 📧 **Email:** support@khetisahayak.com

---

## ✅ Success Checklist

- [ ] PostgreSQL database running
- [ ] Redis server running
- [ ] Spring Boot application started
- [ ] Health check returns OK
- [ ] Swagger UI accessible
- [ ] Educational content endpoints working
- [ ] Notification endpoints working
- [ ] Weather service returning data
- [ ] User registration successful
- [ ] JWT authentication working

---

**🌾 You're all set! Start building amazing agricultural features!**

*Built with ❤️ for Indian farmers*

---

**Last Updated:** October 1, 2025  
**Version:** 1.5.0

