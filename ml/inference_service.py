import os
import io
import json
import logging
import time
import base64
from datetime import datetime
from typing import List, Dict, Any, Optional
from pathlib import Path

import numpy as np
import cv2
from fastapi import FastAPI, File, UploadFile, HTTPException, Query, Form
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from model_manager import ModelManager, get_model_manager
from preprocessing import validate_image_bytes, get_image_info
from disease_database import (
    CROP_DISEASES,
    SUPPORTED_CROPS,
    get_crop_diseases,
    get_disease_info,
    get_all_disease_names
)


logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


app = FastAPI(
    title="Kheti Sahayak ML Inference API",
    description="Production-ready API for crop disease diagnosis using deep learning. Supports 20+ crops with detailed disease information and treatment recommendations.",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


prediction_logs: List[Dict[str, Any]] = []
MAX_LOG_SIZE = 1000

model_manager: Optional[ModelManager] = None


class PredictionResponse(BaseModel):
    success: bool
    crop_type: str = ""
    disease_id: str = ""
    disease_name: str = ""
    disease_hindi_name: str = ""
    confidence: float = 0.0
    severity: str = ""
    description: str = ""
    hindi_description: str = ""
    symptoms: List[str] = []
    causes: List[str] = []
    treatments: List[Dict[str, Any]] = []
    prevention: List[str] = []
    top_predictions: List[Dict[str, Any]] = []
    similar_diseases: List[Dict[str, Any]] = []
    mock_prediction: bool = False
    inference_time_ms: float = 0.0
    error: str = ""


class BatchPredictionItem(BaseModel):
    crop_type: str
    image_base64: str


class BatchPredictionRequest(BaseModel):
    predictions: List[BatchPredictionItem]


class CropInfo(BaseModel):
    crop_type: str
    name: str
    hindi_name: str
    model_loaded: bool
    num_diseases: int


class DiseaseInfo(BaseModel):
    disease_id: str
    name: str
    hindi_name: str
    severity: str
    description: str


class HealthResponse(BaseModel):
    status: str
    models_initialized: int
    models_loaded: int
    mock_mode_count: int
    supported_crops: int
    uptime_seconds: float
    version: str


START_TIME = time.time()


def log_prediction(
    crop_type: str,
    disease_id: str,
    confidence: float,
    mock_mode: bool,
    inference_time: float,
    success: bool
):
    global prediction_logs
    
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "crop_type": crop_type,
        "disease_id": disease_id,
        "confidence": confidence,
        "mock_mode": mock_mode,
        "inference_time_ms": inference_time,
        "success": success
    }
    
    prediction_logs.append(log_entry)
    
    if len(prediction_logs) > MAX_LOG_SIZE:
        prediction_logs = prediction_logs[-MAX_LOG_SIZE:]


@app.on_event("startup")
def startup_event():
    global model_manager
    
    models_dir = os.environ.get("MODELS_DIR", "./models")
    model_manager = get_model_manager(models_dir)
    
    logger.info(f"ML Inference Service started with {len(model_manager.supported_crops)} supported crops")


@app.get("/", tags=["General"])
def root():
    return {
        "message": "Kheti Sahayak ML Inference API",
        "version": "2.0.0",
        "status": "active",
        "supported_crops": len(SUPPORTED_CROPS),
        "docs_url": "/docs"
    }


@app.get("/health", response_model=HealthResponse, tags=["General"])
def health_check():
    health_status = model_manager.get_health_status() if model_manager else {}
    
    return {
        "status": "healthy",
        "models_initialized": health_status.get("models_initialized", 0),
        "models_loaded": health_status.get("models_loaded", 0),
        "mock_mode_count": health_status.get("mock_mode_count", 0),
        "supported_crops": health_status.get("supported_crops", 0),
        "uptime_seconds": round(time.time() - START_TIME, 2),
        "version": "2.0.0"
    }


