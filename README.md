# Kheti Sahayak - Agricultural Assistance Platform

A comprehensive agricultural assistance platform designed to help farmers with crop diagnostics, educational content, marketplace access, and agricultural guidance. The platform consists of a Node.js backend API and a Flutter mobile application.

## 🌾 Project Overview

Kheti Sahayak (meaning "Agricultural Helper" in Hindi) is a digital platform that empowers farmers with:

- **AI-Powered Crop Diagnostics**: Upload plant images for disease detection
- **Educational Content**: Access to agricultural articles, videos, and guides
- **Expert Consultation**: Connect with agricultural experts for personalized advice
- **Marketplace**: Buy and sell agricultural products
- **Weather Information**: Real-time weather data and forecasts
- **Crop Recommendations**: Season-based crop suggestions

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Node.js API    │    │   PostgreSQL    │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │     Redis       │
                       │   (Cache)       │
                       └─────────────────┘
```

## 📁 Project Structure

```
khetisahayak/
├── kheti_sahayak_backend/     # Node.js Backend API
│   ├── controllers/           # API Controllers
│   ├── routes/               # API Routes
│   ├── models/               # Database Models
│   ├── middleware/           # Custom Middleware
│   ├── services/             # Business Logic
│   ├── migrations/           # Database Migrations
│   ├── tests/                # Test Files
│   ├── server.js             # Main Server File
│   ├── package.json          # Backend Dependencies
│   └── README.md             # Backend Documentation
├── kheti_sahayak_app/        # Flutter Mobile App
│   ├── lib/                  # Dart Source Code
│   │   ├── models/           # Data Models
│   │   ├── services/         # API Services
│   │   ├── screens/          # UI Screens
│   │   ├── providers/        # State Management
│   │   ├── widgets/          # Reusable Widgets
│   │   └── main.dart         # App Entry Point
│   ├── android/              # Android Configuration
│   ├── ios/                  # iOS Configuration
│   ├── pubspec.yaml          # Flutter Dependencies
│   └── README.md             # Frontend Documentation
├── prd/                      # Product Requirements
├── docs/                     # Project Documentation
└── README.md                 # This File
```

## 🚀 Quick Start

### Prerequisites

Before setting up the project, ensure you have the following installed:

- **Node.js** (v16 or higher)
- **Flutter SDK** (v3.10 or higher)
- **PostgreSQL** (v12 or higher)
- **Redis** (v6 or higher)
- **Docker** (optional, for containerized setup)
- **Git**

### 1. Clone the Repository

```bash
git clone <repository-url>
cd khetisahayak
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd kheti_sahayak_backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Configure environment variables (see Backend README for details)
# Edit .env file with your database and API credentials

# Start PostgreSQL and Redis (using Docker)
docker-compose up -d

# Run database migrations
npm run migrate

# Seed the database
npm run seed

# Start the development server
npm run dev
```

The backend will be available at: http://localhost:3000
API Documentation: http://localhost:3000/api-docs/

### 3. Frontend Setup

```bash
# Navigate to frontend directory
cd kheti_sahayak_app

# Install Flutter dependencies
flutter pub get

# Create environment file
cp lib/.env.example lib/.env

# Configure API URL in lib/.env
# API_BASE_URL=http://localhost:3000/api

# Run the app
flutter run
```

## 🔧 Development Setup

### Backend Development

```bash
cd kheti_sahayak_backend

# Install dependencies
npm install

# Run in development mode with auto-reload
npm run dev

# Run tests
npm test

# Run tests with coverage
npm run test:coverage
```

### Frontend Development

```bash
cd kheti_sahayak_app

# Install dependencies
flutter pub get

# Run in development mode
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

## 🐳 Docker Setup

### Complete Stack with Docker Compose

```bash
# Start all services (Backend, Database, Cache)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Individual Services

```bash
# Backend only
docker build -t kheti-sahayak-backend ./kheti_sahayak_backend
docker run -p 3000:3000 kheti-sahayak-backend

