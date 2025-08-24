import argparse
import os
import time
import logging
import json
from pathlib import Path
from typing import Dict, Any, Optional, List, Tuple

import torch
import timm
import mlflow
import numpy as np
from torch import nn
from torch.utils.data import DataLoader
import albumentations as A
from albumentations.pytorch import ToTensorV2

from dataset import ManifestImageDataset, create_data_splits
from utils import save_checkpoint, evaluate

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def get_transforms(img_size=224, train=True):
    """Get image transformations for training or validation"""
    if train:
        return A.Compose([
            A.SmallestMaxSize(max_size=img_size),
            A.RandomCrop(width=img_size, height=img_size),
            A.HorizontalFlip(p=0.5),
            A.RandomBrightnessContrast(p=0.2),
            A.Normalize(),
            ToTensorV2(),
        ])
    else:
        return A.Compose([
            A.SmallestMaxSize(max_size=img_size),
            A.CenterCrop(width=img_size, height=img_size),
            A.Normalize(),
            ToTensorV2(),
        ])


def build_model(model_name='tf_efficientnet_b0', num_classes=2, pretrained=True):
    """Create a model with pretrained weights"""
    model = timm.create_model(model_name, pretrained=pretrained, num_classes=num_classes)
    return model


def export_model(model: nn.Module, output_dir: str, model_name: str, img_size: int = 224):
    """Export model to ONNX and TorchScript formats"""
    os.makedirs(output_dir, exist_ok=True)
    model.eval()
    
    # Create dummy input
    dummy_input = torch.randn(1, 3, img_size, img_size)
    
    # Export to ONNX
    onnx_path = os.path.join(output_dir, f"{model_name}.onnx")
    torch.onnx.export(
        model, 
        dummy_input, 
        onnx_path,
        export_params=True,
        opset_version=12,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
    )
    logger.info(f"Model exported to ONNX: {onnx_path}")
    
    # Export to TorchScript
    script_path = os.path.join(output_dir, f"{model_name}.pt")
    scripted_model = torch.jit.trace(model, dummy_input)
    torch.jit.save(scripted_model, script_path)
    logger.info(f"Model exported to TorchScript: {script_path}")
    
    # Save model metadata
    metadata = {
        "model_name": model_name,
        "img_size": img_size,
        "input_shape": [1, 3, img_size, img_size],
        "framework": "pytorch",
        "export_date": time.strftime("%Y-%m-%d %H:%M:%S")
    }
    
    with open(os.path.join(output_dir, f"{model_name}_metadata.json"), 'w') as f:
        json.dump(metadata, f, indent=2)
    
    return onnx_path, script_path


