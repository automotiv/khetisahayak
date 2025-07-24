# Flutter Web Dockerfile
# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Build web app
RUN flutter build web --release

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
