# LLaVA Crop Diagnostics - Quick Start Guide

## 🚀 Quick Start (3 Steps)

### 1. Get Your Free Hugging Face Token
```bash
# Visit: https://huggingface.co/settings/tokens
# Click "New token" → Name: "kheti-sahayak" → Role: "read" → Create token
```

### 2. Install Dependencies
```bash
cd ml/crop_diagnostics
pip install -r requirements.txt
```

### 3. Set Token & Run
```bash
# Set your token
export HUGGINGFACE_TOKEN="hf_your_token_here"

# Test the service
python examples.py
```

## 📋 Usage Examples

### Simple Diagnosis
```python
from llava_service import quick_diagnose

diagnosis = quick_diagnose("my_leaf_image.jpg")
print(diagnosis)
```

### Detailed Analysis
```python
from llava_service import LLaVACropDiagnostics

service = LLaVACropDiagnostics()
result = service.get_detailed_diagnosis("my_leaf_image.jpg")

print("Disease:", result['disease'])
print("Severity:", result['severity'])
print("Treatment:", result['treatment'])
```

### Custom Questions
```python
service = LLaVACropDiagnostics()

questions = [
    "What disease is this?",
    "Is it contagious?",
    "What organic remedies work?"
]

answers = service.conversational_diagnosis("leaf.jpg", questions)
for q, a in answers.items():
    print(f"Q: {q}\nA: {a}\n")
```

## 🌐 Web Interface

### Run Locally
```bash
python gradio_app.py
# Open http://localhost:7860
```

### Deploy to Hugging Face Spaces (FREE)
1. Create account at https://huggingface.co/spaces
2. Click "Create new Space"
3. Choose "Gradio"
4. Upload `gradio_app.py` and `llava_service.py`
5. Add secret: `HUGGINGFACE_TOKEN`
6. Your app will be live!

## 🔌 REST API

### Run FastAPI Server
```bash
pip install fastapi uvicorn python-multipart
python api_server.py
# API at http://localhost:8000
```

### Test API
```bash
curl -X POST http://localhost:8000/api/diagnose \
  -F "image=@my_leaf.jpg" \
  -F "question=What disease is this?"
```

## 💰 Cost Breakdown

| Deployment | Cost | Limits |
|------------|------|--------|
| HF Inference API | $0 | ~1000 req/hr |
| HF Spaces | $0 | Public hosting |
| Local (with GPU) | $0* | Unlimited |

*Electricity costs only

## 🎯 Integration with Kheti Sahayak

### Backend (Django/Flask)
```python
# Add to your views
from ml.crop_diagnostics.llava_service import LLaVACropDiagnostics

diagnostics = LLaVACropDiagnostics()

def diagnose_crop_view(request):
    image_path = save_uploaded_image(request.FILES['image'])
    result = diagnostics.diagnose_crop(image_path)
    return JsonResponse(result)
```

### Mobile App (Flutter)
```dart
// Call your backend API
final response = await http.post(
  Uri.parse('YOUR_API/diagnose'),
  body: {'image': imageFile}
);
```

## 📚 Files Overview

- `llava_service.py` - Core service implementation
- `examples.py` - Usage examples
- `gradio_app.py` - Web interface
- `api_server.py` - REST API server
- `requirements.txt` - Dependencies

## 🆘 Troubleshooting

**Model Loading Error (503)**
- Wait 20 seconds and retry
- Hugging Face warms up the model

**Rate Limit Hit**
- Enable caching (already built-in)
- Consider implementing queue system
- Upgrade to HF Pro ($9/month for unlimited)

**Token Error**
- Verify token at https://huggingface.co/settings/tokens
- Ensure token has "read" permission

## 🎓 Next Steps

1. ✅ Deploy Gradio app to HF Spaces
2. ✅ Integrate API into your backend
3. ✅ Add example crop images
4. ✅ Test with real field data
5. ✅ Monitor usage and cache hit rates

## 📞 Support

- Full guide: `llava_integration_guide.md`
- Model: https://huggingface.co/YuchengShi/LLaVA-v1.5-7B-Plant-Leaf-Diseases-Detection
- Issues: File in your repo

Happy diagnosing! 🌱
