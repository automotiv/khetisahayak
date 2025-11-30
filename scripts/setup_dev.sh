#!/bin/bash

# Exit on error
set -e

echo "📦 Setting up Backend..."
cd kheti_sahayak_backend
npm install
cd ..

echo "📦 Setting up Frontend..."
cd frontend
npm install
cd ..

echo "📦 Setting up Mobile..."
cd kheti_sahayak_app
flutter pub get
cd ..

echo "🚀 Development environment ready!"
