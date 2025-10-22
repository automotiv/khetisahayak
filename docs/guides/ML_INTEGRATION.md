# ML Model Integration Guide

## Overview

This document explains how the ML model for crop disease diagnosis has been integrated with the Kheti Sahayak application. The integration connects the FastAPI inference service with the Express.js backend and Flutter frontend.

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Flutter   │     │  Express.js │     │   FastAPI   │
│  Frontend   │────▶│   Backend   │────▶│ ML Service  │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Components

### 1. ML Inference Service (FastAPI)

- Provides a RESTful API for image analysis
- Endpoints:
  - `/health`: Health check endpoint
  - `/model-info`: Returns model metadata
  - `/predict`: Accepts image uploads and returns predictions
- Containerized with Docker

### 2. Backend Integration (Express.js)

- New `mlService.js` module to communicate with the ML service
- Updated `diagnosticsController.js` to use the ML service
- Fallback to mock responses if the ML service is unavailable

### 3. Frontend Integration (Flutter)

- No changes needed to the Flutter app as it already communicates with the backend

## Setup Instructions

### Environment Variables

Add the following environment variable to your backend `.env` file:

```
ML_API_URL=http://localhost:8000
```

In production, set this to the appropriate URL of your deployed ML service.

### Running with Docker Compose

The easiest way to run the integrated application is using Docker Compose:

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Running Services Separately

#### ML Service

```bash
cd ml
docker build -t kheti-ml-inference -f Dockerfile.inference .
docker run -p 8000:8000 -v $(pwd)/models:/app/models kheti-ml-inference
```

#### Backend

```bash
cd kheti_sahayak_backend
npm install
npm start
```

#### Frontend

```bash
cd kheti_sahayak_app
flutter pub get
flutter run
```

## Testing the Integration

1. Start all services
2. Open the Flutter app
3. Navigate to the Diagnostics screen
4. Upload an image of a crop with disease symptoms
5. Fill in the crop type and issue description
6. Submit for analysis
7. Verify that the results come from the ML model

## Troubleshooting

### ML Service Connection Issues

If the backend cannot connect to the ML service:

1. Check that the ML service is running (`docker ps` or check port 8000)
2. Verify the `ML_API_URL` environment variable is set correctly
3. Check the backend logs for specific error messages

### Image Processing Issues

If image analysis fails:

1. Verify the image format is supported (JPEG, PNG)
2. Check the image size (should be less than 10MB)
3. Ensure the ML model files are correctly placed in the models directory

## Future Improvements

1. Add authentication between backend and ML service
2. Implement caching for frequent predictions
3. Add model versioning and A/B testing capabilities
4. Implement batch processing for multiple images
5. Add feedback loop to improve model accuracy over time