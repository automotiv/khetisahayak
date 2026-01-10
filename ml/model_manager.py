import os
import json
import logging
import time
from typing import Dict, List, Optional, Any, Tuple
from pathlib import Path
import random

import numpy as np

try:
    import onnxruntime as ort
    ONNX_AVAILABLE = True
except ImportError:
    ONNX_AVAILABLE = False

try:
    import torch
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False

from preprocessing import preprocess_image, preprocess_batch_for_tta
from disease_database import (
    CROP_DISEASES,
    SUPPORTED_CROPS,
    get_disease_info,
    get_disease_class_labels,
    get_similar_diseases
)


logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def softmax(x: np.ndarray) -> np.ndarray:
    e_x = np.exp(x - np.max(x, axis=-1, keepdims=True))
    return e_x / e_x.sum(axis=-1, keepdims=True)


def calibrate_confidence(raw_confidence: float, temperature: float = 1.5) -> float:
    logit = np.log(raw_confidence / (1 - raw_confidence + 1e-10))
    calibrated_logit = logit / temperature
    calibrated_prob = 1 / (1 + np.exp(-calibrated_logit))
    return float(np.clip(calibrated_prob, 0.0, 0.99))


class CropModel:
    def __init__(
        self,
        crop_type: str,
        model_path: Optional[str] = None,
        class_labels: Optional[Dict[str, str]] = None,
        model_type: str = "onnx",
        img_size: int = 224
    ):
        self.crop_type = crop_type.lower()
        self.model_path = model_path
        self.model_type = model_type
        self.img_size = img_size
        self.model = None
        self.onnx_session = None
        self.is_loaded = False
        self.mock_mode = True
        
        if class_labels:
            self.class_labels = class_labels
        else:
            self.class_labels = get_disease_class_labels(self.crop_type)
        
        self.num_classes = len(self.class_labels)
        
        if model_path and os.path.exists(model_path):
            self._load_model()
    
    def _load_model(self) -> bool:
        try:
            if self.model_type == "onnx" and ONNX_AVAILABLE:
                self.onnx_session = ort.InferenceSession(self.model_path)
                self.is_loaded = True
                self.mock_mode = False
                logger.info(f"Loaded ONNX model for {self.crop_type} from {self.model_path}")
                return True
            
            elif self.model_type == "torchscript" and TORCH_AVAILABLE:
                self.model = torch.jit.load(self.model_path)
                self.model.eval()
                self.is_loaded = True
                self.mock_mode = False
                logger.info(f"Loaded TorchScript model for {self.crop_type} from {self.model_path}")
                return True
            
            else:
                logger.warning(f"Model type {self.model_type} not supported or dependencies not available")
                return False
                
        except Exception as e:
            logger.error(f"Failed to load model for {self.crop_type}: {str(e)}")
            return False
    
    def _run_inference(self, preprocessed_image: np.ndarray) -> np.ndarray:
        if self.onnx_session is not None:
            input_name = self.onnx_session.get_inputs()[0].name
            outputs = self.onnx_session.run(None, {input_name: preprocessed_image})
            return outputs[0]
        
        elif self.model is not None and TORCH_AVAILABLE:
            with torch.no_grad():
                input_tensor = torch.tensor(preprocessed_image, dtype=torch.float32)
                outputs = self.model(input_tensor)
                return outputs.cpu().numpy()
        
        return self._mock_inference(preprocessed_image)
    
    def _mock_inference(self, preprocessed_image: np.ndarray) -> np.ndarray:
        batch_size = preprocessed_image.shape[0]
        
        random.seed(int(time.time() * 1000) % 2**32)
        
        logits = np.zeros((batch_size, self.num_classes))
        
        for i in range(batch_size):
            primary_class = random.randint(0, self.num_classes - 1)
            
            base_logits = np.random.normal(0, 0.5, self.num_classes)
            
            base_logits[primary_class] += random.uniform(1.5, 3.0)
            
            if random.random() < 0.3:
                secondary_class = random.randint(0, self.num_classes - 1)
                if secondary_class != primary_class:
                    base_logits[secondary_class] += random.uniform(0.5, 1.0)
            
            logits[i] = base_logits
        
        return logits
    
    def predict(
        self,
        image_bytes: bytes,
        use_tta: bool = False,
        num_tta: int = 5,
        calibrate: bool = True,
        temperature: float = 1.5
    ) -> Dict[str, Any]:
        start_time = time.time()
        
        if use_tta:
            preprocessed = preprocess_batch_for_tta(
                image_bytes,
                target_size=(self.img_size, self.img_size),
                num_augmentations=num_tta
            )
        else:
            preprocessed = preprocess_image(
                image_bytes,
                target_size=(self.img_size, self.img_size)
            )
        
        if preprocessed is None:
            return {
                "success": False,
                "error": "Failed to preprocess image"
            }
        
        logits = self._run_inference(preprocessed)
        
        if use_tta:
            probabilities = softmax(logits)
            probabilities = np.mean(probabilities, axis=0)
        else:
            probabilities = softmax(logits[0])
        
        class_id = int(np.argmax(probabilities))
        confidence = float(probabilities[class_id])
        
        if calibrate:
            confidence = calibrate_confidence(confidence, temperature)
        
        disease_id = self.class_labels.get(str(class_id), f"unknown_{class_id}")
        disease_info = get_disease_info(self.crop_type, disease_id)
        
        all_predictions = {
            self.class_labels.get(str(i), f"class_{i}"): float(prob)
            for i, prob in enumerate(probabilities)
        }
        
        top_k = min(3, len(probabilities))
        top_indices = np.argsort(probabilities)[-top_k:][::-1]
        top_predictions = [
            {
                "disease_id": self.class_labels.get(str(idx), f"class_{idx}"),
                "confidence": float(probabilities[idx])
            }
            for idx in top_indices
        ]
        
        inference_time = (time.time() - start_time) * 1000
        
        return {
            "success": True,
            "crop_type": self.crop_type,
            "disease_id": disease_id,
            "disease_name": disease_info.get("name", disease_id),
            "disease_hindi_name": disease_info.get("hindi_name", ""),
            "confidence": confidence,
            "severity": disease_info.get("severity", "unknown"),
            "description": disease_info.get("description", ""),
            "hindi_description": disease_info.get("hindi_description", ""),
            "symptoms": disease_info.get("symptoms", []),
            "causes": disease_info.get("causes", []),
            "treatments": disease_info.get("treatments", []),
            "prevention": disease_info.get("prevention", []),
            "top_predictions": top_predictions,
            "all_predictions": all_predictions,
            "similar_diseases": get_similar_diseases(self.crop_type, disease_id, limit=3),
            "mock_prediction": self.mock_mode,
            "inference_time_ms": round(inference_time, 2),
            "model_info": {
                "crop_type": self.crop_type,
                "model_loaded": self.is_loaded,
                "model_type": self.model_type,
                "num_classes": self.num_classes
            }
        }


