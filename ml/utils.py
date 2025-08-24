import os
import torch
import numpy as np
from sklearn.metrics import accuracy_score, confusion_matrix


def save_checkpoint(state: dict, out_dir: str, name: str = 'checkpoint.pth'):
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, name)
    torch.save(state, path)
    return path


def evaluate(model: torch.nn.Module, dataloader, device='cpu'):
    model.eval()
    preds = []
    labels = []
    with torch.no_grad():
        for x, y in dataloader:
            x = x.to(device)
            out = model(x)
            p = torch.argmax(out, dim=1).cpu().numpy()
            preds.extend(p.tolist())
            labels.extend(y.numpy().tolist())
    acc = accuracy_score(labels, preds)
    cm = confusion_matrix(labels, preds)
    return {'accuracy': acc, 'confusion_matrix': cm}
