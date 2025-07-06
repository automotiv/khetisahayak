# Kheti Sahayak Backend

A comprehensive Node.js/Express backend for the Kheti Sahayak agricultural platform, providing APIs for user management, marketplace, crop diagnostics, weather data, and educational content.

## Features

- **User Authentication & Authorization**: JWT-based authentication with role-based access control
- **Marketplace**: Product management, ordering system, and seller functionality
- **Crop Diagnostics**: AI-powered crop disease detection with expert review system
- **Weather Integration**: Real-time weather data and forecasts
- **Educational Content**: Agricultural learning resources and tutorials
- **Order Management**: Complete order lifecycle management
- **Notifications**: Real-time notification system
- **File Upload**: AWS S3 integration for image storage
- **Database**: PostgreSQL with comprehensive schema
- **Caching**: Redis integration for performance optimization

## Tech Stack

- **Runtime**: Node.js (>=18.0.0)
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Cache**: Redis
- **Authentication**: JWT
- **File Storage**: AWS S3
- **Validation**: Express-validator
- **Logging**: Winston
- **Testing**: Jest
- **Containerization**: Docker

## Prerequisites

- Node.js >= 18.0.0
- PostgreSQL >= 14
- Redis (optional, for caching)
- AWS S3 account (for file uploads)

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd kheti_sahayak_backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   # or
   yarn install
   ```

3. **Environment Setup**
   ```bash
   cp env.example .env
   ```
   
   Update the `.env` file with your configuration:
   ```env
   # Database Configuration
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=kheti_sahayak
   DB_USER=postgres
   DB_PASSWORD=your_password_here

   # JWT Configuration
   JWT_SECRET=your_jwt_secret_key_here

   # Server Configuration
   PORT=3000
   NODE_ENV=development

   # AWS S3 Configuration
   AWS_ACCESS_KEY_ID=your_aws_access_key
   AWS_SECRET_ACCESS_KEY=your_aws_secret_key
   AWS_REGION=us-east-1
   S3_BUCKET_NAME=your_s3_bucket_name

   # Redis Configuration
   REDIS_URL=redis://localhost:6379

   # External API Keys
   WEATHER_API_KEY=your_weather_api_key
   OPENAI_API_KEY=your_openai_api_key

   # Logging
   LOG_LEVEL=info
   ```

4. **Database Setup**
   ```bash
   # Initialize database
   npm run db:init
   
   # Run migrations
   npm run migrate:up
   ```

5. **Start the server**
   ```bash
   # Development
   npm run dev
   
   # Production
   npm start
   ```

## Docker Setup

1. **Build and run with Docker Compose**
   ```bash
   docker-compose up --build
   ```

2. **Run in background**
   ```bash
   docker-compose up -d
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update user profile
- `POST /api/auth/profile-image` - Upload profile image
- `PUT /api/auth/change-password` - Change password
- `POST /api/auth/logout` - User logout

### Marketplace
- `GET /api/marketplace` - Get all products (with filtering)
- `GET /api/marketplace/categories` - Get product categories
- `GET /api/marketplace/:id` - Get product by ID
- `POST /api/marketplace` - Add new product
- `PUT /api/marketplace/:id` - Update product
- `DELETE /api/marketplace/:id` - Delete product
- `POST /api/marketplace/:id/images` - Upload product images
- `GET /api/marketplace/seller/products` - Get seller's products

### Orders
- `POST /api/orders` - Create new order
- `GET /api/orders` - Get user's orders
- `GET /api/orders/seller` - Get seller's orders
- `GET /api/orders/:id` - Get order by ID
- `PUT /api/orders/:id/status` - Update order status
- `PUT /api/orders/:id/cancel` - Cancel order

### Diagnostics
- `POST /api/diagnostics/upload` - Upload image for diagnosis
- `GET /api/diagnostics` - Get diagnostic history
- `GET /api/diagnostics/:id` - Get diagnostic by ID
- `POST /api/diagnostics/:id/expert-review` - Request expert review
- `PUT /api/diagnostics/:id/expert-review` - Submit expert review
- `GET /api/diagnostics/expert/assigned` - Get expert's assigned diagnostics
- `GET /api/diagnostics/recommendations` - Get crop recommendations

### Notifications
- `GET /api/notifications` - Get user's notifications
- `GET /api/notifications/stats` - Get notification statistics
- `PUT /api/notifications/:id/read` - Mark notification as read
- `PUT /api/notifications/read-all` - Mark all notifications as read
- `DELETE /api/notifications/:id` - Delete notification

### Weather
- `GET /api/weather/current` - Get current weather
- `GET /api/weather/forecast` - Get weather forecast

### Educational Content
- `GET /api/educational-content` - Get educational content
- `POST /api/educational-content` - Create educational content
- `PUT /api/educational-content/:id` - Update educational content
- `DELETE /api/educational-content/:id` - Delete educational content

### Health
- `GET /api/health` - Health check

## Database Schema

The application uses PostgreSQL with the following main tables:

- **users**: User accounts and profiles
- **products**: Marketplace products
- **orders**: Order management
- **order_items**: Order line items
- **diagnostics**: Crop diagnostic records
- **educational_content**: Learning resources
- **weather_data**: Weather information
- **crop_recommendations**: Crop suggestions
- **notifications**: User notifications
- **user_sessions**: Active user sessions

## Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

### User Roles

- **user**: Regular user with basic access
- **admin**: Administrator with full access
- **content-creator**: Can create educational content
- **expert**: Agricultural expert for diagnostics

## File Upload

The application supports file uploads for:
- Profile images
- Product images
- Diagnostic images

Files are stored in AWS S3 and the URLs are saved in the database.

## Error Handling

The API returns consistent error responses:

```json
{
  "error": "Error message",
  "status": 400
}
```

## Validation

All input data is validated using express-validator with custom validation rules for:
- Email format
- Password strength
- File types and sizes
- Required fields
- Data types

## Testing

Run tests:
```bash
npm test
```

Run tests with coverage:
```bash
npm run test:coverage
```

## Logging

The application uses Winston for logging with different levels:
- **error**: Application errors
- **warn**: Warning messages
- **info**: General information
- **http**: HTTP requests
- **debug**: Debug information

## Performance

- Database connection pooling
- Redis caching for frequently accessed data
- Image optimization and compression
- Pagination for large datasets
- Indexed database queries

## Security

- JWT token expiration
- Password hashing with bcrypt
- Input validation and sanitization
- CORS configuration
- Rate limiting (can be added)
- SQL injection prevention

## Deployment

### Environment Variables

Ensure all required environment variables are set in production:

```bash
NODE_ENV=production
PORT=3000
DB_HOST=your_db_host
DB_NAME=your_db_name
DB_USER=your_db_user
DB_PASSWORD=your_db_password
JWT_SECRET=your_secure_jwt_secret
```

### Production Considerations

- Use HTTPS in production
- Set up proper logging
- Configure database backups
- Set up monitoring and alerting
- Use a process manager like PM2
- Configure reverse proxy (nginx)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For support and questions, please contact the development team or create an issue in the repository. 