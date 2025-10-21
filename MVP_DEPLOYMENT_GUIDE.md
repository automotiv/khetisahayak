# 🚀 MVP Deployment Guide - Kheti Sahayak

**Last Updated:** October 21, 2025

This guide will help you deploy and test the MVP features for Kheti Sahayak.

---

## 📋 What's Included in MVP

✅ **Core Features Implemented:**
1. ML Inference Service (FastAPI)
2. Treatment Recommendations Database
3. Backend API with ML Integration
4. Treatments API Endpoint
5. 16+ Crop Diseases with Detailed Treatments

---

## 🏗️ System Architecture (MVP)

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  Flutter    │────▶ │   Backend    │────▶ │  PostgreSQL │
│  Mobile App │      │  (Node.js)   │      │  Database   │
└─────────────┘      └──────┬───────┘      └─────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  ML Service  │
                     │  (FastAPI)   │
                     └──────────────┘
```

---

## 🛠️ Prerequisites

### Required
- **Node.js:** v18+ (`node --version`)
- **PostgreSQL:** v12+ (`psql --version`)
- **Python:** 3.8+ (`python --version`)
- **Flutter:** 3.10+ (`flutter --version`)
- **Git:** Latest version

### Optional
- **Docker:** For containerized deployment
- **Redis:** For caching (can skip for MVP)
- **AWS S3:** For image storage (or use local storage)

---

## 📦 Step 1: Database Setup

### 1.1 Create Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE kheti_sahayak;

# Create user (if needed)
CREATE USER kheti_user WITH PASSWORD 'your_secure_password';

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE kheti_sahayak TO kheti_user;

# Exit
\q
```

### 1.2 Run Migrations

```bash
cd kheti_sahayak_backend

# Install dependencies
npm install

# Run initial schema migration
npm run migrate:up

# Run treatments migration
npm run migrate:up
```

### 1.3 Seed Treatment Data

```bash
# Seed the database with crop diseases and treatments
node seedTreatmentData.js
```

**Expected Output:**
```
✓ Inserted disease: Rice Blast (ID: 1)
✓ Inserted disease: Bacterial Leaf Blight (ID: 2)
...
✓ Inserted 16 treatments for Rice Blast
===Seeding Complete ===
Total diseases inserted: 16
Total treatments inserted: 45+
```

---

## 🤖 Step 2: ML Inference Service Setup

### 2.1 Install Python Dependencies

```bash
cd ml

# Create virtual environment
python -m venv venv

# Activate (Mac/Linux)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2.2 Download/Prepare Model (Optional for MVP)

For MVP testing, the service runs in **mock mode** (provides simulated predictions).

For production:
```bash
# Place your trained model in ml/artifacts/exported/
mkdir -p artifacts/exported

# Required files:
# - model.onnx (ONNX model file)
# - model_metadata.json
# - class_mapping.json
```

### 2.3 Start ML Service

```bash
# Development mode (with hot reload)
python inference_service.py

# Or using uvicorn directly
uvicorn inference_service:app --host 0.0.0.0 --port 8000 --reload
```

**Test ML Service:**
```bash
# Health check
curl http://localhost:8000/health

# Model info
curl http://localhost:8000/model-info
```

**Expected Response:**
```json
{
  "status": "healthy",
  "model_loaded": false,
  "mock_mode": true
}
```

---

## ⚙️ Step 3: Backend API Setup

### 3.1 Configure Environment

```bash
cd kheti_sahayak_backend

# Copy .env file (already configured)
# Update if needed:
nano .env
```

**Key Configuration:**
```env
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_NAME=kheti_sahayak
DB_USER=postgres
DB_PASSWORD=postgres
DB_PORT=5432

# JWT
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRE=24h

# ML Service
ML_API_URL=http://localhost:8000
```

### 3.2 Install Dependencies & Start

```bash
# Install packages
npm install

# Start development server
npm run dev
```

**Test Backend API:**
```bash
# Health check
curl http://localhost:3000/api/health

# API documentation
open http://localhost:3000/api-docs
```

---

## 📱 Step 4: Flutter App Setup

### 4.1 Update API Endpoint

```bash
cd kheti_sahayak_app

