# 📊 Monitoring & Logging Setup Guide

## Overview
Comprehensive monitoring, logging, and alerting infrastructure for production-grade Kheti Sahayak deployment.

## Logging Architecture

### 1. Application Logging

#### Backend Logging (Node.js)
```javascript
// Using Winston + JSON structured logging
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { 
    service: 'kheti-backend',
    environment: process.env.NODE_ENV,
    version: process.env.APP_VERSION
  },
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' })
  ]
});
```

#### Flutter Logging
```dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
);

logger.i('User logged in');
logger.e('Login failed', error);
```

### 2. Log Aggregation (ELK Stack)

#### Elasticsearch Setup
```yaml
# elasticsearch/docker-compose.yml
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data

  kibana:
    image: docker.elastic.co/kibana/kibana:8.0.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.0.0
    volumes:
      - ./filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  es_data:
```

#### Logstash Configuration
```conf
input {
  tcp {
    port => 5000
    codec => json
  }
}

filter {
  if [type] == "backend" {
    mutate {
      add_field => { "environment" => "${ENVIRONMENT}" }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "logs-%{+YYYY.MM.dd}"
  }
}
```

## Metrics & Monitoring

### 1. Prometheus Setup

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'backend'
    static_configs:
      - targets: ['localhost:3000']
    metrics_path: '/metrics'

  - job_name: 'postgres'
    static_configs:
      - targets: ['localhost:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:9121']

  - job_name: 'kubernetes'
    kubernetes_sd_configs:
      - role: pod
```

### 2. Application Metrics (Backend)

```javascript
const prometheus = require('prom-client');

// Default metrics
prometheus.collectDefaultMetrics();

// Custom metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 5, 15, 50, 100, 500]
});

const activeUsers = new prometheus.Gauge({
  name: 'active_users',
  help: 'Number of active users'
});

const diagnosticsProcessed = new prometheus.Counter({
  name: 'diagnostics_processed_total',
  help: 'Total crop diagnostics processed',
  labelNames: ['crop_type', 'status']
});

// Middleware to record metrics
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    httpRequestDuration
      .labels(req.method, req.route?.path, res.statusCode)
      .observe(duration);
  });
  next();
});

app.get('/metrics', (req, res) => {
  res.set('Content-Type', prometheus.register.contentType);
  res.end(prometheus.register.metrics());
});
```

### 3. Grafana Dashboards

#### Key Dashboards
1. **System Overview**
   - CPU, Memory, Disk usage
   - Network I/O
   - Container health

2. **Application Performance**
   - Request latency (p50, p95, p99)
   - Error rate & types
   - Throughput
   - Database query performance

3. **Business Metrics**
   - Active users
   - Diagnostics per hour
   - Marketplace transactions
   - Feature usage

4. **Infrastructure**
   - Pod status
   - Node health
   - Storage usage
   - Network saturation

## Alerting Rules

### Prometheus Alert Rules

```yaml
# prometheus/alert-rules.yml
groups:
  - name: application
    rules:
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m])) /
            sum(rate(http_requests_total[5m]))
          ) > 0.05
        for: 5m
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }}"

      - alert: HighLatency
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_ms_bucket[5m])) by (le)
          ) > 500
        for: 5m
        annotations:
          summary: "High API latency"
          description: "P99 latency is {{ $value }}ms"

      - alert: DatabaseDown
        expr: pg_up == 0
        for: 1m
        annotations:
          summary: "PostgreSQL database is down"

      - alert: HighCPUUsage
        expr: |
          (100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80
        for: 5m

      - alert: LowDiskSpace
        expr: |
          (node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.lowerdir|squashfs|vfat"} / 
           node_filesystem_size_bytes) < 0.1
        for: 5m

      - alert: HighMemoryUsage
        expr: |
          (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.85
        for: 5m
```

## Error Tracking (Sentry)

### Backend Integration
```javascript
const Sentry = require('@sentry/node');

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
  integrations: [
    new Sentry.Integrations.Http({ tracing: true }),
    new Sentry.Integrations.Express({ request: true, serverName: true }),
  ],
});

app.use(Sentry.Handlers.requestHandler());

// Your routes...

app.use(Sentry.Handlers.errorHandler());
```

### Frontend Integration
```dart
import 'package:sentry/sentry.dart';

await Sentry.init(
  'YOUR_DSN_HERE',
  tracesSampleRate: 1.0,
  environment: kDebugMode ? 'development' : 'production',
);

// Capture exceptions
try {
  // code
} catch (exception, stackTrace) {
  await Sentry.captureException(
    exception,
    stackTrace: stackTrace,
  );
}
```

## Distributed Tracing (Jaeger)

```yaml
# kubernetes/jaeger.yaml
apiVersion: v1
kind: Service
metadata:
  name: jaeger
spec:
  selector:
    app: jaeger
  ports:
    - port: 6831
      protocol: UDP
    - port: 16686  # UI
      protocol: TCP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:latest
        ports:
        - containerPort: 6831
          protocol: UDP
        - containerPort: 16686
```

## Health Checks

### Readiness & Liveness Probes

```yaml
# kubernetes/backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kheti-backend
spec:
  template:
    spec:
      containers:
      - name: backend
        livenessProbe:
          httpGet:
            path: /health/live
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /health/ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
```

### Health Check Endpoint

```javascript
app.get('/health/live', (req, res) => {
  res.json({ status: 'alive', timestamp: new Date() });
});

app.get('/health/ready', async (req, res) => {
  try {
    // Check database
    await db.query('SELECT 1');
    
    // Check cache
    await redis.ping();
    
    res.json({ status: 'ready', timestamp: new Date() });
  } catch (error) {
    res.status(503).json({ status: 'not_ready', error: error.message });
  }
});
```

## Deployment

### Docker Compose

```bash
docker-compose -f monitoring/docker-compose.yml up -d
```

### Kubernetes

```bash
kubectl apply -f monitoring/kubernetes/
```

## Dashboard Access URLs

- **Kibana**: http://localhost:5601
- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686
- **Sentry**: https://sentry.io

## Best Practices

1. **Structured Logging**: Always log in JSON format
2. **Log Levels**: Use appropriate levels (debug, info, warn, error)
3. **PII Protection**: Never log sensitive data
4. **Metric Naming**: Follow Prometheus naming conventions
5. **Alert Tuning**: Avoid alert fatigue with appropriate thresholds
6. **Retention**: Set log retention policies (7-30 days)
7. **Performance**: Ensure monitoring doesn't impact application
8. **Testing**: Test alerts in staging before production
