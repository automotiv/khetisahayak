"""
Gradio web interface for LLaVA Crop Diagnostics
Deploy to Hugging Face Spaces for FREE
"""

import gradio as gr
from llava_service import LLaVACropDiagnostics
import os
from PIL import Image

# Initialize diagnostics service
diagnostics = LLaVACropDiagnostics(
    hf_token=os.getenv("HUGGINGFACE_TOKEN")
)


def simple_diagnose(image, question):
    """Simple diagnosis interface"""
    if image is None:
        return "❌ Please upload an image"
    
    # Save uploaded image temporarily
    temp_path = "temp_upload.jpg"
    image.save(temp_path)
    
    # Get diagnosis
    result = diagnostics.diagnose_crop(temp_path, question)
    
    # Clean up
    try:
        os.remove(temp_path)
    except:
        pass
    
    if result["success"]:
        cached_badge = "🔄 Cached" if result.get("cached") else "🆕 Fresh"
        return f"**{cached_badge} Diagnosis:**\n\n{result['diagnosis']}"
    else:
        return f"**Error:** {result.get('error')}\n\n💡 Tip: Wait 20 seconds if model is loading"


def detailed_diagnose(image):
    """Detailed diagnosis with multiple aspects"""
    if image is None:
        return "❌ Please upload an image", "", "", ""
    
    temp_path = "temp_upload.jpg"
    image.save(temp_path)
    
    # Get detailed diagnosis
    result = diagnostics.get_detailed_diagnosis(temp_path)
    
    # Clean up
    try:
        os.remove(temp_path)
    except:
        pass
    
    return (
        result.get('disease', 'Error'),
        result.get('severity', 'Error'),
        result.get('treatment', 'Error'),
        result.get('prevention', 'Error')
    )


# Create Gradio interface with tabs
with gr.Blocks(
    title="🌱 Kheti Sahayak - AI Crop Diagnostics",
    theme=gr.themes.Soft()
) as demo:
    
    gr.Markdown("""
    # 🌱 Kheti Sahayak - AI Crop Disease Diagnostics
    
    Powered by **LLaVA-v1.5-7B** multimodal AI model. Upload a crop or leaf image and get instant diagnosis!
    
    💡 **Tip:** You can ask specific questions like:
    - "What disease is this?"
    - "How severe is this infection?"
    - "What organic treatment do you recommend?"
    """)
    
    with gr.Tabs():
        # Tab 1: Simple Diagnosis
        with gr.Tab("🔍 Simple Diagnosis"):
            with gr.Row():
                with gr.Column():
                    image_input = gr.Image(type="pil", label="Upload Crop/Leaf Image")
                    question_input = gr.Textbox(
                        value="What disease does this plant have? Provide diagnosis and treatment recommendations.",
                        label="Your Question",
                        lines=3
                    )
                    diagnose_btn = gr.Button("🔬 Diagnose", variant="primary")
                
                with gr.Column():
                    diagnosis_output = gr.Markdown(label="AI Diagnosis")
            
            diagnose_btn.click(
                fn=simple_diagnose,
                inputs=[image_input, question_input],
                outputs=diagnosis_output
            )
            
            gr.Examples(
                examples=[
                    # Add your example images here
                    # ["examples/tomato_leaf.jpg", "What disease is this?"],
                    # ["examples/rice_leaf.jpg", "How severe is this infection?"],
                ],
                inputs=[image_input, question_input],
                label="Example Images (Add your own)"
            )
        
        # Tab 2: Detailed Analysis
        with gr.Tab("📊 Detailed Analysis"):
            with gr.Row():
                with gr.Column():
                    image_input_detailed = gr.Image(type="pil", label="Upload Crop/Leaf Image")
                    analyze_btn = gr.Button("🔬 Analyze in Detail", variant="primary")
                
                with gr.Column():
                    disease_output = gr.Textbox(label="🦠 Disease Identification", lines=3)
                    severity_output = gr.Textbox(label="⚠️ Severity Assessment", lines=2)
                    treatment_output = gr.Textbox(label="💊 Treatment Recommendations", lines=3)
                    prevention_output = gr.Textbox(label="🛡️ Prevention Measures", lines=3)
            
            analyze_btn.click(
                fn=detailed_diagnose,
                inputs=image_input_detailed,
                outputs=[disease_output, severity_output, treatment_output, prevention_output]
            )
    
    gr.Markdown("""
    ---
    ### 📖 How to Use
    
    1. **Upload** a clear image of affected crop/leaf
    2. **Ask** a specific question or use the default
    3. **Get** instant AI-powered diagnosis and recommendations
    
    ### 💰 Cost
    **100% FREE** using Hugging Face Inference API
    
    ### 🔒 Privacy
    Images are processed temporarily and not stored
    
    ### 🌐 API Access
    Want to integrate this into your app? Check out our [API documentation](https://github.com/your-repo)
    
    ---
    *Powered by [LLaVA-v1.5-7B](https://huggingface.co/YuchengShi/LLaVA-v1.5-7B-Plant-Leaf-Diseases-Detection) | Built for Kheti Sahayak*
    """)


if __name__ == "__main__":
    # Launch the interface
    demo.launch(
        server_name="0.0.0.0",
        server_port=7860,
        share=False  # Set to True for temporary public link
    )
