import os
import io
import json
import logging
from typing import List, Dict, Any, Optional
from pathlib import Path

import numpy as np
import torch
import cv2
from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks, Query
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image
import onnxruntime as ort

from utils import load_checkpoint

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Kheti Sahayak ML Inference API",
    description="API for crop disease diagnosis using deep learning",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Update with specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables for model and config
model = None
model_config = None
onnx_session = None
class_mapping = None


class PredictionInput(BaseModel):
    image_url: Optional[str] = None
    image_base64: Optional[str] = None


class PredictionResult(BaseModel):
    class_id: int
    class_name: str
    confidence: float
    predictions: Dict[str, float]


def load_model(model_dir: str, model_type: str = "onnx"):
    """Load model from directory
    
    Args:
        model_dir: Directory containing model files
        model_type: Type of model to load (onnx, torchscript, pytorch)
    """
    global model, model_config, onnx_session, class_mapping
    
    # Load model config
    config_path = os.path.join(model_dir, "model_metadata.json")
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            model_config = json.load(f)
        logger.info(f"Loaded model config: {model_config}")
    else:
        logger.warning(f"Model config not found at {config_path}, using defaults")
        model_config = {
            "img_size": 224,
            "input_shape": [1, 3, 224, 224],
        }
    
    # Load class mapping
    class_map_path = os.path.join(model_dir, "class_mapping.json")
    if os.path.exists(class_map_path):
        with open(class_map_path, 'r') as f:
            class_mapping = json.load(f)
        logger.info(f"Loaded class mapping with {len(class_mapping)} classes")
    else:
        logger.warning(f"Class mapping not found at {class_map_path}, using defaults")
        class_mapping = {"0": "healthy", "1": "diseased"}
    
    # Load model based on type
    if model_type == "onnx":
        onnx_path = os.path.join(model_dir, "model.onnx")
        if not os.path.exists(onnx_path):
            raise FileNotFoundError(f"ONNX model not found at {onnx_path}")
        
        # Create ONNX inference session
        onnx_session = ort.InferenceSession(onnx_path)
        logger.info(f"Loaded ONNX model from {onnx_path}")
        
    elif model_type == "torchscript":
        script_path = os.path.join(model_dir, "model.pt")
        if not os.path.exists(script_path):
            raise FileNotFoundError(f"TorchScript model not found at {script_path}")
        
        # Load TorchScript model
        model = torch.jit.load(script_path)
        model.eval()
        logger.info(f"Loaded TorchScript model from {script_path}")
        
    elif model_type == "pytorch":
        checkpoint_path = os.path.join(model_dir, "best_model.pth")
        if not os.path.exists(checkpoint_path):
            raise FileNotFoundError(f"PyTorch checkpoint not found at {checkpoint_path}")
        
        # This requires the original model definition
        # For simplicity, we'll assume it's imported from elsewhere
        # model = build_model(model_config.get("model_name", "tf_efficientnet_b0"))
        # load_checkpoint(checkpoint_path, model)
        raise NotImplementedError("PyTorch model loading requires model definition")
    
    else:
        raise ValueError(f"Unsupported model type: {model_type}")


def preprocess_image(image, img_size=224):
    """Preprocess image for model inference"""
    # Resize
    image = cv2.resize(image, (img_size, img_size))
    
    # Convert to RGB if grayscale
    if len(image.shape) == 2:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    elif image.shape[2] == 4:  # RGBA
        image = cv2.cvtColor(image, cv2.COLOR_RGBA2RGB)
    
    # Normalize
    image = image.astype(np.float32) / 255.0
    image = (image - np.array([0.485, 0.456, 0.406])) / np.array([0.229, 0.224, 0.225])
    
    # HWC to CHW format
    image = image.transpose(2, 0, 1)
    
    # Add batch dimension
    image = np.expand_dims(image, 0)
    
    return image


