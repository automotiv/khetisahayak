"""
Example usage of LLaVA Crop Diagnostics Service
Demonstrates different ways to use the free Hugging Face API
"""

import os
from llava_service import LLaVACropDiagnostics, quick_diagnose

# Set your Hugging Face token
# Get free token from: https://huggingface.co/settings/tokens
os.environ["HUGGINGFACE_TOKEN"] = "hf_YOUR_TOKEN_HERE"


def example_1_simple_diagnosis():
    """Example 1: Simple one-line diagnosis"""
    print("\n" + "="*50)
    print("Example 1: Simple Diagnosis")
    print("="*50)
    
    result = quick_diagnose("path/to/your/leaf_image.jpg")
    print(result)


def example_2_detailed_analysis():
    """Example 2: Detailed multi-question analysis"""
    print("\n" + "="*50)
    print("Example 2: Detailed Analysis")
    print("="*50)
    
    service = LLaVACropDiagnostics()
    
    # Get comprehensive diagnosis
    detailed = service.get_detailed_diagnosis("path/to/your/leaf_image.jpg")
    
    print(f"\n🔍 Disease: {detailed.get('disease')}")
    print(f"\n⚠️  Severity: {detailed.get('severity')}")
    print(f"\n💊 Treatment: {detailed.get('treatment')}")
    print(f"\n🛡️  Prevention: {detailed.get('prevention')}")


def example_3_custom_questions():
    """Example 3: Ask custom questions"""
    print("\n" + "="*50)
    print("Example 3: Custom Questions")
    print("="*50)
    
    service = LLaVACropDiagnostics()
    
    custom_questions = [
        "Is this disease fungal, bacterial, or viral?",
        "What stage of infection is this?",
        "Will this spread to nearby plants?",
        "What organic treatments are available?"
    ]
    
    responses = service.conversational_diagnosis(
        "path/to/your/leaf_image.jpg",
        custom_questions
    )
    
    for question, answer in responses.items():
        print(f"\nQ: {question}")
        print(f"A: {answer}")
        print("-" * 50)


def example_4_batch_processing():
    """Example 4: Process multiple images"""
    print("\n" + "="*50)
    print("Example 4: Batch Processing")
    print("="*50)
    
    service = LLaVACropDiagnostics()
    
    image_paths = [
        "field_survey/plant_1.jpg",
        "field_survey/plant_2.jpg",
        "field_survey/plant_3.jpg",
    ]
    
    results = service.batch_diagnose(
        image_paths,
        question="Identify the disease and recommend immediate action"
    )
    
    for i, result in enumerate(results, 1):
        print(f"\n🌱 Plant {i}:")
        if result["success"]:
            print(f"   {result['diagnosis']}")
        else:
            print(f"   ❌ Error: {result.get('error')}")


def example_5_with_error_handling():
    """Example 5: Proper error handling"""
    print("\n" + "="*50)
    print("Example 5: Error Handling")
    print("="*50)
    
    service = LLaVACropDiagnostics()
    
    result = service.diagnose_crop(
        "potentially_missing_file.jpg",
        "What disease is this?"
    )
    
    if result["success"]:
        print("✅ Success!")
        print(f"Diagnosis: {result['diagnosis']}")
        print(f"Cached: {result.get('cached', False)}")
    else:
        print("❌ Failed!")
        print(f"Error: {result.get('error')}")
        
        # Implement fallback logic
        if "rate limit" in result.get('error', '').lower():
            print("\n💡 Tip: Consider using caching or upgrading to Pro tier")
        elif result.get('status_code') == 503:
            print("\n⏳ Tip: Model is loading, retry in 20 seconds")


def example_6_caching_demo():
    """Example 6: Demonstrate caching feature"""
    print("\n" + "="*50)
    print("Example 6: Caching Demo")
    print("="*50)
    
    service = LLaVACropDiagnostics()
    
    image = "path/to/your/leaf_image.jpg"
    question = "What disease is this?"
    
    # First call - hits API
    print("\n1st call (hits API)...")
    result1 = service.diagnose_crop(image, question)
    print(f"Cached: {result1.get('cached', False)}")
    
    # Second call - from cache
    print("\n2nd call (from cache)...")
    result2 = service.diagnose_crop(image, question)
    print(f"Cached: {result2.get('cached', False)}")
    
    # Clear cache
    service.clear_cache()
    
    # Third call - hits API again
    print("\n3rd call after clearing cache...")
    result3 = service.diagnose_crop(image, question)
    print(f"Cached: {result3.get('cached', False)}")


if __name__ == "__main__":
    print("\n🌱 LLaVA Crop Diagnostics - Usage Examples")
    print("=" * 50)
    print("\n⚠️  Important: Set your HUGGINGFACE_TOKEN in environment or code")
    print("Get free token from: https://huggingface.co/settings/tokens\n")
    
    # Run examples (uncomment the ones you want to try)
    
    # example_1_simple_diagnosis()
    # example_2_detailed_analysis()
    # example_3_custom_questions()
    # example_4_batch_processing()
    # example_5_with_error_handling()
    # example_6_caching_demo()
    
    print("\n✅ Examples complete!")
    print("\n💡 Tip: Edit this file to uncomment and run specific examples")
