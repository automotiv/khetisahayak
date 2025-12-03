"""
Kheti Sahayak ML Inference Service (Placeholder)

This is a mock ML service that provides disease detection responses
until the actual trained ML model is deployed.

Production: Replace this with actual TensorFlow/PyTorch model inference.
"""

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import uvicorn
import random
import io
from PIL import Image

app = FastAPI(
    title="Kheti Sahayak ML Inference API",
    description="AI-powered crop disease detection service",
    version="1.0.0 (Mock)"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class DiseaseDetectionResponse(BaseModel):
    disease: str
    confidence: float
    severity: str
    symptoms: List[str]
    treatment_steps: List[str]
    recommendations: str
    model_version: str = "mock-v1.0"

# Mock disease database
DISEASE_DATABASE = {
    'tomato': {
        'yellow_leaves': {
            'disease': 'Early Blight',
            'scientific_name': 'Alternaria solani',
            'confidence_range': (0.82, 0.92),
            'severity': 'moderate',
            'symptoms': [
                'Yellow leaves with brown spots',
                'Circular lesions on leaves',
                'Target-like patterns on affected areas',
                'Stem cankers may appear'
            ],
            'treatment_steps': [
                'Remove and destroy infected plant parts immediately',
                'Apply copper-based fungicide every 7-10 days',
                'Improve plant spacing for better air circulation',
                'Avoid overhead irrigation to reduce leaf wetness',
                'Mulch around plants to prevent soil splash'
            ],
            'recommendations': 'Apply fungicide containing chlorothalonil or copper compounds. Improve air circulation and avoid overhead watering. Remove infected leaves immediately.'
        },
        'brown_spots': {
            'disease': 'Septoria Leaf Spot',
            'scientific_name': 'Septoria lycopersici',
            'confidence_range': (0.75, 0.88),
            'severity': 'low',
            'symptoms': [
                'Small brown spots with gray centers',
                'Yellow halos around spots',
                'Spots appear on lower leaves first',
                'Leaves may turn yellow and drop'
            ],
            'treatment_steps': [
                'Remove infected leaves from bottom of plant',
                'Apply fungicide with azoxystrobin',
                'Improve air circulation between plants',
                'Water at base of plants, not overhead',
                'Rotate crops next season'
            ],
            'recommendations': 'Apply fungicide with active ingredients like azoxystrobin. Remove infected leaves and improve airflow.'
        },
        'wilting': {
            'disease': 'Bacterial Wilt',
            'scientific_name': 'Ralstonia solanacearum',
            'confidence_range': (0.88, 0.96),
            'severity': 'high',
            'symptoms': [
                'Sudden wilting of entire plant',
                'Brown discoloration of vascular tissue',
                'No recovery after watering',
                'Plant death within days'
            ],
            'treatment_steps': [
                'Remove and destroy infected plants immediately',
                'Disinfect all gardening tools with bleach solution',
                'Do not replant in same location for 3-4 years',
                'Rotate to non-susceptible crops',
                'Plant resistant varieties in future'
            ],
            'recommendations': 'Remove infected plants immediately. Disinfect tools. Plant resistant varieties next season. No chemical treatment available.'
        }
    },
    'potato': {
        'brown_spots': {
            'disease': 'Late Blight',
            'scientific_name': 'Phytophthora infestans',
            'confidence_range': (0.90, 0.98),
            'severity': 'high',
            'symptoms': [
                'Dark brown spots on leaves',
                'White fungal growth on underside',
                'Rapid spread in wet conditions',
                'Tuber rot if untreated'
            ],
            'treatment_steps': [
                'Apply copper fungicide immediately',
                'Remove and destroy all infected plants',
                'Improve field drainage',
                'Harvest tubers as soon as possible',
                'Plant resistant varieties next season'
            ],
            'recommendations': 'Remove infected plants immediately. Apply copper-based fungicide. Ensure proper drainage. This is a severe disease.'
        },
        'yellow_leaves': {
            'disease': 'Early Blight',
            'scientific_name': 'Alternaria solani',
            'confidence_range': (0.84, 0.91),
            'severity': 'moderate',
            'symptoms': [
                'Target-like lesions on older leaves',
                'Yellowing leaves',
                'Stem lesions',
                'Reduced yield'
            ],
            'treatment_steps': [
                'Remove infected leaves',
                'Apply fungicide every 7-10 days',
                'Improve plant spacing',
                'Avoid overhead irrigation',
                'Hill soil around plants'
            ],
            'recommendations': 'Apply fungicide and improve air circulation. Remove infected leaves promptly.'
        }
    },
    'corn': {
        'rust_colored': {
            'disease': 'Common Rust',
            'scientific_name': 'Puccinia sorghi',
            'confidence_range': (0.78, 0.89),
            'severity': 'moderate',
            'symptoms': [
                'Rust-colored pustules on leaves',
                'Yellow halos around lesions',
                'Pustules on both leaf surfaces',
                'Reduced photosynthesis'
            ],
            'treatment_steps': [
                'Apply fungicide at first sign',
                'Plant resistant varieties next season',
                'Remove crop debris after harvest',
                'Monitor weather conditions',
                'Scout fields regularly'
            ],
            'recommendations': 'Apply fungicide with active ingredients like azoxystrobin. Plant resistant varieties next season.'
        },
        'gray_spots': {
            'disease': 'Gray Leaf Spot',
            'scientific_name': 'Cercospora zeae-maydis',
            'confidence_range': (0.72, 0.85),
            'severity': 'moderate',
            'symptoms': [
                'Gray to tan rectangular lesions',
                'Lesions with parallel edges',
                'Yellowing between lesions',
                'Premature leaf death'
            ],
            'treatment_steps': [
                'Apply fungicide when lesions appear',
                'Improve field drainage',
                'Plant resistant hybrids',
                'Rotate to non-host crops',
                'Manage crop residue'
            ],
            'recommendations': 'Apply fungicide and improve air circulation. Plant resistant varieties. Rotate crops.'
        }
    },
    'wheat': {
        'white_powder': {
            'disease': 'Powdery Mildew',
            'scientific_name': 'Blumeria graminis',
            'confidence_range': (0.86, 0.94),
            'severity': 'moderate',
            'symptoms': [
                'White powdery growth on leaves',
                'Yellowing of infected leaves',
                'Stunted growth',
                'Reduced grain yield'
            ],
            'treatment_steps': [
                'Apply sulfur-based fungicide',
                'Improve air circulation',
                'Avoid excessive nitrogen fertilization',
                'Plant resistant varieties',
                'Remove heavily infected plants'
            ],
            'recommendations': 'Apply sulfur-based fungicide. Increase plant spacing for better air circulation. Avoid excess nitrogen.'
        },
        'brown_spots': {
            'disease': 'Septoria Leaf Blotch',
            'scientific_name': 'Septoria tritici',
            'confidence_range': (0.81, 0.90),
            'severity': 'moderate',
            'symptoms': [
                'Brown lesions with yellow halos',
                'Small black dots in lesions',
                'Lesions on lower leaves first',
                'Reduced grain filling'
            ],
            'treatment_steps': [
                'Apply fungicide at flag leaf stage',
                'Remove crop debris after harvest',
                'Improve field drainage',
                'Plant resistant varieties',
                'Use crop rotation'
            ],
            'recommendations': 'Apply fungicide and remove infected plant debris. Improve field drainage. Use resistant varieties.'
        }
    }
}

def detect_keywords(description: str) -> str:
    """Detect keywords in issue description to match disease."""
    description_lower = description.lower()

    keywords_map = {
        'yellow': 'yellow_leaves',
        'yellowing': 'yellow_leaves',
        'yellow leaves': 'yellow_leaves',
        'brown': 'brown_spots',
        'brown spots': 'brown_spots',
        'spots': 'brown_spots',
        'rust': 'rust_colored',
        'rust colored': 'rust_colored',
        'wilt': 'wilting',
        'wilting': 'wilting',
        'white powder': 'white_powder',
        'powdery': 'white_powder',
        'gray': 'gray_spots',
        'grey': 'gray_spots'
    }

    for keyword, symptom_key in keywords_map.items():
        if keyword in description_lower:
            return symptom_key

    return 'yellow_leaves'  # default

@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "service": "Kheti Sahayak ML Inference API",
        "status": "healthy",
        "version": "1.0.0 (Mock)",
        "model_type": "placeholder",
        "note": "Replace with actual ML model in production"
    }

