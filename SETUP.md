# 🛠️ Developer Setup Guide

Welcome to the **Kheti Sahayak** project! This guide will help you set up your development environment quickly and easily.

## 📋 Prerequisites

Ensure you have the following installed:
-   **Node.js** (v18+)
-   **Flutter** (v3.x)
-   **Git**
-   **Docker** (Optional, for local DB/Redis)

## 🚀 Quick Start (Automated)

We have created automation scripts to make setup a breeze.

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/khetisahayak.git
cd khetisahayak
```

### 2. Run Setup Script
This script installs dependencies for Backend, Frontend, and Mobile projects.
```bash
chmod +x scripts/*.sh
./scripts/setup_dev.sh
```

### 3. Configure Environment Variables
You need to set up `.env` files for the backend and frontend.

**Backend (`kheti_sahayak_backend/.env`):**
```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://user:password@localhost:5432/kheti_sahayak
REDIS_URL=redis://localhost:6379
```

**Frontend (`frontend/.env`):**
```env
REACT_APP_API_URL=http://localhost:3000
```

**Mobile (`kheti_sahayak_app/lib/.env`):**
```env
API_BASE_URL=http://localhost:3000/api
```

## 🏃 Running the Project

### Backend
```bash
cd kheti_sahayak_backend
npm run dev
```

### Frontend (Web)
```bash
cd frontend
npm start
```

### Mobile (Flutter)
```bash
cd kheti_sahayak_app
flutter run
```

## 🧪 Running Tests

To run all tests across the entire project:
```bash
./scripts/run_all_tests.sh
```

## 🧹 Troubleshooting

If you encounter issues, try cleaning the project artifacts:
```bash
./scripts/clean_all.sh
```

## 🚢 Deployment

### Deploy Backend (Render)
```bash
node scripts/deploy_backend.js
```

### Deploy Frontend (Vercel)
```bash
./scripts/deploy_frontend.sh
```