@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
async def predict(
    file: UploadFile = File(...),
    crop_type: str = Form(default="rice"),
    use_tta: bool = Form(default=False),
    calibrate: bool = Form(default=True)
):
    start_time = time.time()
    
    try:
        contents = await file.read()
        
        is_valid, validation_msg = validate_image_bytes(contents)
        if not is_valid:
            raise HTTPException(status_code=400, detail=validation_msg)
        
        crop_type = crop_type.lower()
        if crop_type not in SUPPORTED_CROPS:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported crop type: {crop_type}. Supported crops: {list(SUPPORTED_CROPS.keys())}"
            )
        
        result = model_manager.predict(
            crop_type=crop_type,
            image_bytes=contents,
            use_tta=use_tta,
            calibrate=calibrate
        )
        
        log_prediction(
            crop_type=crop_type,
            disease_id=result.get("disease_id", "unknown"),
            confidence=result.get("confidence", 0.0),
            mock_mode=result.get("mock_prediction", False),
            inference_time=result.get("inference_time_ms", 0.0),
            success=result.get("success", False)
        )
        
        return result
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@app.post("/predict/base64", response_model=PredictionResponse, tags=["Prediction"])
async def predict_base64(
    image_base64: str = Form(...),
    crop_type: str = Form(default="rice"),
    use_tta: bool = Form(default=False),
    calibrate: bool = Form(default=True)
):
    try:
        image_data = image_base64
        if "," in image_base64:
            image_data = image_base64.split(",")[1]
        
        try:
            contents = base64.b64decode(image_data)
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid base64 image data")
        
        is_valid, validation_msg = validate_image_bytes(contents)
        if not is_valid:
            raise HTTPException(status_code=400, detail=validation_msg)
        
        crop_type = crop_type.lower()
        if crop_type not in SUPPORTED_CROPS:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported crop type: {crop_type}"
            )
        
        result = model_manager.predict(
            crop_type=crop_type,
            image_bytes=contents,
            use_tta=use_tta,
            calibrate=calibrate
        )
        
        log_prediction(
            crop_type=crop_type,
            disease_id=result.get("disease_id", "unknown"),
            confidence=result.get("confidence", 0.0),
            mock_mode=result.get("mock_prediction", False),
            inference_time=result.get("inference_time_ms", 0.0),
            success=result.get("success", False)
        )
        
        return result
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@app.post("/batch-predict", tags=["Prediction"])
async def batch_predict(request: BatchPredictionRequest):
    results = []
    
    for item in request.predictions:
        try:
            image_data = item.image_base64
            if "," in image_data:
                image_data = image_data.split(",")[1]
            
            contents = base64.b64decode(image_data)
            
            result = model_manager.predict(
                crop_type=item.crop_type.lower(),
                image_bytes=contents,
                use_tta=False,
                calibrate=True
            )
            results.append(result)
            
        except Exception as e:
            results.append({
                "success": False,
                "error": str(e),
                "crop_type": item.crop_type
            })
    
    return {
        "success": True,
        "total": len(request.predictions),
        "successful": sum(1 for r in results if r.get("success", False)),
        "results": results
    }


@app.get("/crops", response_model=List[CropInfo], tags=["Crops & Diseases"])
def get_supported_crops():
    return model_manager.get_supported_crops()


@app.get("/crops/{crop_type}", tags=["Crops & Diseases"])
def get_crop_info(crop_type: str):
    crop_type = crop_type.lower()
    
    if crop_type not in SUPPORTED_CROPS:
        raise HTTPException(
            status_code=404,
            detail=f"Crop type not found: {crop_type}"
        )
    
    crop_info = SUPPORTED_CROPS[crop_type]
    diseases = get_crop_diseases(crop_type)
    model_info = model_manager.get_model_info(crop_type)
    
    return {
        "crop_type": crop_type,
        "name": crop_info["name"],
        "hindi_name": crop_info["hindi_name"],
        "total_diseases": len(diseases),
        "diseases": [
            {
                "disease_id": disease_id,
                "name": info.get("name"),
                "hindi_name": info.get("hindi_name"),
                "severity": info.get("severity")
            }
            for disease_id, info in diseases.items()
        ],
        "model_info": model_info
    }


@app.get("/diseases/{crop_type}", tags=["Crops & Diseases"])
def get_diseases_for_crop(crop_type: str):
    crop_type = crop_type.lower()
    
    if crop_type not in CROP_DISEASES:
        raise HTTPException(
            status_code=404,
            detail=f"Crop type not found: {crop_type}"
        )
    
    diseases = get_crop_diseases(crop_type)
    
    return {
        "crop_type": crop_type,
        "total_diseases": len(diseases),
        "diseases": [
            {
                "disease_id": disease_id,
                "name": info.get("name"),
                "hindi_name": info.get("hindi_name"),
                "severity": info.get("severity"),
                "description": info.get("description")
            }
            for disease_id, info in diseases.items()
        ]
    }


