# Production-Grade ML Pipeline for Crop Diagnostics

## Overview
This repository contains a production-ready machine learning pipeline for crop disease diagnostics. The system includes comprehensive features for training, validation, model tracking, deployment, and inference.

**Supports 20+ crops commonly grown in India with detailed disease information in English and Hindi.**

## Contents
- `requirements.txt` — Python dependencies for development and production
- `train.py` — Training entrypoint with MLflow tracking, validation splits, and model export
- `dataset.py` — Dataset implementation with validation splits and class weighting
- `utils.py` — Metrics, evaluation helpers, and visualization utilities
- `data_validation.py` — Data validation pipeline for ensuring data quality
- `inference_service.py` — FastAPI service for model inference (v2.0)
- `model_manager.py` — Multi-crop model management with mock/real mode support
- `preprocessing.py` — Image preprocessing and TTA (Test-Time Augmentation)
- `disease_database.py` — Comprehensive disease database with treatments
- `Dockerfile` — Container for training experiments
- `Dockerfile.inference` — Optimized container for inference service
- `.github/workflows/ml-pipeline.yml` — CI/CD pipeline configuration

## Supported Crops (20+)

| Crop | Hindi Name | Diseases |
|------|------------|----------|
| Rice | धान | 7 |
| Wheat | गेहूं | 5 |
| Maize | मक्का | 4 |
| Tomato | टमाटर | 6 |
| Potato | आलू | 4 |
| Cotton | कपास | 4 |
| Sugarcane | गन्ना | 4 |
| Onion | प्याज | 4 |
| Chilli | मिर्च | 4 |
| Brinjal | बैंगन | 4 |
| Cabbage | पत्तागोभी | 3 |
| Cauliflower | फूलगोभी | 3 |
| Okra | भिंडी | 3 |
| Cucumber | खीरा | 3 |
| Mango | आम | 4 |
| Banana | केला | 4 |
| Grapes | अंगूर | 4 |
| Apple | सेब | 4 |
| Groundnut | मूंगफली | 3 |
| Soybean | सोयाबीन | 3 |

## Features

### Data Management
- Manifest-based dataset (CSV with image_path,label)
- Automatic train/validation/test splitting
- Class balancing and weighting
- Data validation pipeline with Great Expectations
- Image integrity checking

### Training
- Transfer learning with `timm` models
- Configurable data augmentation with Albumentations
- Class-weighted loss functions
- Learning rate scheduling
- Comprehensive evaluation metrics

### Experiment Tracking
- MLflow integration for experiment tracking
- Hyperparameter logging
- Metrics visualization
- Model versioning and registry

### Model Export
- ONNX format export for cross-platform compatibility
- TorchScript export for optimized deployment
- Model metadata and class mapping preservation

### Inference Service (v2.0)
- FastAPI-based REST API with comprehensive endpoints
- Multi-crop model support with automatic fallback to mock mode
- Confidence calibration for realistic predictions
- Test-Time Augmentation (TTA) for improved accuracy
- Batch prediction support
- Disease search and analytics
- Bilingual support (English/Hindi)
- Optimized Docker container
- Health checks and monitoring
- Scalable deployment options

### CI/CD Pipeline
- Automated testing and linting
- Configurable model training
- Containerized deployment
- Kubernetes integration

## Quick Start

### Development Setup
1. Create a Python venv and install dependencies:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

### Data Validation
1. Validate your dataset before training:
   ```
   python data_validation.py --manifest data/manifest.csv --output validation_report.json
   ```

### Training
1. Train a model with MLflow tracking:
   ```
   python train.py \
     --manifest data/manifest.csv \
     --output-dir ./artifacts \
     --epochs 10 \
     --batch-size 32 \
     --experiment-name crop_disease \
     --run-name production_run \
     --val-size 0.2 \
     --export-model
   ```