def train(args):
    """Main training function with MLflow tracking"""
    # Set up MLflow
    mlflow.set_experiment(args.experiment_name)
    
    with mlflow.start_run(run_name=args.run_name) as run:
        # Log parameters
        mlflow.log_params({
            "model": args.model,
            "epochs": args.epochs,
            "batch_size": args.batch_size,
            "learning_rate": args.lr,
            "img_size": args.img_size,
            "num_classes": args.num_classes,
            "pretrained": not args.no_pretrained,
        })
        
        # Set device
        device = 'cuda' if torch.cuda.is_available() and not args.force_cpu else 'cpu'
        logger.info(f"Using device: {device}")
        
        # Create transforms for training and validation
        train_transforms = get_transforms(args.img_size, train=True)
        val_transforms = get_transforms(args.img_size, train=False)
        
        # Load dataset
        full_dataset = ManifestImageDataset(args.manifest, transform=None)
        logger.info(f"Loaded dataset with {len(full_dataset)} samples")
        logger.info(f"Class distribution: {full_dataset.class_counts}")
        
        # Split dataset
        train_dataset, val_dataset, _ = create_data_splits(
            full_dataset, val_size=args.val_size, test_size=0, random_seed=args.seed
        )
        
        # Apply transforms
        train_dataset.dataset.transform = train_transforms
        val_dataset.dataset.transform = val_transforms
        
        logger.info(f"Train set: {len(train_dataset)} samples")
        logger.info(f"Validation set: {len(val_dataset)} samples")
        
        # Create data loaders
        train_loader = DataLoader(
            train_dataset, 
            batch_size=args.batch_size, 
            shuffle=True, 
            num_workers=args.num_workers,
            pin_memory=True
        )
        
        val_loader = DataLoader(
            val_dataset, 
            batch_size=args.batch_size, 
            shuffle=False, 
            num_workers=args.num_workers,
            pin_memory=True
        )
        
        # Build model
        model = build_model(
            args.model, 
            num_classes=args.num_classes, 
            pretrained=not args.no_pretrained
        ).to(device)
        
        # Calculate class weights for imbalanced datasets
        if args.use_class_weights:
            class_weights = full_dataset.get_class_weights().to(device)
            criterion = nn.CrossEntropyLoss(weight=class_weights)
            logger.info(f"Using weighted loss with weights: {class_weights}")
        else:
            criterion = nn.CrossEntropyLoss()
        
        # Optimizer and scheduler
        optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=args.weight_decay)
        scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(
            optimizer, mode='max', factor=0.5, patience=2, verbose=True
        )
        
        # Training loop
        best_val_acc = 0.0
        for epoch in range(1, args.epochs + 1):
            # Train
            model.train()
            epoch_loss = 0.0
            t0 = time.time()
            
            for xb, yb in train_loader:
                xb = xb.to(device)
                yb = yb.to(device)
                
                optimizer.zero_grad()
                preds = model(xb)
                loss = criterion(preds, yb)
                loss.backward()
                optimizer.step()
                
                epoch_loss += loss.item() * xb.size(0)
            
            epoch_loss /= len(train_loader.dataset)
            train_metrics = evaluate(model, train_loader, device=device)
            
            # Validate
            val_metrics = evaluate(model, val_loader, device=device)
            
            # Update LR scheduler
            scheduler.step(val_metrics['accuracy'])
            
            # Log metrics
            mlflow.log_metrics({
                "train_loss": epoch_loss,
                "train_accuracy": train_metrics['accuracy'],
                "val_accuracy": val_metrics['accuracy'],
                "epoch_time": time.time() - t0
            }, step=epoch)
            
            logger.info(f"Epoch {epoch}/{args.epochs} | "
                      f"Train Loss: {epoch_loss:.4f} | "
                      f"Train Acc: {train_metrics['accuracy']:.4f} | "
                      f"Val Acc: {val_metrics['accuracy']:.4f} | "
                      f"Time: {(time.time()-t0):.1f}s")
            
            # Save best model
            if val_metrics['accuracy'] > best_val_acc:
                best_val_acc = val_metrics['accuracy']
                checkpoint_path = save_checkpoint(
                    {
                        'model_state': model.state_dict(),
                        'optimizer_state': optimizer.state_dict(),
                        'epoch': epoch,
                        'val_acc': best_val_acc
                    }, 
                    args.output_dir, 
                    f'best_model.pth'
                )
                mlflow.log_artifact(checkpoint_path)
                logger.info(f"Saved best model with val_acc={best_val_acc:.4f}")
        
        # Final evaluation
        model.load_state_dict(torch.load(os.path.join(args.output_dir, 'best_model.pth'))['model_state'])
        final_val_metrics = evaluate(model, val_loader, device=device)
        
        logger.info(f"Final validation accuracy: {final_val_metrics['accuracy']:.4f}")
        mlflow.log_metrics({
            "final_val_accuracy": final_val_metrics['accuracy'],
        })
        
        # Export model
        if args.export_model:
            export_dir = os.path.join(args.output_dir, "exported")
            onnx_path, script_path = export_model(
                model, export_dir, f"{args.model}_v{int(time.time())}", args.img_size
            )
            mlflow.log_artifact(onnx_path)
            mlflow.log_artifact(script_path)
        
        # Log model to MLflow
        mlflow.pytorch.log_model(model, "model")
        
        return model, final_val_metrics


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('--manifest', required=True, help='CSV manifest with image_path,label')
    p.add_argument('--output-dir', default='./artifacts')
    p.add_argument('--experiment-name', default='crop_diagnostics')
    p.add_argument('--run-name', default=None)
    p.add_argument('--epochs', type=int, default=10)
    p.add_argument('--batch-size', type=int, default=32)
    p.add_argument('--lr', type=float, default=1e-4)
    p.add_argument('--weight-decay', type=float, default=1e-5)
    p.add_argument('--val-size', type=float, default=0.2)
    p.add_argument('--model', default='tf_efficientnet_b0')
    p.add_argument('--img-size', type=int, default=224)
    p.add_argument('--num-classes', type=int, default=2)
    p.add_argument('--num-workers', type=int, default=4)
    p.add_argument('--seed', type=int, default=42)
    p.add_argument('--use-class-weights', action='store_true')
    p.add_argument('--export-model', action='store_true')
    p.add_argument('--no-pretrained', action='store_true')
    p.add_argument('--force-cpu', dest='force_cpu', action='store_true')
    return p.parse_args()


if __name__ == '__main__':
    args = parse_args()
    os.makedirs(args.output_dir, exist_ok=True)
    train(args)