@app.get("/health")
async def health_check():
    """Detailed health check."""
    return {
        "status": "healthy",
        "model_loaded": True,
        "model_version": "mock-v1.0",
        "supported_crops": list(DISEASE_DATABASE.keys())
    }

@app.post("/predict", response_model=DiseaseDetectionResponse)
async def predict_disease(
    image: UploadFile = File(...),
    crop_type: str = Form(...),
    issue_description: str = Form(...)
):
    """
    Predict disease from plant image.

    Args:
        image: Plant image file
        crop_type: Type of crop (tomato, potato, corn, wheat, etc.)
        issue_description: Description of the issue

    Returns:
        Disease detection response with recommendations
    """

    # Validate image
    if not image.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")

    # Read and validate image
    try:
        image_data = await image.read()
        img = Image.open(io.BytesIO(image_data))

        # Basic image validation
        if img.width < 100 or img.height < 100:
            raise HTTPException(status_code=400, detail="Image too small. Minimum 100x100 pixels required")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image file: {str(e)}")

    # Normalize crop type
    crop_type_lower = crop_type.lower()

    # Get disease database for crop
    if crop_type_lower not in DISEASE_DATABASE:
        # Return unknown disease for unsupported crops
        return DiseaseDetectionResponse(
            disease='Unknown Disease',
            confidence=0.65,
            severity='unknown',
            symptoms=[
                'Various symptoms observed',
                'Requires expert examination'
            ],
            treatment_steps=[
                'Consult with agricultural expert',
                'Take detailed photos of symptoms',
                'Monitor plant development',
                'Consider soil testing',
                'Check for pest infestation'
            ],
            recommendations='Unable to identify specific disease. Please consult with an agricultural expert for proper diagnosis. Consider taking soil samples for testing.'
        )

    # Detect disease based on description
    symptom_key = detect_keywords(issue_description)

    # Get disease info
    crop_diseases = DISEASE_DATABASE[crop_type_lower]

    if symptom_key not in crop_diseases:
        # Use first available disease as fallback
        symptom_key = list(crop_diseases.keys())[0]

    disease_info = crop_diseases[symptom_key]

    # Generate confidence score (with some randomness for realism)
    min_conf, max_conf = disease_info['confidence_range']
    confidence = round(random.uniform(min_conf, max_conf), 2)

    return DiseaseDetectionResponse(
        disease=disease_info['disease'],
        confidence=confidence,
        severity=disease_info['severity'],
        symptoms=disease_info['symptoms'],
        treatment_steps=disease_info['treatment_steps'],
        recommendations=disease_info['recommendations']
    )