class ModelManager:
    def __init__(self, models_dir: str = "./models"):
        self.models_dir = Path(models_dir)
        self.models: Dict[str, CropModel] = {}
        self.default_model: Optional[CropModel] = None
        self.supported_crops = list(SUPPORTED_CROPS.keys())
        
        self._initialize_models()
    
    def _initialize_models(self):
        logger.info(f"Initializing ModelManager with models directory: {self.models_dir}")
        
        if self.models_dir.exists():
            for crop_dir in self.models_dir.iterdir():
                if crop_dir.is_dir() and crop_dir.name in self.supported_crops:
                    self._load_crop_model(crop_dir.name, crop_dir)
        
        for crop_type in self.supported_crops:
            if crop_type not in self.models:
                self.models[crop_type] = CropModel(crop_type)
                logger.info(f"Initialized mock model for {crop_type}")
        
        if "rice" in self.models:
            self.default_model = self.models["rice"]
        elif self.models:
            self.default_model = list(self.models.values())[0]
        
        logger.info(f"ModelManager initialized with {len(self.models)} crop models")
    
    def _load_crop_model(self, crop_type: str, model_dir: Path):
        metadata_path = model_dir / "model_metadata.json"
        class_mapping_path = model_dir / "class_mapping.json"
        
        model_config = {}
        if metadata_path.exists():
            with open(metadata_path, 'r') as f:
                model_config = json.load(f)
        
        class_labels = None
        if class_mapping_path.exists():
            with open(class_mapping_path, 'r') as f:
                class_labels = json.load(f)
        
        model_type = model_config.get("framework", "onnx")
        img_size = model_config.get("img_size", 224)
        
        model_file = None
        if model_type == "onnx":
            model_file = model_dir / "model.onnx"
        elif model_type == "torchscript":
            model_file = model_dir / "model.pt"
        
        model_path = str(model_file) if model_file and model_file.exists() else None
        
        self.models[crop_type] = CropModel(
            crop_type=crop_type,
            model_path=model_path,
            class_labels=class_labels,
            model_type=model_type,
            img_size=img_size
        )
        
        if model_path:
            logger.info(f"Loaded model for {crop_type} from {model_path}")
        else:
            logger.info(f"Using mock model for {crop_type} (no model file found)")
    
    def load_model(self, crop_type: str, model_path: str, model_type: str = "onnx") -> bool:
        crop_type = crop_type.lower()
        
        if crop_type not in self.supported_crops:
            logger.error(f"Unsupported crop type: {crop_type}")
            return False
        
        if not os.path.exists(model_path):
            logger.error(f"Model file not found: {model_path}")
            return False
        
        self.models[crop_type] = CropModel(
            crop_type=crop_type,
            model_path=model_path,
            model_type=model_type
        )
        
        return self.models[crop_type].is_loaded
    
    def get_model(self, crop_type: str) -> Optional[CropModel]:
        crop_type = crop_type.lower()
        return self.models.get(crop_type, self.default_model)
    
    def predict(
        self,
        crop_type: str,
        image_bytes: bytes,
        use_tta: bool = False,
        calibrate: bool = True
    ) -> Dict[str, Any]:
        model = self.get_model(crop_type)
        
        if model is None:
            return {
                "success": False,
                "error": f"No model available for crop type: {crop_type}"
            }
        
        return model.predict(image_bytes, use_tta=use_tta, calibrate=calibrate)
    
    def batch_predict(
        self,
        predictions_request: List[Tuple[str, bytes]]
    ) -> List[Dict[str, Any]]:
        results = []
        for crop_type, image_bytes in predictions_request:
            result = self.predict(crop_type, image_bytes)
            results.append(result)
        return results
    
    def get_supported_crops(self) -> List[Dict[str, str]]:
        return [
            {
                "crop_type": crop_type,
                "name": info["name"],
                "hindi_name": info["hindi_name"],
                "model_loaded": self.models.get(crop_type, CropModel(crop_type)).is_loaded,
                "num_diseases": len(CROP_DISEASES.get(crop_type, {}))
            }
            for crop_type, info in SUPPORTED_CROPS.items()
        ]
    
    def get_model_info(self, crop_type: Optional[str] = None) -> Dict[str, Any]:
        if crop_type:
            model = self.get_model(crop_type)
            if model:
                return {
                    "crop_type": model.crop_type,
                    "model_loaded": model.is_loaded,
                    "mock_mode": model.mock_mode,
                    "model_type": model.model_type,
                    "num_classes": model.num_classes,
                    "class_labels": model.class_labels,
                    "img_size": model.img_size
                }
            return {"error": f"Model not found for crop type: {crop_type}"}
        
        return {
            "total_models": len(self.models),
            "loaded_models": sum(1 for m in self.models.values() if m.is_loaded),
            "mock_models": sum(1 for m in self.models.values() if m.mock_mode),
            "supported_crops": self.supported_crops,
            "models": {
                crop: {
                    "loaded": model.is_loaded,
                    "mock_mode": model.mock_mode,
                    "num_classes": model.num_classes
                }
                for crop, model in self.models.items()
            }
        }
    
    def get_health_status(self) -> Dict[str, Any]:
        return {
            "status": "healthy",
            "models_initialized": len(self.models),
            "models_loaded": sum(1 for m in self.models.values() if m.is_loaded),
            "mock_mode_count": sum(1 for m in self.models.values() if m.mock_mode),
            "supported_crops": len(self.supported_crops),
            "onnx_available": ONNX_AVAILABLE,
            "torch_available": TORCH_AVAILABLE
        }


_model_manager: Optional[ModelManager] = None


def get_model_manager(models_dir: str = "./models") -> ModelManager:
    global _model_manager
    if _model_manager is None:
        _model_manager = ModelManager(models_dir)
    return _model_manager