### Inference Service
1. Start the FastAPI inference service:
   ```bash
   MODELS_DIR=./models uvicorn inference_service:app --host 0.0.0.0 --port 8000
   ```

2. Or use Docker:
   ```bash
   docker build -f Dockerfile.inference -t khetisahayak-inference .
   docker run -p 8000:8000 -v $(pwd)/models:/app/models khetisahayak-inference
   ```

3. Access API documentation at: http://localhost:8000/docs

## API Endpoints

### Prediction Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/predict` | Predict disease from uploaded image |
| POST | `/predict/base64` | Predict from base64-encoded image |
| POST | `/batch-predict` | Batch prediction for multiple images |

### Crops & Diseases

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/crops` | List all supported crops |
| GET | `/crops/{crop_type}` | Get crop details and diseases |
| GET | `/diseases/{crop_type}` | List diseases for a crop |
| GET | `/diseases/{crop_type}/{disease_id}` | Get detailed disease info |

### Model Information

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/model-info` | Get all model information |
| GET | `/model-info/{crop_type}` | Get model info for specific crop |

### Utilities

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check endpoint |
| POST | `/image/validate` | Validate uploaded image |
| GET | `/search/diseases` | Search diseases by keyword |
| GET | `/analytics/predictions` | Get prediction analytics |

## Example API Usage

### Predict Disease
```bash
curl -X POST "http://localhost:8000/predict" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@rice_leaf.jpg" \
  -F "crop_type=rice" \
  -F "use_tta=false"
```

### Response Format
```json
{
  "success": true,
  "crop_type": "rice",
  "disease_id": "rice_blast",
  "disease_name": "Rice Blast",
  "disease_hindi_name": "धान का झुलसा",
  "confidence": 0.87,
  "severity": "high",
  "description": "Fungal disease caused by Magnaporthe oryzae...",
  "symptoms": ["Diamond-shaped lesions on leaves", ...],
  "treatments": [
    {"type": "chemical", "name": "Tricyclazole 75% WP", "dosage": "0.6 g/liter water"}
  ],
  "prevention": ["Use resistant varieties", ...],
  "similar_diseases": [...],
  "mock_prediction": false,
  "inference_time_ms": 45.2
}
```

### Get Supported Crops
```bash
curl http://localhost:8000/crops
```

### Search Diseases
```bash
curl "http://localhost:8000/search/diseases?query=blight&crop_type=rice"
```

### CI/CD Pipeline
1. The GitHub Actions workflow can be triggered manually or automatically on pushes to the main branch.
2. Configure the necessary secrets in your GitHub repository for AWS access and Docker Hub credentials.

## Environment Variables
- `MODELS_DIR`: Directory containing crop-specific model folders (default: ./models)
- `MODEL_TYPE`: Type of model to load (onnx, torchscript) (default: onnx)
- `MLFLOW_TRACKING_URI`: MLflow tracking server URI

## Model Directory Structure

```
models/
├── rice/
│   ├── model.onnx          # ONNX model file
│   ├── model_metadata.json  # Model configuration
│   └── class_mapping.json   # Disease class labels
├── wheat/
│   ├── model.onnx
│   ├── model_metadata.json
│   └── class_mapping.json
└── ...
```

When model files are not available, the service automatically runs in **mock mode** with realistic predictions using the disease database.

## Mock Mode vs Real Mode

| Feature | Mock Mode | Real Mode |
|---------|-----------|-----------|
| Model Files | Not required | Required |
| Predictions | Randomized with realistic confidence | Actual inference |
| Disease Info | Full database support | Full database support |
| Treatments | Available | Available |
| Use Case | Development, testing | Production |

## Notes
- This system is designed for production use with scalability and reliability in mind.
- Mock mode provides realistic responses for development/testing when models aren't available.
- All disease information includes both English and Hindi translations.
- Confidence calibration prevents overconfident predictions.
- Extend with additional features like A/B testing, model monitoring, and automated retraining as needed.
