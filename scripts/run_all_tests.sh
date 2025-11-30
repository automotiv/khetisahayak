#!/bin/bash

# Exit on error
set -e

echo "🧪 Running Backend Tests..."
cd kheti_sahayak_backend
npm test --if-present
cd ..

echo "🧪 Running Frontend Tests..."
cd frontend
npm test --if-present
cd ..

echo "🧪 Running Mobile Tests..."
cd kheti_sahayak_app
flutter test
cd ..

echo "✅ All tests passed!"
