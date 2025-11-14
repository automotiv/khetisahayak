# Multi-stage build for Kheti Sahayak Spring Boot Application
# Optimized for production deployment with agricultural platform requirements

# Stage 1: Build the application
FROM openjdk:17-jdk-slim AS builder

# Set working directory
WORKDIR /app

# Copy Maven wrapper and pom.xml
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Make Maven wrapper executable
RUN chmod +x ./mvnw

# Download dependencies (this layer will be cached if pom.xml doesn't change)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN ./mvnw clean package -DskipTests

# Stage 2: Runtime image
FROM openjdk:17-jre-slim

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN groupadd -r kheti && useradd -r -g kheti kheti

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the JAR file from builder stage
COPY --from=builder /app/target/kheti-sahayak-*.jar app.jar

# Create logs directory
RUN mkdir -p /app/logs && chown -R kheti:kheti /app

# Switch to non-root user
USER kheti

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# JVM optimization for agricultural platform
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseStringDeduplication -Djava.security.egd=file:/dev/./urandom"

# Start the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]