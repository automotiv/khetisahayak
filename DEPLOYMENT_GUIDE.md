# 🌾 Kheti Sahayak MVP Deployment Guide

## 🚀 **Quick Start - Complete MVP Setup**

This guide provides step-by-step instructions to deploy the Kheti Sahayak MVP with all implemented features.

---

## 📋 **Prerequisites**

### **System Requirements**
- **Java 17+** (for Spring Boot backend)
- **Node.js 18+** (for React frontend and development tools)
- **PostgreSQL 14+** (primary database)
- **Redis 6.2+** (caching and OTP storage)
- **Docker & Docker Compose** (recommended for easy setup)
- **Git** (for code management)

### **Optional for Production**
- **Maven 3.8+** (if not using Docker)
- **AWS Account** (for S3 file storage)
- **SMS Service** (Twilio, AWS SNS, etc.)

---

## 🐳 **Option 1: Docker Deployment (Recommended)**

### **1. Clone and Setup**
```bash
git clone https://github.com/automotiv/khetisahayak.git
cd khetisahayak
```

### **2. Environment Configuration**
Create `.env` file in project root:
```env
# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_NAME=kheti_sahayak
DB_USER=postgres
DB_PASSWORD=postgres123

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT Configuration
JWT_SECRET=kheti-sahayak-jwt-secret-key-change-in-production
JWT_EXPIRATION=86400000
JWT_REFRESH_EXPIRATION=604800000

# OTP Configuration
OTP_LENGTH=6
OTP_EXPIRY_MINUTES=5
OTP_MAX_ATTEMPTS=3
SMS_ENABLED=false

# ML Service Configuration
ML_SERVICE_URL=http://ml-service:8000
ML_SERVICE_TIMEOUT=30000
ML_SERVICE_ENABLED=true

# AWS S3 Configuration (Optional)
AWS_REGION=ap-south-1
AWS_S3_BUCKET=kheti-sahayak-uploads
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
CORS_ALLOWED_METHODS=GET,POST,PUT,PATCH,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=*
CORS_ALLOW_CREDENTIALS=false

# Spring Profiles
SPRING_PROFILES_ACTIVE=development
```

### **3. Docker Compose Setup**
Update `docker-compose.yml`:
```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:14-alpine
    container_name: kheti_postgres
    environment:
      POSTGRES_DB: kheti_sahayak
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres123
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./kheti_sahayak_spring_boot/src/main/resources/db/migration:/docker-entrypoint-initdb.d
    networks:
      - kheti_network

  # Redis Cache
  redis:
    image: redis:6.2-alpine
    container_name: kheti_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - kheti_network

  # Spring Boot Backend
  backend:
    build: 
      context: ./kheti_sahayak_spring_boot
      dockerfile: Dockerfile
    container_name: kheti_backend
    environment:
      - SPRING_PROFILES_ACTIVE=production
      - DB_HOST=postgres
      - DB_USER=postgres
      - DB_PASSWORD=postgres123
      - DB_NAME=kheti_sahayak
      - REDIS_HOST=redis
      - ML_SERVICE_URL=http://ml-service:8000
    ports:
      - "8080:8080"
    depends_on:
      - postgres
      - redis
    networks:
      - kheti_network
    volumes:
      - ./uploads:/app/uploads

  # ML Inference Service
  ml-service:
    build:
      context: ./ml
      dockerfile: Dockerfile.inference
    container_name: kheti_ml_service
    ports:
      - "8000:8000"
    volumes:
      - ./ml/models:/app/models
    networks:
      - kheti_network

  # React Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: kheti_frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_BASE_URL=http://localhost:8080
    depends_on:
      - backend
    networks:
      - kheti_network

  # Database Admin (Optional)
  adminer:
    image: adminer:latest
    container_name: kheti_adminer
    ports:
      - "8081:8080"
    networks:
      - kheti_network

volumes:
  postgres_data:
  redis_data:

networks:
  kheti_network:
    driver: bridge
```

### **4. Create Dockerfiles**

**Backend Dockerfile (`kheti_sahayak_spring_boot/Dockerfile`):**
```dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app

# Copy Maven files
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

# Download dependencies
RUN ./mvnw dependency:go-offline

# Copy source code
COPY src src

# Build application
RUN ./mvnw clean package -DskipTests

# Create uploads directory
RUN mkdir -p /app/uploads

# Expose port
EXPOSE 8080

# Run application
CMD ["java", "-jar", "target/kheti-sahayak-0.0.1-SNAPSHOT.jar"]
```

**Frontend Dockerfile (`frontend/Dockerfile`):**
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build application
RUN npm run build

# Install serve
RUN npm install -g serve