# Database only
docker run -d --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:14

# Redis only
docker run -d --name redis -p 6379:6379 redis:6-alpine
```

## 📚 API Documentation

Once the backend is running, access the interactive API documentation:

**Swagger UI**: http://localhost:3000/api-docs/

The documentation includes:
- All available endpoints
- Request/response schemas
- Authentication requirements
- Example requests and responses
- Interactive testing interface

## 🔌 Key API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout

### Diagnostics
- `POST /api/diagnostics/upload` - Upload image for diagnosis
- `GET /api/diagnostics` - Get diagnostic history
- `GET /api/diagnostics/recommendations` - Get crop recommendations

### Educational Content
- `GET /api/educational-content` - Get educational content
- `GET /api/educational-content/:id` - Get specific content
- `GET /api/educational-content/categories` - Get content categories

### Marketplace
- `GET /api/products` - Get products
- `POST /api/orders` - Create order
- `GET /api/orders` - Get user orders

## 🧪 Testing

### Backend Testing

```bash
cd kheti_sahayak_backend

# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

### Frontend Testing

```bash
cd kheti_sahayak_app

# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run tests with coverage
flutter test --coverage
```

## 📊 Database Schema

The application uses PostgreSQL with the following main tables:

- `users` - User accounts and profiles
- `diagnostics` - Plant disease diagnostics
- `educational_content` - Articles, videos, and guides
- `products` - Marketplace products
- `orders` - User orders
- `notifications` - User notifications
- `expert_reviews` - Expert review data
- `crop_recommendations` - Crop recommendation data

## 🔒 Security Features

- JWT-based authentication
- Password hashing with bcrypt
- Input validation and sanitization
- CORS configuration
- Rate limiting
- Secure file uploads
- Environment variable protection

## 🚀 Deployment

### Backend Deployment

```bash
cd kheti_sahayak_backend

# Build for production
npm run build

# Start production server
npm start

# Using PM2
pm2 start server.js --name kheti-sahayak-backend
```

### Frontend Deployment

```bash
cd kheti_sahayak_app

# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Build for web
flutter build web --release
```

## 📱 Platform Support

### Backend
- Node.js runtime
- PostgreSQL database
- Redis cache
- Docker containerization

### Frontend
- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **Web**: Modern browsers
- **Desktop**: Windows, macOS, Linux (experimental)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow coding standards for each technology
- Write tests for new features
- Update documentation
- Test on multiple platforms
- Ensure security best practices

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- Create an issue in the repository
- Contact the development team
- Check the individual README files:
  - [Backend README](kheti_sahayak_backend/README.md)
  - [Frontend README](kheti_sahayak_app/README.md)
- Access API documentation at http://localhost:3000/api-docs/

## 🔄 Version History

- **v1.0.0** - Initial release with core features
- **v1.1.0** - Added crop diagnostics and expert review system
- **v1.2.0** - Enhanced educational content management
- **v1.3.0** - Added marketplace functionality
- **v1.4.0** - Improved API documentation and testing

## 📊 Project Status

- ✅ Backend API (Complete)
- ✅ Database Schema (Complete)
- ✅ Authentication System (Complete)
- ✅ Crop Diagnostics (Complete)
- ✅ Educational Content (Complete)
- ✅ Marketplace (Complete)
- ✅ Frontend App (In Progress)
- 🔄 UI/UX Enhancement (In Progress)
- 🔄 Testing (In Progress)
- 🔄 Deployment (Pending)

## 🌟 Features Roadmap

### Completed Features
- User authentication and authorization
- Crop diagnostics with AI simulation
- Educational content management
- Marketplace functionality
- Expert review system
- Weather integration
- Notification system

### Upcoming Features
- Real-time chat with experts
- Advanced analytics dashboard
- Multi-language support
- Offline mode enhancement
- Push notifications
- Payment gateway integration
- Social features

---

**Note**: Make sure to configure all environment variables and database credentials according to your setup before running the application. Refer to the individual README files for detailed setup instructions. 