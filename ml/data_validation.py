import os
import json
import logging
import argparse
from pathlib import Path
from typing import Dict, List, Any, Tuple

import pandas as pd
import numpy as np
import cv2
from PIL import Image
import great_expectations as ge
from great_expectations.dataset import PandasDataset

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class DataValidator:
    """Data validation for ML training pipeline"""
    
    def __init__(self, manifest_path: str, base_dir: str = None):
        """Initialize data validator
        
        Args:
            manifest_path: Path to manifest CSV file
            base_dir: Base directory for relative paths in manifest
        """
        self.manifest_path = manifest_path
        self.base_dir = base_dir or os.path.dirname(manifest_path)
        self.df = None
        self.validation_results = {}
        self.load_manifest()
    
    def load_manifest(self):
        """Load manifest CSV file"""
        try:
            self.df = pd.read_csv(self.manifest_path)
            logger.info(f"Loaded manifest with {len(self.df)} entries")
            
            # Convert to Great Expectations dataset
            self.ge_df = ge.from_pandas(self.df)
            
        except Exception as e:
            logger.error(f"Failed to load manifest: {str(e)}")
            raise
    
    def validate_manifest_structure(self) -> bool:
        """Validate manifest structure"""
        # Check required columns
        required_columns = ['image_path', 'label']
        result = self.ge_df.expect_table_columns_to_match_set(
            column_set=required_columns,
            exact_match=False
        )
        
        self.validation_results['manifest_structure'] = result
        
        if not result.success:
            logger.error(f"Manifest structure validation failed: {result.result}")
            return False
        
        # Check for missing values
        missing_check = self.ge_df.expect_column_values_to_not_be_null('image_path')
        self.validation_results['missing_image_paths'] = missing_check
        
        label_check = self.ge_df.expect_column_values_to_not_be_null('label')
        self.validation_results['missing_labels'] = label_check
        
        if not (missing_check.success and label_check.success):
            logger.error("Manifest contains missing values")
            return False
        
        return True
    
    def validate_class_distribution(self, min_samples_per_class: int = 10) -> bool:
        """Validate class distribution
        
        Args:
            min_samples_per_class: Minimum number of samples per class
        """
        class_counts = self.df['label'].value_counts()
        min_count = class_counts.min()
        num_classes = len(class_counts)
        
        result = {
            'success': min_count >= min_samples_per_class,
            'result': {
                'observed_min': min_count,
                'threshold': min_samples_per_class,
                'class_counts': class_counts.to_dict(),
                'num_classes': num_classes
            }
        }
        
        self.validation_results['class_distribution'] = result
        
        if not result['success']:
            logger.warning(f"Class distribution validation failed: minimum {min_count} samples, threshold {min_samples_per_class}")
            return False
        
        logger.info(f"Class distribution: {num_classes} classes, min {min_count} samples per class")
        return True
    
    def validate_image_files(self, max_samples: int = None) -> Tuple[bool, Dict]:
        """Validate image files
        
        Args:
            max_samples: Maximum number of samples to validate (None for all)
        """
        df_sample = self.df if max_samples is None else self.df.sample(min(max_samples, len(self.df)))
        
        results = {
            'total': len(df_sample),
            'valid': 0,
            'invalid': 0,
            'missing': 0,
            'corrupt': 0,
            'invalid_files': []
        }
        
        for idx, row in df_sample.iterrows():
            img_path = row['image_path']
            
            # Handle relative paths
            if not os.path.isabs(img_path):
                img_path = os.path.join(self.base_dir, img_path)
            
            if not os.path.exists(img_path):
                results['missing'] += 1
                results['invalid_files'].append({'path': img_path, 'reason': 'missing'})
                continue
            
            try:
                # Try to open with OpenCV
                img = cv2.imread(img_path)
                if img is None:
                    raise ValueError("OpenCV could not read image")
                
                # Check dimensions
                h, w, c = img.shape
                if h < 10 or w < 10 or c != 3:
                    results['corrupt'] += 1
                    results['invalid_files'].append({
                        'path': img_path, 
                        'reason': f'invalid dimensions: {h}x{w}x{c}'
                    })
                    continue
                
                # Try to open with PIL as well
                with Image.open(img_path) as pil_img:
                    pil_img.verify()  # Verify image integrity
                
                results['valid'] += 1
                
            except Exception as e:
                results['corrupt'] += 1
                results['invalid_files'].append({'path': img_path, 'reason': str(e)})
        
        results['invalid'] = results['missing'] + results['corrupt']
        results['success'] = results['invalid'] == 0
        
        self.validation_results['image_files'] = results
        
        if not results['success']:
            logger.error(f"Image validation failed: {results['invalid']} invalid files out of {results['total']}")
            return False, results
        
        logger.info(f"Image validation passed: {results['valid']} valid files")
        return True, results
    
    def validate_label_consistency(self) -> bool:
        """Validate label consistency"""
        # Check if labels are consistent (all strings or all integers)
        try:
            # Try to convert to numeric
            numeric_labels = pd.to_numeric(self.df['label'])
            is_numeric = True
        except ValueError:
            is_numeric = False
        
        if is_numeric:
            # Check if all are integers
            is_integer = np.all(numeric_labels.apply(lambda x: x.is_integer()))
            result = {
                'success': is_integer,
                'result': {
                    'label_type': 'integer' if is_integer else 'float',
                    'unique_values': sorted(self.df['label'].unique().tolist())
                }
            }
        else:
            # Check if all are strings
            result = {
                'success': True,
                'result': {
                    'label_type': 'string',
                    'unique_values': sorted(self.df['label'].unique().tolist())
                }
            }
        
        self.validation_results['label_consistency'] = result
        
        if not result['success']:
            logger.error(f"Label consistency validation failed: {result['result']}")
            return False
        
        logger.info(f"Label consistency validation passed: {result['result']['label_type']} labels")
        return True
    
    def run_all_validations(self, max_image_samples: int = 100) -> bool:
        """Run all validations
        
        Args:
            max_image_samples: Maximum number of images to validate
        """
        structure_valid = self.validate_manifest_structure()
        if not structure_valid:
            logger.error("Manifest structure validation failed, stopping further validations")
            return False
        
        validations = [
            self.validate_class_distribution(),
            self.validate_label_consistency(),
            self.validate_image_files(max_samples=max_image_samples)[0]
        ]
        
        all_valid = all(validations)
        
        if all_valid:
            logger.info("All validations passed!")
        else:
            logger.error("Some validations failed")
        
        return all_valid
    
    def save_validation_report(self, output_path: str):
        """Save validation report to JSON file
        
        Args:
            output_path: Path to save report
        """
        # Convert any non-serializable objects
        def serialize(obj):
            if isinstance(obj, (np.int64, np.int32)):
                return int(obj)
            if isinstance(obj, (np.float64, np.float32)):
                return float(obj)
            if isinstance(obj, pd.Series):
                return obj.to_dict()
            if isinstance(obj, np.ndarray):
                return obj.tolist()
            raise TypeError(f"Object of type {type(obj)} is not JSON serializable")
        
        # Create report
        report = {
            'manifest_path': self.manifest_path,
            'base_dir': self.base_dir,
            'total_samples': len(self.df),
            'validation_results': self.validation_results,
            'timestamp': pd.Timestamp.now().isoformat()
        }
        
        # Save report
        with open(output_path, 'w') as f:
            json.dump(report, f, default=serialize, indent=2)
        
        logger.info(f"Validation report saved to {output_path}")


def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='Validate ML training data')
    parser.add_argument('--manifest', type=str, required=True,
                        help='Path to manifest CSV file')
    parser.add_argument('--base-dir', type=str, default=None,
                        help='Base directory for relative paths in manifest')
    parser.add_argument('--output', type=str, default='validation_report.json',
                        help='Path to save validation report')
    parser.add_argument('--max-image-samples', type=int, default=100,
                        help='Maximum number of images to validate')
    return parser.parse_args()


def main():
    """Main function"""
    args = parse_args()
    
    validator = DataValidator(
        manifest_path=args.manifest,
        base_dir=args.base_dir
    )
    
    valid = validator.run_all_validations(max_image_samples=args.max_image_samples)
    validator.save_validation_report(args.output)
    
    return 0 if valid else 1


if __name__ == '__main__':
    exit(main())