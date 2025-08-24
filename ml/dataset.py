import os
from typing import List

import pandas as pd
import cv2
import torch
from torch.utils.data import Dataset


class ManifestImageDataset(Dataset):
    """Simple manifest-based dataset.

    Expects a CSV with columns: image_path,label
    image_path can be absolute or relative to the manifest file directory.
    """

    def __init__(self, manifest_csv: str, transform=None):
        self.manifest_csv = manifest_csv
        self.df = pd.read_csv(manifest_csv)
        self.root = os.path.dirname(os.path.abspath(manifest_csv))
        self.transform = transform

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        row = self.df.iloc[idx]
        path = row['image_path']
        if not os.path.isabs(path):
            path = os.path.join(self.root, path)
        img = cv2.imread(path)
        if img is None:
            raise RuntimeError(f"Failed to read image: {path}")
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        label = int(row['label'])
        if self.transform:
            augmented = self.transform(image=img)
            img = augmented['image']
        img = torch.from_numpy(img).permute(2, 0, 1).float() / 255.0
        return img, label
