# 🚀 Quick Start Guide

Get Kheti Sahayak up and running in minutes!

## Prerequisites

- Node.js (v16+)
- Flutter SDK (v3.10+)
- Docker (optional, for database)
- Git

## Option 1: Automated Setup (Recommended)

Run the setup script to automatically configure everything:

```bash
# Clone the repository
git clone <repository-url>
cd khetisahayak

# Run the setup script
./setup.sh
```

The script will:
- ✅ Check prerequisites
- ✅ Install dependencies
- ✅ Create environment files
- ✅ Set up database (if Docker is available)
- ✅ Run migrations and seed data

## Option 2: Manual Setup

### 1. Backend Setup

```bash
cd kheti_sahayak_backend

# Install dependencies
npm install

# Copy environment file
cp env.example .env

# Edit .env with your configuration
# (Database credentials, API keys, etc.)

# Start database (using Docker)
docker-compose up -d postgres redis

# Run migrations and seed
npm run migrate
npm run seed

# Start development server
npm run dev
```

Backend will be available at: http://localhost:3000
API Documentation: http://localhost:3000/api-docs/

### 2. Frontend Setup

```bash
cd kheti_sahayak_app

# Install dependencies
flutter pub get

# Copy environment file
cp lib/env.example lib/.env

# Edit lib/.env with your API URL
# API_BASE_URL=http://localhost:3000/api

# Run the app
flutter run
```

## 🧪 Test the Setup

### Backend API Test

```bash
# Test health endpoint
curl http://localhost:3000/api/health

# Test educational content
curl http://localhost:3000/api/educational-content?limit=3

# Test crop recommendations
curl http://localhost:3000/api/diagnostics/recommendations
```

### Frontend Test

1. Open the app on your device/emulator
2. Navigate to different screens
3. Test the diagnostic upload feature
4. Browse educational content
5. Check marketplace functionality

## 🔧 Common Issues & Solutions

### Database Connection Issues

```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Restart database
docker-compose restart postgres

# Check database connection
cd kheti_sahayak_backend
npm run db:check
```

### Flutter Dependencies Issues

```bash
cd kheti_sahayak_app

# Clean and get dependencies
flutter clean
flutter pub get

# Check for issues
flutter doctor
flutter analyze
```

### API Connection Issues

1. Ensure backend is running on port 3000
2. Check API_BASE_URL in frontend .env file
3. Verify CORS settings in backend
4. Check network connectivity

## 📚 Next Steps

1. **Explore the API**: Visit http://localhost:3000/api-docs/
2. **Read Documentation**: 
   - [Main README](README.md)
   - [Backend README](kheti_sahayak_backend/README.md)
   - [Frontend README](kheti_sahayak_app/README.md)
3. **Run Tests**: 
   - Backend: `cd kheti_sahayak_backend && npm test`
   - Frontend: `cd kheti_sahayak_app && flutter test`
4. **Start Developing**: Pick a feature and start coding!

## 🆘 Need Help?

- Check the [Main README](README.md) for detailed documentation
- Create an issue in the repository
- Contact the development team

---

**Happy coding! 🌾** 