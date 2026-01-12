"""
FastAPI backend endpoint for LLaVA crop diagnostics
Free deployment on platforms like Render, Railway, or Fly.io
"""

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from llava_service import LLaVACropDiagnostics
import os
import shutil
import uuid
from pathlib import Path

# Initialize FastAPI app
app = FastAPI(
    title="Kheti Sahayak - Crop Diagnostics API",
    description="Free AI-powered crop disease diagnostics using LLaVA",
    version="1.0.0"
)

# CORS middleware for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Update with your frontend domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize diagnostics service
diagnostics = LLaVACropDiagnostics()

# Create temp directory for uploads
UPLOAD_DIR = Path("temp_uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


@app.get("/")
async def root():
    """API health check"""
    return {
        "service": "Kheti Sahayak Crop Diagnostics",
        "status": "active",
        "model": "LLaVA-v1.5-7B",
        "cost": "Free (Hugging Face Inference API)",
        "endpoints": {
            "diagnose": "/api/diagnose",
            "detailed": "/api/diagnose/detailed",
            "batch": "/api/diagnose/batch"
        }
    }


@app.post("/api/diagnose")
async def diagnose_crop(
    image: UploadFile = File(..., description="Crop/leaf image"),
    question: str = Form(
        "What disease does this plant have? Provide diagnosis and treatment.",
        description="Question to ask about the image"
    )
):
    """
    Diagnose a single crop image
    
    Returns:
        JSON with diagnosis, question, and metadata
    """
    # Validate image
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    # Save uploaded file with unique name
    file_id = str(uuid.uuid4())
    file_extension = Path(image.filename).suffix
    temp_path = UPLOAD_DIR / f"{file_id}{file_extension}"
    
    try:
        # Save file
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        
        # Get diagnosis
        result = diagnostics.diagnose_crop(str(temp_path), question)
        
        return JSONResponse(content=result)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        # Clean up temp file
        if temp_path.exists():
            temp_path.unlink()


@app.post("/api/diagnose/detailed")
async def diagnose_crop_detailed(
    image: UploadFile = File(..., description="Crop/leaf image")
):
    """
    Get detailed diagnosis with disease, severity, treatment, and prevention
    
    Returns:
        JSON with comprehensive diagnosis
    """
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    file_id = str(uuid.uuid4())
    file_extension = Path(image.filename).suffix
    temp_path = UPLOAD_DIR / f"{file_id}{file_extension}"
    
    try:
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        
        # Get detailed diagnosis
        result = diagnostics.get_detailed_diagnosis(str(temp_path))
        
        return JSONResponse(content=result)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        if temp_path.exists():
            temp_path.unlink()


@app.post("/api/diagnose/custom")
async def diagnose_crop_custom(
    image: UploadFile = File(...),
    questions: str = Form(..., description="Comma-separated questions")
):
    """
    Ask multiple custom questions about a crop image
    
    Args:
        image: Crop image
        questions: Comma-separated list of questions
        
    Returns:
        JSON mapping questions to answers
    """
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    file_id = str(uuid.uuid4())
    file_extension = Path(image.filename).suffix
    temp_path = UPLOAD_DIR / f"{file_id}{file_extension}"
    
    try:
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        
        # Parse questions
        question_list = [q.strip() for q in questions.split(",")]
        
        # Get conversational diagnosis
        result = diagnostics.conversational_diagnosis(
            str(temp_path),
            question_list
        )
        
        return JSONResponse(content=result)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        if temp_path.exists():
            temp_path.unlink()


@app.get("/api/stats")
async def get_stats():
    """Get API usage statistics"""
    return {
        "cache_size": len(diagnostics.cache),
        "model": "LLaVA-v1.5-7B",
        "provider": "Hugging Face Inference API",
        "cost": "$0/month (free tier)"
    }


@app.post("/api/cache/clear")
async def clear_cache():
    """Clear the diagnosis cache"""
    diagnostics.clear_cache()
    return {"status": "Cache cleared successfully"}


if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