# Edit API configuration
nano lib/utils/constants.dart
```

Update the API URL:
```dart
class Constants {
  // Change to your local IP for physical device testing
  static const String apiBaseUrl = 'http://localhost:3000/api';

  // For Android Emulator:
  // static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

  // For iOS Simulator:
  // static const String apiBaseUrl = 'http://localhost:3000/api';

  // For Physical Device (find your local IP):
  // static const String apiBaseUrl = 'http://192.168.1.XXX:3000/api';
}
```

### 4.2 Install Dependencies

```bash
# Get Flutter packages
flutter pub get

# For iOS (Mac only)
cd ios && pod install && cd ..
```

### 4.3 Run App

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or just run (will prompt for device selection)
flutter run
```

---

## 🧪 Step 5: Testing the MVP

### 5.1 Test ML Service (Standalone)

```bash
# Test image prediction
curl -X POST http://localhost:8000/predict \
  -F "file=@test-images/rice_blast.jpg"
```

**Expected Response:**
```json
{
  "class_id": 0,
  "class_name": "rice_blast",
  "confidence": 0.85,
  "predictions": {
    "rice_blast": 0.85,
    "healthy": 0.15
  },
  "mock_prediction": true
}
```

### 5.2 Test Backend API

#### Register User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "farmer1",
    "email": "farmer1@example.com",
    "password": "Test123!",
    "first_name": "Test",
    "last_name": "Farmer",
    "phone": "+911234567890",
    "role": "farmer"
  }'
```

#### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "farmer1@example.com",
    "password": "Test123!"
  }'
```

Save the `token` from response.

#### Upload Image for Diagnosis
```bash
TOKEN="your_token_here"

curl -X POST http://localhost:3000/api/diagnostics/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@test-images/rice_blast.jpg" \
  -F "crop_type=Rice" \
  -F "issue_description=Yellow spots on leaves"
```

#### Get Treatments
```bash
DIAGNOSTIC_ID=1

curl -X GET http://localhost:3000/api/diagnostics/$DIAGNOSTIC_ID/treatments \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
{
  "success": true,
  "diagnostic_id": 1,
  "disease": {
    "id": 1,
    "name": "Rice Blast",
    "symptoms": "Diamond-shaped lesions...",
    "prevention": "Use resistant varieties..."
  },
  "treatments": [
    {
      "treatment_type": "chemical",
      "treatment_name": "Tricyclazole",
      "dosage": "0.6g per liter",
      "effectiveness_rating": 5,
      "cost_estimate": "₹300-400 per acre"
    }
  ]
}
```

### 5.3 Test Flutter App

1. **Launch App**
   - App should show splash screen → Login screen

2. **Register/Login**
   - Create account or login with test credentials

3. **Test Diagnostics Flow**
   - Go to Diagnostics screen
   - Tap "Upload Image" or "Take Photo"
   - Select crop type: Rice
   - Add description: "Yellow spots on leaves"
   - Upload image
   - Wait for AI analysis (should show loading)
   - View results: Disease name, confidence, severity
   - Tap "View Treatments"
   - See treatment recommendations

4. **Test History**
   - Go to History tab
   - See list of past diagnostics
   - Filter by crop type or status
   - Tap on diagnostic to view details

---

## 🐛 Troubleshooting

### ML Service Issues

**Problem:** `ModuleNotFoundError: No module named 'onnxruntime'`
```bash
pip install onnxruntime
```

**Problem:** Port 8000 already in use
```bash
# Find and kill process
lsof -ti:8000 | xargs kill -9

# Or use different port
uvicorn inference_service:app --port 8001
```

### Database Issues

**Problem:** `relation "diagnostics" does not exist`
```bash
# Run migrations
cd kheti_sahayak_backend
npm run migrate:up
```

**Problem:** `relation "crop_diseases" does not exist`
```bash
# Run the treatments migration
npm run migrate:up

# Then seed data
node seedTreatmentData.js
```

### Backend Issues

**Problem:** `ECONNREFUSED` when calling ML service
- Ensure ML service is running on port 8000
- Check ML_API_URL in .env file
- Test ML service directly: `curl http://localhost:8000/health`

**Problem:** Database connection failed
- Verify PostgreSQL is running: `pg_isready`
- Check credentials in .env
- Ensure database exists: `psql -l | grep kheti_sahayak`

