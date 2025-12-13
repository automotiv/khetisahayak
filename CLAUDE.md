# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kheti Sahayak ("Farm Helper") is a comprehensive agricultural assistance platform with multiple components:

- **Flutter Mobile App** (`kheti_sahayak_app/`) - Cross-platform mobile application for farmers
- **Node.js Backend** (`kheti_sahayak_backend/`) - REST API with PostgreSQL database
- **React Web Frontend** (`frontend/`) - Web dashboard built with React/MUI
- **ML Service** (`ml/`) - FastAPI service for crop disease detection
- **Spring Boot Backend** (`kheti_sahayak_spring_boot/`) - Alternative Java backend (archived)

## Quick Start

### Using Docker (Recommended)

```bash
# Start all services
docker-compose up -d

# Services will be available at:
# - Backend API: http://localhost:5001
# - ML Service: http://localhost:8000
# - Frontend: http://localhost:3000
# - PostgreSQL: localhost:5432
```

### Manual Setup

```bash
# 1. Start PostgreSQL database
# 2. Start backend
cd kheti_sahayak_backend && npm install && npm run dev

# 3. Start ML service (optional)
cd ml && pip install -r requirements.txt && python inference_service.py

# 4. Start React frontend (optional)
cd frontend && npm install && npm run dev

# 5. Run Flutter app
cd kheti_sahayak_app && flutter pub get && flutter run
```

---

## Flutter Mobile App (`kheti_sahayak_app/`)

### Development Commands

```bash
cd kheti_sahayak_app

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run with specific device
flutter run -d <device_id>

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Architecture

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
├── providers/             # State management (Provider)
├── screens/               # UI screens
├── services/              # API and local services
├── routes/                # Navigation routes
├── theme/                 # App theming
├── utils/                 # Utility functions
└── widgets/               # Reusable widgets
```

### Key Dependencies

- **State Management**: Provider
- **HTTP**: Dio, http
- **Local Storage**: SQLite, SharedPreferences, FlutterSecureStorage
- **UI**: Material Design, Google Fonts, FL Chart
- **Image**: ImagePicker, CachedNetworkImage
- **Location**: Geolocator

### Environment Configuration

Create `lib/.env` from `lib/.env.example`:
```
API_BASE_URL=http://localhost:3000/api
```

---

## Node.js Backend (`kheti_sahayak_backend/`)

See `kheti_sahayak_backend/CLAUDE.md` for detailed backend documentation.

### Quick Reference

```bash
cd kheti_sahayak_backend

# Development
npm run dev              # Start with hot reload

# Database
npm run db:init          # Initialize database
npm run migrate:up       # Run migrations
npm run db:seed          # Seed test data

# Testing
npm test                 # Run all tests
```

### API Documentation

Swagger UI available at `http://localhost:3000/api-docs`

### Test Credentials

After seeding:
- Admin: `admin@khetisahayak.com` / `admin123`
- Expert: `expert@khetisahayak.com` / `expert123`
- Farmer: `farmer@khetisahayak.com` / `user123`

---

## React Web Frontend (`frontend/`)

### Development Commands

```bash
cd frontend

# Install dependencies
npm install

# Development server
npm run dev

# Production build
npm run build

# Preview production build
npm run preview
```

### Tech Stack

- **Framework**: React 18 with TypeScript
- **UI Library**: Material-UI (MUI) v6
- **State Management**: Redux Toolkit
- **Routing**: React Router v6
- **HTTP Client**: Axios
- **Build Tool**: Vite

### Project Structure

```
frontend/
├── src/
│   ├── components/     # Reusable components
│   ├── pages/          # Page components
│   ├── store/          # Redux store & slices
│   ├── services/       # API services
│   └── utils/          # Utilities
└── vite.config.ts      # Vite configuration
```

---

## ML Service (`ml/`)

### Development Commands

```bash
cd ml

# Install dependencies
pip install -r requirements.txt

# Run inference service
python inference_service.py

# Train model
python train.py

# Validate data
python data_validation.py
```

### API Endpoints

- `POST /predict` - Disease prediction from crop image
- `GET /health` - Health check

The service runs on `http://localhost:8000`.

---

## Common Development Patterns

### API Communication

All components communicate with the backend via REST APIs:
- Flutter app → Backend API (port 3000)
- React frontend → Backend API (port 3000)
- Backend → ML Service (port 8000)

### Authentication Flow

1. User registers/logs in via `/api/auth`
2. Backend returns JWT token
3. Client stores token and includes in `Authorization: Bearer <token>` header
4. Protected routes validate token via `protect` middleware

### Database

- **Type**: PostgreSQL 14
- **ORM**: Raw SQL with parameterized queries
- **Migrations**: node-pg-migrate
- **Primary Keys**: UUIDs

---

## Infrastructure

### Docker Services

| Service | Container | Port | Description |
|---------|-----------|------|-------------|
| postgres | kheti-postgres | 5432 | PostgreSQL database |
| backend | kheti-backend | 5001 | Node.js API |
| ml-inference | kheti-ml-inference | 8000 | ML prediction service |
| frontend | kheti-frontend | 3000 | Web frontend |

### Deployment

- **Render**: `render.yaml` for cloud deployment
- **Terraform**: `terraform/` for infrastructure as code
- **GitHub Actions**: `.github/` for CI/CD

---

## Testing

### Backend Tests
```bash
cd kheti_sahayak_backend
npm test                          # All tests
npm test -- tests/unit/auth.test.js  # Specific test
```

### Flutter Tests
```bash
cd kheti_sahayak_app
flutter test                      # Unit tests
flutter test integration_test/    # Integration tests
```

---

## Troubleshooting

1. **Database connection fails**: Ensure PostgreSQL is running on port 5432
2. **Flutter build fails**: Run `flutter clean && flutter pub get`
3. **Backend won't start**: Check `.env` configuration
4. **ML predictions fail**: ML service is optional; backend uses mock responses
5. **Redis errors**: Redis is optional; mock client activates automatically

---

## Project Links

- **Repository**: GitHub (automotiv/khetisahayak)
- **API Docs**: http://localhost:3000/api-docs (when running)
- **Wiki**: See `wiki/` and `wiki_repo/` directories
