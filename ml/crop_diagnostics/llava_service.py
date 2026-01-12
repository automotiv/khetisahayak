"""
LLaVA-based Crop Disease Diagnostics Service
Free integration with Hugging Face Inference API
"""

import requests
from PIL import Image
import io
import base64
import os
from typing import Optional, Dict, List
import time
from functools import wraps


def retry_with_exponential_backoff(max_retries=3):
    """Handle rate limits and model loading gracefully"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                result = func(*args, **kwargs)
                
                if isinstance(result, dict) and result.get("status_code") == 503:
                    wait_time = 20 * (attempt + 1)
                    print(f"Model loading, waiting {wait_time}s... (Attempt {attempt + 1}/{max_retries})")
                    time.sleep(wait_time)
                    continue
                    
                return result
            return {"success": False, "error": "Max retries exceeded"}
        return wrapper
    return decorator


class LLaVACropDiagnostics:
    """
    Free LLaVA-based crop disease diagnostics using Hugging Face Inference API
    
    Model: YuchengShi/LLaVA-v1.5-7B-Plant-Leaf-Diseases-Detection
    Cost: FREE (with rate limits ~1000 requests/hour)
    
    Get your free token from: https://huggingface.co/settings/tokens
    """
    
    def __init__(self, hf_token: Optional[str] = None):
        """
        Initialize with your Hugging Face token
        
        Args:
            hf_token: Hugging Face API token (or set HUGGINGFACE_TOKEN env var)
        """
        self.hf_token = hf_token or os.getenv("HUGGINGFACE_TOKEN")
        if not self.hf_token:
            raise ValueError(
                "Hugging Face token required. Get free token from: "
                "https://huggingface.co/settings/tokens"
            )
        
        self.api_url = (
            "https://api-inference.huggingface.co/models/"
            "YuchengShi/LLaVA-v1.5-7B-Plant-Leaf-Diseases-Detection"
        )
        self.headers = {"Authorization": f"Bearer {self.hf_token}"}
        self.cache = {}  # Simple in-memory cache
    
    @retry_with_exponential_backoff(max_retries=3)
    def diagnose_crop(
        self, 
        image_path: str, 
        question: str = "What disease does this plant have? Provide diagnosis and treatment recommendations.",
        use_cache: bool = True
    ) -> Dict:
        """
        Analyze crop image and answer questions about diseases
        
        Args:
            image_path: Path to crop/leaf image
            question: Question to ask about the image
            use_cache: Whether to use cached results
            
        Returns:
            Dictionary with diagnosis information:
            {
                "success": True/False,
                "diagnosis": "AI response text",
                "question": "original question",
                "model": "model name",
                "cached": True/False
            }
        """
        # Check cache
        cache_key = f"{hash(image_path)}_{question}"
        if use_cache and cache_key in self.cache:
            result = self.cache[cache_key]
            result["cached"] = True
            return result
        
        try:
            # Load and encode image
            with open(image_path, "rb") as f:
                image_bytes = f.read()
            
            # Prepare payload for the API
            payload = {
                "inputs": {
                    "image": base64.b64encode(image_bytes).decode(),
                    "question": question
                }
            }
            
            # Make API request
            response = requests.post(
                self.api_url,
                headers=self.headers,
                json=payload,
                timeout=60
            )
            
            if response.status_code == 200:
                result_data = response.json()
                result = {
                    "success": True,
                    "diagnosis": result_data.get("generated_text", str(result_data)),
                    "question": question,
                    "model": "LLaVA-v1.5-7B",
                    "cached": False
                }
                
                # Cache successful results
                self.cache[cache_key] = result
                return result
                
            elif response.status_code == 503:
                return {
                    "success": False,
                    "error": "Model is loading on Hugging Face servers. Please retry in 20 seconds.",
                    "status_code": 503
                }
            else:
                return {
                    "success": False,
                    "error": f"API Error: {response.status_code}",
                    "details": response.text
                }
                
        except FileNotFoundError:
            return {
                "success": False,
                "error": f"Image file not found: {image_path}"
            }
        except Exception as e:
            return {
                "success": False,
                "error": f"Exception: {str(e)}"
            }
    
    def batch_diagnose(
        self, 
        image_paths: List[str], 
        question: str = "What disease does this plant have?"
    ) -> List[Dict]:
        """
        Diagnose multiple images
        
        Args:
            image_paths: List of image file paths
            question: Question to ask for each image
            
        Returns:
            List of diagnosis results
        """
        results = []
        for img_path in image_paths:
            result = self.diagnose_crop(img_path, question)
            results.append(result)
            
            # Rate limit protection: wait between requests
            if not result.get("cached", False):
                time.sleep(1)
        
        return results
    
    def conversational_diagnosis(
        self, 
        image_path: str, 
        questions: List[str]
    ) -> Dict[str, str]:
        """
        Ask multiple questions about the same image
        Useful for detailed multi-aspect analysis
        
        Args:
            image_path: Path to image
            questions: List of questions to ask
            
        Returns:
            Dictionary mapping questions to answers
        """
        responses = {}
        for question in questions:
            result = self.diagnose_crop(image_path, question)
            if result["success"]:
                responses[question] = result["diagnosis"]
            else:
                responses[question] = f"Error: {result.get('error')}"
            
            # Rate limit protection
            time.sleep(0.5)
        
        return responses
    
    def get_detailed_diagnosis(self, image_path: str) -> Dict:
        """
        Get comprehensive diagnosis with multiple aspects
        
        Returns:
            Dictionary with disease, severity, treatment, prevention
        """
        questions = {
            "disease": "What disease or pest problem does this plant have? Be specific.",
            "severity": "How severe is this condition? Rate from mild to critical.",
            "treatment": "What treatment or intervention do you recommend?",
            "prevention": "How can this problem be prevented in the future?"
        }
        
        detailed_result = {
            "image": image_path,
            "timestamp": time.time()
        }
        
        for key, question in questions.items():
            result = self.diagnose_crop(image_path, question)
            if result["success"]:
                detailed_result[key] = result["diagnosis"]
            else:
                detailed_result[key] = f"Error: {result.get('error')}"
        
        return detailed_result
    
    def clear_cache(self):
        """Clear the diagnosis cache"""
        self.cache = {}
        print("Cache cleared")


# Convenience function for quick testing
def quick_diagnose(image_path: str, token: Optional[str] = None) -> str:
    """
    Quick one-line diagnosis function
    
    Usage:
        diagnosis = quick_diagnose("sick_leaf.jpg")
        print(diagnosis)
    """
    service = LLaVACropDiagnostics(hf_token=token)
    result = service.diagnose_crop(image_path)
    
    if result["success"]:
        return result["diagnosis"]
    else:
        return f"Error: {result.get('error')}"


if __name__ == "__main__":
    # Example usage
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python llava_service.py <image_path> [question]")
        print("\nExample:")
        print("  python llava_service.py diseased_leaf.jpg")
        print('  python llava_service.py leaf.jpg "How severe is this?"')
        sys.exit(1)
    
    image_path = sys.argv[1]
    question = sys.argv[2] if len(sys.argv) > 2 else "What disease does this plant have?"
    
    print(f"Analyzing: {image_path}")
    print(f"Question: {question}\n")
    
    result = quick_diagnose(image_path)
    print("Diagnosis:")
    print(result)