# Expose port
EXPOSE 3000

# Serve application
CMD ["serve", "-s", "build", "-l", "3000"]
```

### **5. Deploy**
```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### **6. Verify Deployment**
```bash
# Run test script
node test-kheti-sahayak-features.js

# Or test manually:
curl http://localhost:8080/api/health
curl http://localhost:8080/api/diagnostics/model-info
```

---

## 🔧 **Option 2: Manual Deployment**

### **1. Database Setup**
```bash
# Install PostgreSQL
sudo apt-get install postgresql postgresql-contrib  # Ubuntu/Debian
# OR
brew install postgresql  # macOS

# Start PostgreSQL
sudo systemctl start postgresql  # Ubuntu/Debian
# OR
brew services start postgresql  # macOS

# Create database
sudo -u postgres createdb kheti_sahayak
sudo -u postgres psql -c "CREATE USER postgres WITH PASSWORD 'postgres123';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE kheti_sahayak TO postgres;"

# Run migrations
psql -h localhost -U postgres -d kheti_sahayak -f kheti_sahayak_spring_boot/src/main/resources/db/migration/V001__Create_Initial_Schema.sql
```

### **2. Redis Setup**
```bash
# Install Redis
sudo apt-get install redis-server  # Ubuntu/Debian
# OR
brew install redis  # macOS

# Start Redis
sudo systemctl start redis-server  # Ubuntu/Debian
# OR
brew services start redis  # macOS
```

### **3. Backend Setup**
```bash
cd kheti_sahayak_spring_boot

# Set environment variables
export SPRING_PROFILES_ACTIVE=development
export DB_HOST=localhost
export DB_USER=postgres
export DB_PASSWORD=postgres123
export DB_NAME=kheti_sahayak
export REDIS_HOST=localhost
export ML_SERVICE_URL=http://localhost:8000

# Build and run (requires Maven)
./mvnw spring-boot:run

# OR using Java directly
./mvnw clean package
java -jar target/kheti-sahayak-0.0.1-SNAPSHOT.jar
```

### **4. ML Service Setup**
```bash
cd ml

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/macOS
# OR
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Start inference service
MODEL_DIR=./models MODEL_TYPE=onnx uvicorn inference_service:app --host 0.0.0.0 --port 8000
```

### **5. Frontend Setup**
```bash
cd frontend

# Install dependencies
npm install

# Set API URL
export REACT_APP_API_BASE_URL=http://localhost:8080

# Start development server
npm start

# OR build for production
npm run build
npm install -g serve
serve -s build -l 3000
```

---

## 📱 **Mobile App Deployment (Flutter)**

### **1. Setup Flutter Environment**
```bash
# Install Flutter (follow official guide)
# https://flutter.dev/docs/get-started/install

# Verify installation
flutter doctor

# Get dependencies
cd kheti_sahayak_app
flutter pub get
```

### **2. Configure API Endpoint**
Update `lib/.env`:
```env
API_BASE_URL=http://your-backend-url:8080/api
ENVIRONMENT=production
```

### **3. Build and Deploy**
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires Xcode on macOS)
flutter build ios --release

# Web
flutter build web --release
```

---

## 🌐 **Production Deployment**

### **1. Cloud Infrastructure Setup**

#### **AWS Deployment**
```bash
# EC2 instances
# - t3.medium for backend (2 vCPU, 4GB RAM)
# - t3.small for database (1 vCPU, 2GB RAM)
# - t3.micro for Redis (1 vCPU, 1GB RAM)

# RDS PostgreSQL
aws rds create-db-instance \
  --db-instance-identifier kheti-sahayak-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 14.9 \
  --allocated-storage 20 \
  --db-name kheti_sahayak \
  --master-username postgres \
  --master-user-password YourSecurePassword

# ElastiCache Redis
aws elasticache create-cache-cluster \
  --cache-cluster-id kheti-sahayak-redis \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --num-cache-nodes 1

# S3 Bucket for file storage
aws s3 mb s3://kheti-sahayak-uploads
```

#### **Docker Swarm / Kubernetes**
```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kheti-sahayak-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: kheti-sahayak-backend
  template:
    metadata:
      labels:
        app: kheti-sahayak-backend
    spec:
      containers:
      - name: backend
        image: khetisahayak/backend:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        - name: DB_HOST
          value: "postgres-service"