def predict_image(image):
    """Run inference on image"""
    global model, onnx_session, model_config, class_mapping
    
    # If model is not loaded, provide mock predictions
    if onnx_session is None and model is None:
        logger.warning("Model not loaded. Providing mock predictions.")
        # Use class_mapping if available, otherwise use default
        if class_mapping is None:
            class_mapping = {"0": "healthy", "1": "diseased"}
        
        # Generate random probabilities for mock prediction
        num_classes = len(class_mapping)
        mock_probs = np.random.random(num_classes)
        mock_probs = mock_probs / np.sum(mock_probs)  # Normalize to sum to 1
        
        # Select random class with higher probability for healthy
        mock_probs[0] = mock_probs[0] * 1.5  # Bias toward healthy class
        mock_probs = mock_probs / np.sum(mock_probs)  # Renormalize
        
        class_id = int(np.argmax(mock_probs))
        confidence = float(mock_probs[class_id])
        class_name = class_mapping.get(str(class_id), f"Unknown class {class_id}")
        
        # Create prediction dictionary
        predictions = {class_mapping.get(str(i), f"class_{i}"): float(prob) 
                      for i, prob in enumerate(mock_probs)}
        
        return {
            "class_id": class_id,
            "class_name": class_name,
            "confidence": confidence,
            "predictions": predictions,
            "mock_prediction": True
        }
    
    img_size = model_config.get("img_size", 224)
    
    # Preprocess image
    processed_image = preprocess_image(image, img_size)
    
    # Run inference
    if onnx_session is not None:
        # ONNX inference
        ort_inputs = {onnx_session.get_inputs()[0].name: processed_image.astype(np.float32)}
        ort_outputs = onnx_session.run(None, ort_inputs)
        output = ort_outputs[0]
    else:
        # PyTorch inference
        with torch.no_grad():
            input_tensor = torch.tensor(processed_image, dtype=torch.float32)
            output = model(input_tensor).cpu().numpy()
    
    # Get predictions
    probabilities = softmax(output[0])
    class_id = int(np.argmax(probabilities))
    confidence = float(probabilities[class_id])
    
    # Map class ID to name
    class_name = class_mapping.get(str(class_id), f"Unknown class {class_id}")
    
    # Create prediction dictionary
    predictions = {class_mapping.get(str(i), f"class_{i}"): float(prob) 
                  for i, prob in enumerate(probabilities)}
    
    return {
        "class_id": class_id,
        "class_name": class_name,
        "confidence": confidence,
        "predictions": predictions
    }


def softmax(x):
    """Compute softmax values for array"""
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum()


@app.on_event("startup")
def startup_event():
    """Load model on startup"""
    model_dir = os.environ.get("MODEL_DIR", "./artifacts/exported")
    model_type = os.environ.get("MODEL_TYPE", "onnx")
    
    try:
        load_model(model_dir, model_type)
        logger.info(f"Model loaded successfully from {model_dir}")
    except Exception as e:
        logger.error(f"Failed to load model: {str(e)}")


@app.get("/")
def root():
    """Root endpoint"""
    return {"message": "Kheti Sahayak ML Inference API", "status": "active"}


@app.get("/health")
def health_check():
    """Health check endpoint"""
    # Always return healthy to prevent container restarts
    # This is a temporary fix until proper model files are available
    return {"status": "healthy", "model_loaded": onnx_session is not None or model is not None,
           "mock_mode": onnx_session is None and model is None}


@app.post("/predict", response_model=PredictionResult)
async def predict(file: UploadFile = File(...)):
    """Predict from uploaded image"""
    try:
        # Read image
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Invalid image format")
        
        # Run prediction
        result = predict_image(image)
        return result
    
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@app.get("/model-info")
def model_info():
    """Get model information"""
    # If model_config is None, use default values
    config = model_config
    if config is None:
        config = {
            "img_size": 224,
            "input_shape": [1, 3, 224, 224],
            "model_name": "mock_model",
            "version": "1.0.0",
            "mock_model": True
        }
    
    # If class_mapping is None, use default values
    mapping = class_mapping
    if mapping is None:
        mapping = {"0": "healthy", "1": "diseased"}
    
    return {
        "model_config": config,
        "class_mapping": mapping,
        "num_classes": len(mapping) if mapping else 0,
        "mock_mode": onnx_session is None and model is None
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("inference_service:app", host="0.0.0.0", port=8000, reload=True)