#!/bin/bash

# Kheti Sahayak Setup Script
# This script helps set up the development environment for both backend and frontend

set -e  # Exit on any error

echo "🌾 Welcome to Kheti Sahayak Setup!"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js v16 or higher."
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        print_error "Node.js version 16 or higher is required. Current version: $(node -v)"
        exit 1
    fi
    print_success "Node.js $(node -v) is installed"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed."
        exit 1
    fi
    print_success "npm $(npm -v) is installed"
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        print_warning "Flutter is not installed. Please install Flutter SDK for frontend development."
        FRONTEND_AVAILABLE=false
    else
        print_success "Flutter $(flutter --version | head -n1 | cut -d' ' -f2) is installed"
        FRONTEND_AVAILABLE=true
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed. You'll need to set up PostgreSQL and Redis manually."
        DOCKER_AVAILABLE=false
    else
        print_success "Docker $(docker --version | cut -d' ' -f3 | cut -d',' -f1) is installed"
        DOCKER_AVAILABLE=true
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed."
        exit 1
    fi
    print_success "Git $(git --version | cut -d' ' -f3) is installed"
}

# Setup backend
setup_backend() {
    print_status "Setting up backend..."
    
    cd kheti_sahayak_spring_boot
    
    # Install dependencies
    print_status "Installing backend dependencies..."
    npm install
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        print_status "Creating .env file..."
        cat > .env << EOF
# Server Configuration
NODE_ENV=development
PORT=3000

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=kheti_sahayak
DB_USER=postgres
DB_PASSWORD=postgres

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_change_this_in_production
JWT_EXPIRES_IN=7d

# AWS S3 Configuration (Optional)
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
EOF
        print_success "Created .env file. Please update the configuration as needed."
    else
        print_status ".env file already exists"
    fi
    
    cd ..
}

# Setup frontend
setup_frontend() {
    if [ "$FRONTEND_AVAILABLE" = false ]; then
        print_warning "Skipping frontend setup - Flutter not installed"
        return
    fi
    
    print_status "Setting up frontend..."
    
    cd kheti_sahayak_app
    
    # Install dependencies
    print_status "Installing Flutter dependencies..."
    flutter pub get
    
    # Create .env file if it doesn't exist
    if [ ! -f lib/.env ]; then
        print_status "Creating frontend .env file..."
        cat > lib/.env << EOF
# API Configuration
API_BASE_URL=http://localhost:3000/api
API_TIMEOUT=30000

# Feature Flags
ENABLE_NOTIFICATIONS=true
ENABLE_OFFLINE_MODE=true
ENABLE_ANALYTICS=false

# App Configuration
APP_NAME=Kheti Sahayak
APP_VERSION=1.0.0
EOF
        print_success "Created frontend .env file"
    else
        print_status "Frontend .env file already exists"
    fi
    
    cd ..
}

# Setup database
setup_database() {
    if [ "$DOCKER_AVAILABLE" = true ]; then
        print_status "Setting up database with Docker..."
        
        # Start PostgreSQL and Redis
        cd kheti_sahayak_spring_boot
        docker-compose up -d postgres redis
        
        # Wait for database to be ready
        print_status "Waiting for database to be ready..."
        sleep 10
        
        # Run migrations
        print_status "Running database migrations..."
        npm run migrate
        
        # Seed database
        print_status "Seeding database..."
        npm run seed
        
        cd ..
        print_success "Database setup completed"
    else
        print_warning "Docker not available. Please set up PostgreSQL and Redis manually:"
        echo "1. Install PostgreSQL and create database 'kheti_sahayak'"
        echo "2. Install Redis"
        echo "3. Update .env file with correct database credentials"
        echo "4. Run: cd kheti_sahayak_spring_boot && ./mvnw spring-boot:run"
    fi
}

# Main setup function
main() {
    echo ""
    print_status "Starting Kheti Sahayak setup..."
    
    # Check prerequisites
    check_prerequisites
    
    echo ""
    print_status "Setting up project components..."
    
    # Setup backend
    setup_backend
    
    # Setup frontend
    setup_frontend
    
    # Setup database
    setup_database
    
    echo ""
    print_success "Setup completed successfully!"
    echo ""
    echo "🎉 Next steps:"
    echo "=============="
    echo ""
    echo "1. Backend:"
    echo "   cd kheti_sahayak_spring_boot"
    echo "   ./mvnw spring-boot:run"
    echo "   API will be available at: http://localhost:8080"
    echo "   API docs at: http://localhost:8080/api-docs/"
    echo ""
    
    if [ "$FRONTEND_AVAILABLE" = true ]; then
        echo "2. Frontend:"
        echo "   cd kheti_sahayak_app"
        echo "   flutter run"
        echo ""
    fi
    
    echo "3. Documentation:"
    echo "   - Main README: README.md"
    echo "   - Backend README: kheti_sahayak_spring_boot/README.md"
    if [ "$FRONTEND_AVAILABLE" = true ]; then
        echo "   - Frontend README: kheti_sahayak_app/README.md"
    fi
    echo ""
    echo "4. Environment Configuration:"
    echo "   - Update .env files with your specific configuration"
    echo "   - Set up AWS S3 credentials if using file uploads"
    echo "   - Configure email settings if using notifications"
    echo ""
    echo "Happy coding! 🌾"
}

# Run main function
main "$@" 