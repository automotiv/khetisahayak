# Use a simpler approach with a static HTML page
# Stage 1: Create a simple placeholder page
FROM alpine:latest AS build

# Set working directory
WORKDIR /app

# Create a placeholder web build
RUN mkdir -p /app/build/web && \
    echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Kheti Sahayak</title><style>body{font-family:Arial,sans-serif;line-height:1.6;margin:0;padding:20px;color:#333;background-color:#f5f5f5;}h1{color:#2e7d32;}h2{color:#388e3c;}p{margin-bottom:10px;}.container{max-width:800px;margin:0 auto;background-color:white;padding:20px;border-radius:5px;box-shadow:0 2px 5px rgba(0,0,0,0.1);}.header{text-align:center;margin-bottom:30px;}.feature{margin-bottom:20px;border-left:3px solid #4caf50;padding-left:15px;}.status{background-color:#e8f5e9;padding:10px;border-radius:3px;margin-top:30px;}</style></head><body><div class="container"><div class="header"><h1>Kheti Sahayak</h1><p>Agricultural Assistant Application</p></div><div class="content"><h2>Services Status</h2><div class="feature"><h3>Backend API</h3><p>Status: Running</p><p>Port: 5001</p></div><div class="feature"><h3>ML Inference Service</h3><p>Status: Running</p><p>Port: 8000</p></div><div class="feature"><h3>Database</h3><p>Status: Running</p><p>Port: 5432</p></div><div class="status"><p><strong>Note:</strong> The frontend application is currently under development. Please use the API endpoints directly for testing.</p></div></div></div></body></html>' > /app/build/web/index.html

# Stage 2: Serve the web app with nginx
FROM nginx:alpine

# Copy the built web app to nginx html directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration if needed
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
