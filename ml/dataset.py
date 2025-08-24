import os
import logging
from typing import List, Dict, Tuple, Optional, Union
from pathlib import Path

import pandas as pd
import numpy as np
import cv2
import torch
from torch.utils.data import Dataset, random_split, Subset
from sklearn.model_selection import train_test_split


class ManifestImageDataset(Dataset):
    """Enhanced manifest-based dataset for production use.

    Expects a CSV with columns: image_path,label
    image_path can be absolute or relative to the manifest file directory.
    """

    def __init__(self, manifest_csv: str, transform=None, class_mapping: Dict[int, str] = None):
        self.manifest_csv = manifest_csv
        self.df = pd.read_csv(manifest_csv)
        self.root = os.path.dirname(os.path.abspath(manifest_csv))
        self.transform = transform
        self.class_mapping = class_mapping
        self.class_counts = self._count_classes()
        
        # Validate data integrity
        self._validate_dataset()
        
    def _validate_dataset(self):
        """Validate dataset integrity"""
        # Check for missing files
        missing_files = []
        for idx, row in self.df.iterrows():
            path = row['image_path']
            if not os.path.isabs(path):
                path = os.path.join(self.root, path)
            if not os.path.exists(path):
                missing_files.append(path)
        
        if missing_files:
            logging.warning(f"Found {len(missing_files)} missing files in dataset")
            if len(missing_files) > 5:
                logging.warning(f"First 5 missing files: {missing_files[:5]}")
            else:
                logging.warning(f"Missing files: {missing_files}")
    
    def _count_classes(self) -> Dict[int, int]:
        """Count number of samples per class"""
        return self.df['label'].value_counts().to_dict()

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        row = self.df.iloc[idx]
        path = row['image_path']
        if not os.path.isabs(path):
            path = os.path.join(self.root, path)
        
        try:
            img = cv2.imread(path)
            if img is None:
                raise RuntimeError(f"Failed to read image: {path}")
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        except Exception as e:
            logging.error(f"Error loading image {path}: {str(e)}")
            # Return a placeholder image in production to avoid crashing
            img = np.zeros((224, 224, 3), dtype=np.uint8)
            
        label = int(row['label'])
        
        if self.transform:
            try:
                augmented = self.transform(image=img)
                img = augmented['image']
            except Exception as e:
                logging.error(f"Error in transform for {path}: {str(e)}")
                # Return unaugmented image if transform fails
                img = torch.from_numpy(img).permute(2, 0, 1).float() / 255.0
                return img, label
                
        img = torch.from_numpy(img).permute(2, 0, 1).float() / 255.0
        return img, label
        
    def get_class_weights(self) -> torch.Tensor:
        """Calculate class weights for imbalanced datasets"""
        counts = np.array(list(self.class_counts.values()))
        weights = 1.0 / counts
        weights = weights / weights.sum() * len(self.class_counts)
        return torch.tensor(weights, dtype=torch.float32)


def create_data_splits(dataset: Dataset, val_size: float = 0.2, test_size: float = 0.1, 
                      random_seed: int = 42) -> Tuple[Subset, Subset, Optional[Subset]]:
    """Split dataset into train, validation and test sets
    
    Args:
        dataset: The full dataset to split
        val_size: Proportion of data to use for validation
        test_size: Proportion of data to use for testing (0 for no test set)
        random_seed: Random seed for reproducibility
        
    Returns:
        Tuple of (train_dataset, val_dataset, test_dataset)
        If test_size is 0, test_dataset will be None
    """
    dataset_size = len(dataset)
    indices = list(range(dataset_size))
    
    if test_size > 0:
        # First split off the test set
        test_split = int(np.floor(test_size * dataset_size))
        train_val_indices, test_indices = train_test_split(
            indices, test_size=test_split, random_state=random_seed, stratify=None
        )
        
        # Then split the remaining data into train and val
        val_split = int(np.floor(val_size * len(train_val_indices)))
        train_indices, val_indices = train_test_split(
            train_val_indices, test_size=val_split, random_state=random_seed, stratify=None
        )
        
        train_dataset = Subset(dataset, train_indices)
        val_dataset = Subset(dataset, val_indices)
        test_dataset = Subset(dataset, test_indices)
        
        return train_dataset, val_dataset, test_dataset
    else:
        # Just split into train and val
        val_split = int(np.floor(val_size * dataset_size))
        train_indices, val_indices = train_test_split(
            indices, test_size=val_split, random_state=random_seed, stratify=None
        )
        
        train_dataset = Subset(dataset, train_indices)
        val_dataset = Subset(dataset, val_indices)
        
        return train_dataset, val_dataset, None