### Flutter Issues

**Problem:** API calls failing
- Check API_BASE_URL in constants.dart
- For physical device: Use your local IP address
- For emulator: Use appropriate localhost mapping

**Problem:** Image picker not working
- iOS: Add camera/photo permissions to Info.plist
- Android: Add permissions to AndroidManifest.xml

---

## 📊 Database Schema Reference

### crop_diseases Table
```sql
- id (PK)
- disease_name
- scientific_name
- crop_type (Rice, Wheat, Cotton, Tomato, etc.)
- description
- symptoms
- causes
- prevention
- severity (low, moderate, high, severe)
- ai_model_class (maps to ML model output)
- created_at, updated_at
```

### treatment_recommendations Table
```sql
- id (PK)
- disease_id (FK → crop_diseases)
- treatment_type (organic, chemical, cultural, biological)
- treatment_name
- active_ingredient
- dosage
- application_method
- timing
- frequency
- precautions
- effectiveness_rating (1-5)
- cost_estimate
- availability
- notes
- created_at, updated_at
```

### diagnostics Table (Updated)
```sql
- id (PK)
- user_id (FK → users)
- crop_type
- issue_description
- image_urls
- diagnosis_result
- recommendations
- confidence_score
- status
- disease_detected (NEW)
- ai_confidence (NEW)
- severity (NEW)
- ai_model_version (NEW)
- disease_id (FK → crop_diseases) (NEW)
- created_at, updated_at
```

---

## 🚀 Deployment to Production

### Option 1: Railway.app (Free Tier)

#### ML Service
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Create project
railway init

# Deploy ML service
cd ml
railway up
```

#### Backend API
```bash
cd kheti_sahayak_backend
railway init
railway up

# Add environment variables via Railway dashboard
```

### Option 2: Render.com (Free Tier)

1. Create account at render.com
2. New → Web Service
3. Connect GitHub repository
4. Configure:
   - **ML Service:**
     - Build Command: `pip install -r requirements.txt`
     - Start Command: `uvicorn inference_service:app --host 0.0.0.0 --port $PORT`
   - **Backend:**
     - Build Command: `npm install`
     - Start Command: `npm start`

### Option 3: Docker (Local/VPS)

```bash
# Build ML service
cd ml
docker build -f Dockerfile.inference -t khetisahayak-ml .
docker run -p 8000:8000 khetisahayak-ml

# Build backend
cd kheti_sahayak_backend
docker build -t khetisahayak-backend .
docker run -p 3000:3000 khetisahayak-backend
```

---

## 📈 Next Steps After MVP

1. **Offline Functionality** (Issue #298)
   - Add SQLite local storage
   - Implement background sync
   - Handle offline image queue

2. **Production ML Model**
   - Train model on real dataset
   - Achieve 85%+ accuracy
   - Deploy ONNX model

3. **Beta Testing**
   - Deploy to Play Store (internal track)
   - Invite 10-20 farmers
   - Collect feedback
   - Iterate

4. **Additional Features**
   - Weather forecast
   - Marketplace
   - Community forum
   - Expert connect

---

## 📞 Support

- **GitHub Issues:** https://github.com/automotiv/khetisahayak/issues/297
- **Documentation:** Check wiki for detailed guides
- **Community:** GitHub Discussions

---

## ✅ MVP Checklist

### Backend
- [x] Database migration for treatments
- [x] Seed data for 16+ diseases
- [x] ML service integration
- [x] Treatments API endpoint
- [x] Updated diagnostics controller
- [ ] Run migrations
- [ ] Seed database
- [ ] Start services

### ML Service
- [x] FastAPI inference service
- [x] Mock mode for testing
- [x] Health checks
- [ ] Deploy service
- [ ] Test endpoints

### Frontend
- [ ] Update API constants
- [ ] Test diagnostics flow
- [ ] Test treatments display
- [ ] Test on physical device

### Testing
- [ ] Register test user
- [ ] Upload test image
- [ ] Verify AI analysis
- [ ] Check treatment recommendations
- [ ] Test history/filtering

---

**MVP Status:** Ready for Local Testing 🎉

**Next:** Run migrations, seed database, and test end-to-end!