@app.get("/supported-crops")
async def get_supported_crops():
    """Get list of supported crop types."""
    return {
        "crops": list(DISEASE_DATABASE.keys()),
        "total": len(DISEASE_DATABASE)
    }

@app.get("/diseases/{crop_type}")
async def get_crop_diseases(crop_type: str):
    """Get all diseases for a specific crop."""
    crop_type_lower = crop_type.lower()

    if crop_type_lower not in DISEASE_DATABASE:
        raise HTTPException(status_code=404, detail=f"Crop type '{crop_type}' not supported")

    diseases = []
    for symptom, info in DISEASE_DATABASE[crop_type_lower].items():
        diseases.append({
            "disease_name": info['disease'],
            "scientific_name": info.get('scientific_name', 'N/A'),
            "severity": info['severity'],
            "symptoms": info['symptoms']
        })

    return {
        "crop_type": crop_type,
        "diseases": diseases,
        "total": len(diseases)
    }

class CropRecommendationRequest(BaseModel):
    nitrogen: float
    phosphorus: float
    potassium: float
    ph: float
    rainfall: float
    temperature: float
    humidity: float
    soil_type: str
    season: str

class CropRecommendationResponse(BaseModel):
    recommended_crops: List[dict]
    model_version: str = "mock-crop-v1.0"