```

### **2. Environment Configuration**
```env
# Production environment variables
SPRING_PROFILES_ACTIVE=production
DB_HOST=your-rds-endpoint
DB_USER=postgres
DB_PASSWORD=your-secure-password
REDIS_HOST=your-elasticache-endpoint
AWS_REGION=ap-south-1
AWS_S3_BUCKET=kheti-sahayak-uploads
JWT_SECRET=your-super-secure-jwt-secret
SMS_ENABLED=true
ML_SERVICE_URL=http://your-ml-service-url:8000
```

### **3. SSL/TLS Setup**
```bash
# Let's Encrypt with Certbot
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d api.khetisahayak.com
sudo certbot --nginx -d app.khetisahayak.com
```

### **4. Nginx Configuration**
```nginx
# /etc/nginx/sites-available/khetisahayak
server {
    listen 80;
    server_name api.khetisahayak.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name api.khetisahayak.com;
    
    ssl_certificate /etc/letsencrypt/live/api.khetisahayak.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.khetisahayak.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 🧪 **Testing & Validation**

### **1. Health Checks**
```bash
# Backend health
curl http://localhost:8080/api/health

# Database connectivity
curl http://localhost:8080/actuator/health

# ML service
curl http://localhost:8000/health

# Redis connectivity
redis-cli ping
```

### **2. Feature Testing**
```bash
# Run comprehensive test suite
node test-kheti-sahayak-features.js

# Test authentication
curl -X POST http://localhost:8080/api/auth/register \
  -d "mobileNumber=9876543210&fullName=Test Farmer&state=Maharashtra&district=Nashik"

# Test crop diagnostics
curl -X POST http://localhost:8080/api/diagnostics/upload \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "image=@test-images/test-image.jpg" \
  -F "cropType=Rice" \
  -F "symptoms=Yellow spots on leaves"
```

### **3. Performance Testing**
```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Load test API endpoints
ab -n 1000 -c 10 http://localhost:8080/api/health
ab -n 100 -c 5 http://localhost:8080/api/weather?lat=19.9975&lon=73.7898
```

---

## 📊 **Monitoring & Maintenance**

### **1. Application Monitoring**
```bash
# Prometheus metrics
curl http://localhost:8080/actuator/prometheus

# Application logs
docker-compose logs -f backend
tail -f /var/log/kheti-sahayak/application.log
```

### **2. Database Maintenance**
```sql
-- Performance monitoring
SELECT * FROM pg_stat_activity;
SELECT * FROM pg_stat_user_tables;

-- Backup
pg_dump -h localhost -U postgres kheti_sahayak > backup_$(date +%Y%m%d).sql

-- Vacuum and analyze
VACUUM ANALYZE;
```

### **3. Security Updates**
```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Update Docker images
docker-compose pull
docker-compose up -d

# Check for vulnerabilities
docker scan khetisahayak/backend:latest
```

---

## 🚨 **Troubleshooting**

### **Common Issues**

#### **Backend Won't Start**
```bash
# Check Java version
java -version

# Check port availability
netstat -tulpn | grep :8080

# Check database connectivity
telnet localhost 5432

# View detailed logs
java -jar target/kheti-sahayak-0.0.1-SNAPSHOT.jar --debug
```

#### **Database Connection Issues**
```bash
# Test PostgreSQL connection
psql -h localhost -U postgres -d kheti_sahayak

# Check PostgreSQL status
sudo systemctl status postgresql

# Reset PostgreSQL password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'newpassword';"
```

#### **Redis Connection Issues**
```bash
# Test Redis connection
redis-cli ping

# Check Redis status
sudo systemctl status redis-server

# View Redis logs
sudo journalctl -u redis-server
```

#### **ML Service Issues**
```bash
# Check Python environment
python --version
pip list

# Test ML service directly
curl http://localhost:8000/health

# Check model files
ls -la ml/models/
```

### **Performance Issues**
```bash
# Check system resources
htop
df -h
free -h

# Check database performance
SELECT * FROM pg_stat_database;

# Optimize database
VACUUM FULL;
REINDEX DATABASE kheti_sahayak;
```

---

## 📞 **Support**

### **Documentation**
- [GitHub Wiki](https://github.com/automotiv/khetisahayak/wiki)
- [API Documentation](http://localhost:8080/api-docs)
- [Project Board](https://github.com/users/automotiv/projects/3)

### **Contact**
- 📧 Email: support@khetisahayak.com
- 🐛 Issues: [GitHub Issues](https://github.com/automotiv/khetisahayak/issues)
- 💬 Community: [Discord Server](#)

---

## 🎉 **Success Metrics**

Your deployment is successful when:

- ✅ All health checks pass
- ✅ Authentication flow works (registration/login)
- ✅ Image upload and ML diagnosis works
- ✅ Weather service returns data
- ✅ Database queries execute successfully
- ✅ Frontend communicates with backend
- ✅ Mobile app connects to APIs

**🌾 Congratulations! Kheti Sahayak MVP is now deployed and ready to serve farmers!**
