import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from disease_database import (
    CROP_DISEASES,
    SUPPORTED_CROPS,
    get_crop_diseases,
    get_disease_info,
    get_disease_class_labels,
    get_similar_diseases,
    get_all_disease_names
)


class TestDiseaseDatabase:
    def test_supported_crops_count(self):
        assert len(SUPPORTED_CROPS) >= 20
    
    def test_all_crops_have_diseases(self):
        for crop_type in SUPPORTED_CROPS:
            diseases = get_crop_diseases(crop_type)
            assert len(diseases) > 0, f"Crop {crop_type} has no diseases"
    
    def test_all_crops_have_healthy_state(self):
        for crop_type in SUPPORTED_CROPS:
            diseases = get_crop_diseases(crop_type)
            assert "healthy" in diseases, f"Crop {crop_type} missing healthy state"
    
    def test_disease_info_structure(self):
        required_fields = ["name", "hindi_name", "description", "symptoms", "causes", "treatments", "prevention", "severity"]
        
        for crop_type in list(SUPPORTED_CROPS.keys())[:5]:
            diseases = get_crop_diseases(crop_type)
            for disease_id, disease_info in diseases.items():
                for field in required_fields:
                    assert field in disease_info, f"Missing {field} in {crop_type}/{disease_id}"
    
    def test_get_disease_info(self):
        info = get_disease_info("rice", "rice_blast")
        assert info is not None
        assert info["name"] == "Rice Blast"
        assert info["severity"] == "high"
    
    def test_get_disease_info_invalid_crop(self):
        info = get_disease_info("invalid_crop", "some_disease")
        assert info == {}
    
    def test_get_disease_info_invalid_disease(self):
        info = get_disease_info("rice", "invalid_disease")
        assert info == {}
    
    def test_get_disease_class_labels(self):
        labels = get_disease_class_labels("rice")
        assert "0" in labels or 0 in labels or len(labels) > 0
        assert len(labels) == len(CROP_DISEASES["rice"])
    
    def test_get_similar_diseases(self):
        similar = get_similar_diseases("rice", "rice_blast", limit=3)
        assert isinstance(similar, list)
        assert len(similar) <= 3
        
        for disease in similar:
            assert "disease_id" in disease
            assert disease["disease_id"] != "rice_blast"
            assert disease["disease_id"] != "healthy"
    
    def test_get_all_disease_names(self):
        names = get_all_disease_names("rice")
        assert "healthy" not in names
        assert len(names) > 0
    
    def test_treatments_structure(self):
        info = get_disease_info("rice", "rice_blast")
        treatments = info.get("treatments", [])
        
        for treatment in treatments:
            assert "type" in treatment
            assert "name" in treatment
            assert treatment["type"] in ["chemical", "biological", "organic", "antibiotic"]
    
    def test_severity_values(self):
        valid_severities = ["none", "low", "medium", "high"]
        
        for crop_type in SUPPORTED_CROPS:
            diseases = get_crop_diseases(crop_type)
            for disease_id, disease_info in diseases.items():
                severity = disease_info.get("severity")
                assert severity in valid_severities, f"Invalid severity {severity} in {crop_type}/{disease_id}"
    
    def test_hindi_names_present(self):
        for crop_type, crop_info in SUPPORTED_CROPS.items():
            assert "hindi_name" in crop_info
            assert len(crop_info["hindi_name"]) > 0
        
        for crop_type in list(SUPPORTED_CROPS.keys())[:5]:
            diseases = get_crop_diseases(crop_type)
            for disease_id, disease_info in diseases.items():
                assert "hindi_name" in disease_info


class TestModelManager:
    def test_import_model_manager(self):
        try:
            from model_manager import ModelManager, CropModel, get_model_manager
            assert True
        except ImportError as e:
            if "cv2" in str(e) or "numpy" in str(e):
                pytest.skip("OpenCV/NumPy not installed")
            raise


class TestPreprocessing:
    def test_import_preprocessing(self):
        try:
            from preprocessing import preprocess_image, validate_image_bytes, augment_for_tta
            assert True
        except ImportError as e:
            if "cv2" in str(e) or "numpy" in str(e):
                pytest.skip("OpenCV/NumPy not installed")
            raise


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