# Mock Crop Database (Simulating 100+ crops knowledge)
CROP_DATABASE = [
    {"name": "Rice", "nitrogen": 80, "phosphorus": 40, "potassium": 40, "ph": 6.5, "rainfall": 200, "soil": "clay"},
    {"name": "Wheat", "nitrogen": 60, "phosphorus": 30, "potassium": 30, "ph": 6.5, "rainfall": 100, "soil": "loam"},
    {"name": "Maize", "nitrogen": 70, "phosphorus": 40, "potassium": 40, "ph": 6.5, "rainfall": 100, "soil": "loam"},
    {"name": "Cotton", "nitrogen": 90, "phosphorus": 50, "potassium": 50, "ph": 6.5, "rainfall": 100, "soil": "black"},
    {"name": "Sugarcane", "nitrogen": 100, "phosphorus": 60, "potassium": 60, "ph": 7.0, "rainfall": 200, "soil": "loam"},
    {"name": "Potato", "nitrogen": 50, "phosphorus": 60, "potassium": 100, "ph": 5.5, "rainfall": 80, "soil": "sandy"},
    {"name": "Tomato", "nitrogen": 50, "phosphorus": 50, "potassium": 50, "ph": 6.0, "rainfall": 80, "soil": "loam"},
    {"name": "Onion", "nitrogen": 60, "phosphorus": 50, "potassium": 50, "ph": 6.5, "rainfall": 60, "soil": "loam"},
    {"name": "Soybean", "nitrogen": 20, "phosphorus": 60, "potassium": 40, "ph": 6.5, "rainfall": 100, "soil": "loam"},
    {"name": "Groundnut", "nitrogen": 20, "phosphorus": 50, "potassium": 40, "ph": 6.0, "rainfall": 80, "soil": "sandy"},
    {"name": "Chickpea", "nitrogen": 20, "phosphorus": 40, "potassium": 40, "ph": 7.0, "rainfall": 60, "soil": "loam"},
    {"name": "Mustard", "nitrogen": 40, "phosphorus": 40, "potassium": 40, "ph": 7.0, "rainfall": 50, "soil": "loam"},
    {"name": "Barley", "nitrogen": 30, "phosphorus": 30, "potassium": 30, "ph": 6.5, "rainfall": 50, "soil": "sandy"},
    {"name": "Millet", "nitrogen": 20, "phosphorus": 20, "potassium": 20, "ph": 6.5, "rainfall": 40, "soil": "sandy"},
    {"name": "Sorghum", "nitrogen": 30, "phosphorus": 30, "potassium": 30, "ph": 6.5, "rainfall": 60, "soil": "loam"},
    {"name": "Jute", "nitrogen": 80, "phosphorus": 40, "potassium": 40, "ph": 6.5, "rainfall": 150, "soil": "clay"},
    {"name": "Coffee", "nitrogen": 100, "phosphorus": 60, "potassium": 80, "ph": 6.0, "rainfall": 200, "soil": "loam"},
    {"name": "Tea", "nitrogen": 100, "phosphorus": 40, "potassium": 60, "ph": 5.0, "rainfall": 250, "soil": "acidic"},
    {"name": "Rubber", "nitrogen": 50, "phosphorus": 30, "potassium": 30, "ph": 5.5, "rainfall": 200, "soil": "acidic"},
    {"name": "Coconut", "nitrogen": 60, "phosphorus": 40, "potassium": 80, "ph": 6.5, "rainfall": 150, "soil": "sandy"},
    # Add more crops to simulate 100+
]

@app.post("/recommend-crops", response_model=CropRecommendationResponse)
async def recommend_crops(request: CropRecommendationRequest):
    """
    Recommend crops based on soil and weather conditions using a mock ML model.
    """
    recommendations = []
    
    # Mock ML Logic: Calculate a "suitability score" for each crop
    for crop in CROP_DATABASE:
        score = 100.0
        
        # Penalize for soil mismatch (simplified)
        if request.soil_type.lower() not in crop["soil"].lower() and crop["soil"] != "loam":
             score -= 30
        
        # Penalize for rainfall difference
        rainfall_diff = abs(request.rainfall - crop["rainfall"])
        if rainfall_diff > 100:
            score -= 40
        elif rainfall_diff > 50:
            score -= 20
            
        # Penalize for pH difference
        ph_diff = abs(request.ph - crop["ph"])
        if ph_diff > 1.5:
            score -= 30
        elif ph_diff > 0.5:
            score -= 10
            
        # Add some randomness to simulate ML confidence
        score += random.uniform(-5, 5)
        
        # Normalize score
        score = max(0, min(100, score))
        
        if score > 60:
            recommendations.append({
                "crop": crop["name"],
                "confidence": round(score / 100.0, 2),
                "reason": f"Suitable for {request.soil_type} soil and current rainfall."
            })
            
    # Sort by confidence
    recommendations.sort(key=lambda x: x["confidence"], reverse=True)
    
    return CropRecommendationResponse(
        recommended_crops=recommendations[:5] # Return top 5
    )

if __name__ == "__main__":
    print("""
    ╔═══════════════════════════════════════════════════════════╗
    ║  Kheti Sahayak ML Inference Service (Mock)                ║
    ║  Starting FastAPI server on http://localhost:8000         ║
    ║                                                           ║
    ║  ⚠️  This is a MOCK service for development               ║
    ║  Replace with actual trained ML model in production       ║
    ╚═══════════════════════════════════════════════════════════╝
    """)

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
