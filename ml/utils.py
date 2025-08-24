import os
import json
import logging
from typing import Dict, Any, List, Optional, Union

import torch
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import (
    accuracy_score, confusion_matrix, precision_recall_fscore_support,
    roc_curve, auc, classification_report
)

logger = logging.getLogger(__name__)


def save_checkpoint(state: dict, out_dir: str, name: str = 'checkpoint.pth') -> str:
    """Save model checkpoint to file
    
    Args:
        state: Dictionary containing model state and metadata
        out_dir: Directory to save checkpoint
        name: Filename for checkpoint
        
    Returns:
        Path to saved checkpoint
    """
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, name)
    torch.save(state, path)
    return path


def load_checkpoint(path: str, model: torch.nn.Module, device: str = 'cpu') -> Dict[str, Any]:
    """Load model checkpoint from file
    
    Args:
        path: Path to checkpoint file
        model: Model to load weights into
        device: Device to load model on
        
    Returns:
        Dictionary containing checkpoint metadata
    """
    if not os.path.exists(path):
        raise FileNotFoundError(f"Checkpoint not found at {path}")
        
    checkpoint = torch.load(path, map_location=device)
    model.load_state_dict(checkpoint['model_state'])
    return checkpoint


def evaluate(model: torch.nn.Module, dataloader, device='cpu') -> Dict[str, Any]:
    """Evaluate model on dataloader
    
    Args:
        model: PyTorch model to evaluate
        dataloader: DataLoader with evaluation data
        device: Device to run evaluation on
        
    Returns:
        Dictionary with evaluation metrics
    """
    model.eval()
    all_preds = []
    all_labels = []
    all_probs = []
    
    with torch.no_grad():
        for x, y in dataloader:
            x = x.to(device)
            out = model(x)
            probs = torch.softmax(out, dim=1)
            preds = torch.argmax(out, dim=1).cpu().numpy()
            
            all_preds.extend(preds.tolist())
            all_labels.extend(y.numpy().tolist())
            all_probs.extend(probs.cpu().numpy().tolist())
    
    # Calculate metrics
    acc = accuracy_score(all_labels, all_preds)
    cm = confusion_matrix(all_labels, all_preds)
    precision, recall, f1, _ = precision_recall_fscore_support(
        all_labels, all_preds, average='weighted'
    )
    
    # Convert to numpy arrays for further processing
    all_labels_np = np.array(all_labels)
    all_preds_np = np.array(all_preds)
    all_probs_np = np.array(all_probs)
    
    metrics = {
        'accuracy': acc,
        'precision': precision,
        'recall': recall,
        'f1': f1,
        'confusion_matrix': cm,
        'predictions': all_preds_np,
        'labels': all_labels_np,
        'probabilities': all_probs_np
    }
    
    return metrics


def plot_confusion_matrix(cm: np.ndarray, class_names: List[str], output_path: Optional[str] = None):
    """Plot confusion matrix
    
    Args:
        cm: Confusion matrix from sklearn
        class_names: List of class names
        output_path: Path to save plot (if None, just displays)
    """
    plt.figure(figsize=(10, 8))
    plt.imshow(cm, interpolation='nearest', cmap=plt.cm.Blues)
    plt.title('Confusion Matrix')
    plt.colorbar()
    
    tick_marks = np.arange(len(class_names))
    plt.xticks(tick_marks, class_names, rotation=45)
    plt.yticks(tick_marks, class_names)
    
    # Normalize and annotate
    cm_norm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]
    thresh = cm.max() / 2.
    
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            plt.text(j, i, f"{cm[i, j]}\n({cm_norm[i, j]:.2f})",
                    horizontalalignment="center",
                    color="white" if cm[i, j] > thresh else "black")
    
    plt.tight_layout()
    plt.ylabel('True label')
    plt.xlabel('Predicted label')
    
    if output_path:
        plt.savefig(output_path)
        logger.info(f"Saved confusion matrix to {output_path}")
    else:
        plt.show()


def plot_roc_curve(labels: np.ndarray, probs: np.ndarray, output_path: Optional[str] = None):
    """Plot ROC curve for binary classification
    
    Args:
        labels: Ground truth labels
        probs: Predicted probabilities for positive class
        output_path: Path to save plot (if None, just displays)
    """
    # For binary classification
    if probs.shape[1] == 2:
        probs = probs[:, 1]  # Use probability of positive class
    else:
        logger.warning("ROC curve only supported for binary classification")
        return
    
    fpr, tpr, _ = roc_curve(labels, probs)
    roc_auc = auc(fpr, tpr)
    
    plt.figure(figsize=(8, 8))
    plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'ROC curve (area = {roc_auc:.2f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('Receiver Operating Characteristic')
    plt.legend(loc="lower right")
    
    if output_path:
        plt.savefig(output_path)
        logger.info(f"Saved ROC curve to {output_path}")
    else:
        plt.show()


def get_classification_report(labels: np.ndarray, preds: np.ndarray, 
                             class_names: Optional[List[str]] = None) -> str:
    """Get classification report as string
    
    Args:
        labels: Ground truth labels
        preds: Predicted labels
        class_names: Optional list of class names
        
    Returns:
        Classification report as string
    """
    return classification_report(labels, preds, target_names=class_names)


def save_metrics(metrics: Dict[str, Any], output_dir: str, prefix: str = ''):
    """Save evaluation metrics to JSON file
    
    Args:
        metrics: Dictionary of metrics
        output_dir: Directory to save metrics
        prefix: Prefix for filename
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Create a copy of metrics that's JSON serializable
    json_metrics = {}
    for k, v in metrics.items():
        if isinstance(v, np.ndarray):
            if k in ['confusion_matrix']:
                json_metrics[k] = v.tolist()
            else:
                # Skip large arrays
                continue
        elif isinstance(v, (int, float, str, bool)):
            json_metrics[k] = v
    
    filename = f"{prefix}_metrics.json" if prefix else "metrics.json"
    output_path = os.path.join(output_dir, filename)
    
    with open(output_path, 'w') as f:
        json.dump(json_metrics, f, indent=2)
    
    logger.info(f"Saved metrics to {output_path}")
    return output_path