@app.get("/diseases/{crop_type}/{disease_id}", tags=["Crops & Diseases"])
def get_disease_details(crop_type: str, disease_id: str):
    crop_type = crop_type.lower()
    disease_id = disease_id.lower()
    
    if crop_type not in CROP_DISEASES:
        raise HTTPException(
            status_code=404,
            detail=f"Crop type not found: {crop_type}"
        )
    
    disease_info = get_disease_info(crop_type, disease_id)
    
    if not disease_info:
        raise HTTPException(
            status_code=404,
            detail=f"Disease not found: {disease_id} for crop: {crop_type}"
        )
    
    return {
        "crop_type": crop_type,
        "disease_id": disease_id,
        **disease_info
    }


@app.get("/model-info", tags=["Model"])
def get_model_info(crop_type: Optional[str] = Query(None)):
    if crop_type:
        return model_manager.get_model_info(crop_type.lower())
    return model_manager.get_model_info()


@app.get("/model-info/{crop_type}", tags=["Model"])
def get_crop_model_info(crop_type: str):
    crop_type = crop_type.lower()
    
    if crop_type not in SUPPORTED_CROPS:
        raise HTTPException(
            status_code=404,
            detail=f"Crop type not found: {crop_type}"
        )
    
    return model_manager.get_model_info(crop_type)


@app.get("/analytics/predictions", tags=["Analytics"])
def get_prediction_analytics(
    limit: int = Query(default=100, ge=1, le=1000),
    crop_type: Optional[str] = Query(None)
):
    logs = prediction_logs[-limit:]
    
    if crop_type:
        logs = [log for log in logs if log.get("crop_type") == crop_type.lower()]
    
    if not logs:
        return {
            "total_predictions": 0,
            "average_confidence": 0,
            "average_inference_time_ms": 0,
            "mock_prediction_ratio": 0,
            "success_rate": 0,
            "crop_distribution": {},
            "disease_distribution": {},
            "recent_predictions": []
        }
    
    crop_counts = {}
    disease_counts = {}
    total_confidence = 0
    total_inference_time = 0
    mock_count = 0
    success_count = 0
    
    for log in logs:
        crop = log.get("crop_type", "unknown")
        crop_counts[crop] = crop_counts.get(crop, 0) + 1
        
        disease = log.get("disease_id", "unknown")
        disease_counts[disease] = disease_counts.get(disease, 0) + 1
        
        total_confidence += log.get("confidence", 0)
        total_inference_time += log.get("inference_time_ms", 0)
        
        if log.get("mock_mode"):
            mock_count += 1
        if log.get("success"):
            success_count += 1
    
    return {
        "total_predictions": len(logs),
        "average_confidence": round(total_confidence / len(logs), 4),
        "average_inference_time_ms": round(total_inference_time / len(logs), 2),
        "mock_prediction_ratio": round(mock_count / len(logs), 4),
        "success_rate": round(success_count / len(logs), 4),
        "crop_distribution": crop_counts,
        "disease_distribution": disease_counts,
        "recent_predictions": logs[-10:]
    }


@app.post("/image/validate", tags=["Utilities"])
async def validate_image(file: UploadFile = File(...)):
    contents = await file.read()
    
    is_valid, validation_msg = validate_image_bytes(contents)
    image_info = get_image_info(contents)
    
    return {
        "valid": is_valid,
        "message": validation_msg,
        "info": image_info
    }


@app.get("/search/diseases", tags=["Search"])
def search_diseases(
    query: str = Query(..., min_length=2),
    crop_type: Optional[str] = Query(None)
):
    query_lower = query.lower()
    results = []
    
    crops_to_search = [crop_type.lower()] if crop_type else list(CROP_DISEASES.keys())
    
    for crop in crops_to_search:
        if crop not in CROP_DISEASES:
            continue
        
        for disease_id, disease_info in CROP_DISEASES[crop].items():
            name = disease_info.get("name", "").lower()
            hindi_name = disease_info.get("hindi_name", "")
            description = disease_info.get("description", "").lower()
            symptoms = " ".join(disease_info.get("symptoms", [])).lower()
            
            if (query_lower in name or 
                query_lower in disease_id or 
                query_lower in description or 
                query_lower in symptoms or
                query in hindi_name):
                
                results.append({
                    "crop_type": crop,
                    "disease_id": disease_id,
                    "name": disease_info.get("name"),
                    "hindi_name": disease_info.get("hindi_name"),
                    "severity": disease_info.get("severity"),
                    "match_context": "name" if query_lower in name else "symptoms/description"
                })
    
    return {
        "query": query,
        "crop_filter": crop_type,
        "total_results": len(results),
        "results": results[:50]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("inference_service:app", host="0.0.0.0", port=8000, reload=True)
