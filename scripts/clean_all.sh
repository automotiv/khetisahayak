#!/bin/bash

echo "🧹 Cleaning Backend..."
cd kheti_sahayak_backend
rm -rf node_modules
rm -rf coverage
cd ..

echo "🧹 Cleaning Frontend..."
cd frontend
rm -rf node_modules
rm -rf build
rm -rf coverage
cd ..

echo "🧹 Cleaning Mobile..."
cd kheti_sahayak_app
flutter clean
cd ..

echo "✨ All projects cleaned!"
