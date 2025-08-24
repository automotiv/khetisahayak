# Production-Grade ML Pipeline for Crop Diagnostics

## Overview
This repository contains a production-ready machine learning pipeline for crop disease diagnostics. The system includes comprehensive features for training, validation, model tracking, deployment, and inference.

## Contents
- `requirements.txt` — Python dependencies for development and production
- `train.py` — Training entrypoint with MLflow tracking, validation splits, and model export
- `dataset.py` — Dataset implementation with validation splits and class weighting
- `utils.py` — Metrics, evaluation helpers, and visualization utilities
- `data_validation.py` — Data validation pipeline for ensuring data quality
- `inference_service.py` — FastAPI service for model inference
- `Dockerfile` — Container for training experiments
- `Dockerfile.inference` — Optimized container for inference service
- `.github/workflows/ml-pipeline.yml` — CI/CD pipeline configuration

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

### Inference Service
- FastAPI-based REST API
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
   ```
   MODEL_DIR=./artifacts/exported MODEL_TYPE=onnx uvicorn inference_service:app --host 0.0.0.0 --port 8000
   ```

2. Or use Docker:
   ```
   docker build -f Dockerfile.inference -t khetisahayak-inference .
   docker run -p 8000:8000 -v $(pwd)/artifacts/exported:/app/models khetisahayak-inference
   ```

### CI/CD Pipeline
1. The GitHub Actions workflow can be triggered manually or automatically on pushes to the main branch.
2. Configure the necessary secrets in your GitHub repository for AWS access and Docker Hub credentials.

## Environment Variables
- `MODEL_DIR`: Directory containing model artifacts (default: ./artifacts/exported)
- `MODEL_TYPE`: Type of model to load (onnx, torchscript, pytorch) (default: onnx)
- `MLFLOW_TRACKING_URI`: MLflow tracking server URI

## Notes
- This system is designed for production use with scalability and reliability in mind.
- Extend with additional features like A/B testing, model monitoring, and automated retraining as needed.
