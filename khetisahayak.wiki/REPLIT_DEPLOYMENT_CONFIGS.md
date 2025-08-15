
# Replit Deployment Configurations

## Backend Services Deployment

### Main API Service (Autoscale Deployment)
```bash
# This will be configured in Replit's deployment interface
Name: kheti-sahayak-api
Type: Autoscale Deployment
Port: 3000
Build Command: npm install
Run Command: npm start
Environment: Production
```

### Database Configuration
```bash
# Replit PostgreSQL Database
Database: kheti_sahayak_prod
Connection: Use Replit's database connection string
Backup: Daily automated backups
```

### Environment Variables (Replit Secrets)
```
NODE_ENV=production
PORT=3000
DATABASE_URL=<replit_postgres_connection_string>
REDIS_URL=<redis_connection_string>
JWT_SECRET=<production_jwt_secret>
WEATHER_API_KEY=<weather_api_key>
PAYMENT_API_KEY=<payment_gateway_key>
SMS_API_KEY=<sms_service_key>
EMAIL_API_KEY=<email_service_key>
S3_BUCKET_NAME=<s3_bucket_name>
S3_ACCESS_KEY=<s3_access_key>
S3_SECRET_KEY=<s3_secret_key>
CORS_ORIGIN=https://kheti-sahayak-app.com
```

### Service-Specific Deployments

#### Authentication Service
```bash
Name: kheti-sahayak-auth
Type: Autoscale Deployment
Port: 3001
Run Command: node services/auth/server.js
```

#### Marketplace Service
```bash
Name: kheti-sahayak-marketplace
Type: Autoscale Deployment
Port: 3002
Run Command: node services/marketplace/server.js
```

#### Diagnostics Service
```bash
Name: kheti-sahayak-diagnostics
Type: Reserved VM Deployment
Port: 3003
Run Command: node services/diagnostics/server.js
Machine Size: 4 CPU, 8GB RAM (for ML processing)
```

#### Weather Service
```bash
Name: kheti-sahayak-weather
Type: Autoscale Deployment
Port: 3004
Run Command: node services/weather/server.js
```

#### Notification Service
```bash
Name: kheti-sahayak-notifications
Type: Autoscale Deployment
Port: 3005
Run Command: node services/notifications/server.js
```

## Production Deployment Steps

### 1. Backend API Deployment
1. Push code to main branch
2. Configure environment variables in Replit Secrets
3. Set up database connections
4. Deploy using Autoscale Deployment
5. Configure custom domain (optional)

### 2. Database Setup
1. Create PostgreSQL database in Replit
2. Run migrations: `npm run migrate:prod`
3. Seed initial data: `npm run seed:prod`
4. Configure backup schedule

### 3. Monitoring Setup
1. Enable Replit's built-in monitoring
2. Configure external monitoring services
3. Set up log aggregation
4. Configure alerting thresholds

### 4. Security Configuration
1. Enable HTTPS enforcement
2. Configure CORS settings
3. Set up rate limiting
4. Enable security headers

## Scaling Configuration

### Auto-scaling Rules
```javascript
// Example auto-scaling configuration
{
  "minInstances": 2,
  "maxInstances": 10,
  "targetCPUUtilization": 70,
  "targetMemoryUtilization": 80,
  "scaleUpCooldown": 300,
  "scaleDownCooldown": 600
}
```

### Load Balancing
- Replit automatically handles load balancing for Autoscale deployments
- Configure health checks for all services
- Set up failover mechanisms

## Backup & Recovery

### Database Backups
- Daily automated backups via Replit
- Weekly full database exports
- Point-in-time recovery capability
- Cross-region backup replication

### Application Backups
- Git-based version control
- Container image backups
- Configuration backups
- SSL certificate backups

## Monitoring & Alerting

### Key Metrics to Monitor
- API response times
- Error rates
- Database performance
- Memory and CPU usage
- Network latency
- User authentication success rates

### Alert Thresholds
- Response time > 1000ms
- Error rate > 1%
- CPU usage > 80%
- Memory usage > 85%
- Database connections > 80% of pool

## Security Best Practices

### Network Security
- Enable HTTPS everywhere
- Configure proper CORS settings
- Implement rate limiting
- Use secure session management

### Data Security
- Encrypt sensitive data at rest
- Use parameterized queries
- Implement input validation
- Regular security audits

### Access Control
- Implement least privilege principle
- Use JWT tokens with short expiration
- Multi-factor authentication for admin access
- Regular access reviews

## Performance Optimization

### Database Optimization
- Implement connection pooling
- Add appropriate indexes
- Optimize query performance
- Use read replicas for read-heavy operations

### API Optimization
- Implement response caching
- Use compression for large responses
- Optimize serialization
- Implement pagination

### Frontend Optimization
- Use CDN for static assets
- Implement lazy loading
- Optimize images and media
- Minimize bundle sizes

This configuration provides a comprehensive setup for deploying the Kheti Sahayak platform on Replit with production-ready settings.
