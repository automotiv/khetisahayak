#!/bin/bash

# Kheti Sahayak Application Startup Script
# Implements CodeRabbit deployment standards for agricultural platform

set -e

echo "🌾 Starting Kheti Sahayak Agricultural Platform..."
echo "=================================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p logs
mkdir -p data/postgres
mkdir -p data/redis

# Set environment variables
export COMPOSE_PROJECT_NAME=kheti-sahayak
export SPRING_PROFILES_ACTIVE=docker

echo "🔧 Building and starting services..."

# Build and start all services
docker-compose up --build -d

echo "⏳ Waiting for services to be ready..."

# Wait for PostgreSQL to be ready
echo "🐘 Waiting for PostgreSQL..."
until docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    echo "   PostgreSQL is starting..."
    sleep 2
done
echo "✅ PostgreSQL is ready!"

# Wait for Redis to be ready
echo "🔴 Waiting for Redis..."
until docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; do
    echo "   Redis is starting..."
    sleep 2
done
echo "✅ Redis is ready!"

# Wait for Spring Boot backend to be ready
echo "☕ Waiting for Spring Boot backend..."
until curl -f http://localhost:8080/api/health > /dev/null 2>&1; do
    echo "   Spring Boot backend is starting..."
    sleep 5
done
echo "✅ Spring Boot backend is ready!"

# Wait for React frontend to be ready
echo "⚛️ Waiting for React frontend..."
until curl -f http://localhost:3000 > /dev/null 2>&1; do
    echo "   React frontend is starting..."
    sleep 3
done
echo "✅ React frontend is ready!"

echo ""
echo "🎉 Kheti Sahayak is now running!"
echo "=================================================="
echo ""
echo "📱 Frontend (React):     http://localhost:3000"
echo "🔧 Backend API:          http://localhost:8080"
echo "📚 API Documentation:    http://localhost:8080/api-docs"
echo "🏥 Health Check:         http://localhost:8080/api/health"
echo "🗄️ Database Admin:       http://localhost:8081"
echo "🔴 Redis Admin:          http://localhost:8082"
echo ""
echo "🔍 To view logs:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 To stop the application:"
echo "   docker-compose down"
echo ""
echo "🌾 Welcome to Kheti Sahayak - Empowering Indian Farmers!"
echo "=================================================="
