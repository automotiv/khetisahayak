#!/bin/bash

# Exit on error
set -e

echo "🚀 Deploying Frontend to Vercel..."
cd frontend

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "⚠️ Vercel CLI not found. Using npx..."
    npx vercel --prod
else
    vercel --prod
fi

cd ..
echo "✅ Frontend deployment triggered!"
