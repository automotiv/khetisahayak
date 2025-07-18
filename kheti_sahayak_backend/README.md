# Kheti Sahayak Backend

A comprehensive Node.js backend API for the Kheti Sahayak agricultural assistance platform. This backend provides robust APIs for user management, crop diagnostics, educational content, marketplace, and more.

## 🚀 Features

- **User Authentication & Authorization**: JWT-based authentication with role-based access control
- **Crop Diagnostics**: AI-powered plant disease detection with expert review system
- **Educational Content Management**: Articles, videos, and guides with categorization
- **Marketplace**: Product management and order processing
- **Weather Integration**: Real-time weather data for farmers
- **Notifications**: Push notifications and email alerts
- **File Upload**: AWS S3 integration for image and file storage
- **Caching**: Redis-based caching for improved performance
- **API Documentation**: Swagger UI for comprehensive API documentation

## 🛠️ Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Cache**: Redis
- **Authentication**: JWT
- **File Storage**: AWS S3
- **Documentation**: Swagger UI
- **Validation**: Joi
- **Testing**: Jest
- **Containerization**: Docker

## 📋 Prerequisites

Before running this application, make sure you have the following installed:

- Node.js (v16 or higher)
- PostgreSQL (v12 or higher)
- Redis (v6 or higher)
- Docker (optional, for containerized setup)

## 🔧 Installation & Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd kheti_sahayak_backend
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Configuration

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Configure the following environment variables:

```env
# Server Configuration
NODE_ENV=development
PORT=3000

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=kheti_sahayak
DB_USER=postgres
DB_PASSWORD=your_password

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT Configuration
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=7d

# AWS S3 Configuration
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=your_s3_bucket_name

# Email Configuration (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_email_password

# Weather API (Optional)
WEATHER_API_KEY=your_weather_api_key
```

### 4. Database Setup

#### Option A: Using Docker (Recommended)

```bash
# Start PostgreSQL and Redis using Docker Compose
docker-compose up -d

# Run database migrations
npm run migrate

# Seed the database with initial data
npm run seed
```

#### Option B: Manual Setup

1. Create a PostgreSQL database named `kheti_sahayak`
2. Update the database credentials in your `.env` file
3. Run migrations and seeds:

```bash
npm run migrate
npm run seed
```

### 5. Start the Application

#### Development Mode

```bash
npm run dev
```

#### Production Mode

```bash
npm start
```

The server will start on `http://localhost:3000`

## 📚 API Documentation

Once the server is running, you can access the interactive API documentation at:

**Swagger UI**: http://localhost:3000/api-docs/

The documentation includes:
- All available endpoints
- Request/response schemas
- Authentication requirements
- Example requests and responses
- Interactive testing interface

## 🗂️ Project Structure

```
kheti_sahayak_backend/
├── controllers/          # Route controllers
│   ├── authController.js
│   ├── diagnosticController.js
│   ├── educationalContentController.js
│   ├── marketplaceController.js
│   ├── notificationController.js
│   └── userController.js
├── middleware/           # Custom middleware
│   ├── auth.js
│   └── validation.js
├── migrations/           # Database migrations
├── models/              # Database models
├── routes/              # API routes
│   ├── auth.js
│   ├── diagnostics.js
│   ├── educationalContent.js
│   ├── marketplace.js
│   ├── notifications.js
│   └── users.js
├── services/            # Business logic
├── utils/               # Utility functions
├── tests/               # Test files
├── .env                 # Environment variables
├── server.js            # Main application file
└── package.json
```

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/auth/forgot-password` - Password reset request
- `POST /api/auth/change-password` - Change password

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `GET /api/users` - Get all users (Admin)

### Diagnostics
- `POST /api/diagnostics/upload` - Upload image for diagnosis
- `GET /api/diagnostics` - Get user's diagnostic history
- `GET /api/diagnostics/:id` - Get specific diagnostic
- `POST /api/diagnostics/:id/expert-review` - Request expert review
- `PUT /api/diagnostics/:id/expert-review` - Submit expert review
- `GET /api/diagnostics/recommendations` - Get crop recommendations
- `GET /api/diagnostics/stats` - Get diagnostic statistics

### Educational Content
- `GET /api/educational-content` - Get educational content
- `POST /api/educational-content` - Create new content (Admin)
- `GET /api/educational-content/:id` - Get specific content
- `PUT /api/educational-content/:id` - Update content (Admin)
- `DELETE /api/educational-content/:id` - Delete content (Admin)
- `GET /api/educational-content/categories` - Get content categories
- `GET /api/educational-content/popular` - Get popular content

### Marketplace
- `GET /api/products` - Get products
- `POST /api/products` - Create product (Admin)
- `GET /api/products/:id` - Get specific product
- `PUT /api/products/:id` - Update product (Admin)
- `DELETE /api/products/:id` - Delete product (Admin)
- `POST /api/orders` - Create order
- `GET /api/orders` - Get user orders
- `GET /api/orders/:id` - Get specific order

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

## 🐳 Docker Deployment

### Build and Run with Docker

```bash
# Build the Docker image
docker build -t kheti-sahayak-backend .

# Run the container
docker run -p 3000:3000 --env-file .env kheti-sahayak-backend
```

### Using Docker Compose

```bash
# Start all services (PostgreSQL, Redis, Backend)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## 🔒 Security Features

- JWT-based authentication
- Password hashing with bcrypt
- Input validation and sanitization
- CORS configuration
- Rate limiting
- Helmet.js for security headers
- Environment variable protection

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

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- Create an issue in the repository
- Contact the development team
- Check the API documentation at http://localhost:3000/api-docs/

## 🔄 Version History

- **v1.0.0** - Initial release with core features
- **v1.1.0** - Added expert review system
- **v1.2.0** - Enhanced educational content management
- **v1.3.0** - Added marketplace functionality
- **v1.4.0** - Improved API documentation and testing

---

**Note**: Make sure to update the environment variables and database credentials according to your setup before running the application. 