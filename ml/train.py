import argparse
import os
import time

import torch
import timm
from torch import nn
from torch.utils.data import DataLoader
import albumentations as A
from albumentations.pytorch import ToTensorV2

from dataset import ManifestImageDataset
from utils import save_checkpoint, evaluate


def get_transforms(img_size=224):
    return A.Compose([
        A.SmallestMaxSize(max_size=img_size),
        A.RandomCrop(width=img_size, height=img_size),
        A.HorizontalFlip(p=0.5),
        A.RandomBrightnessContrast(p=0.2),
        A.Normalize(),
    ])


def build_model(model_name='tf_efficientnet_b0', num_classes=2, pretrained=True):
    model = timm.create_model(model_name, pretrained=pretrained, num_classes=num_classes)
    return model


def train(args):
    device = 'cuda' if torch.cuda.is_available() and not args.force_cpu else 'cpu'
    transforms = get_transforms(args.img_size)
    train_ds = ManifestImageDataset(args.manifest, transform=transforms)
    train_loader = DataLoader(train_ds, batch_size=args.batch_size, shuffle=True, num_workers=4)

    model = build_model(args.model, num_classes=args.num_classes, pretrained=not args.no_pretrained).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr)

    best_acc = 0.0
    for epoch in range(1, args.epochs + 1):
        model.train()
        epoch_loss = 0.0
        t0 = time.time()
        for xb, yb in train_loader:
            xb = xb.to(device)
            yb = yb.to(device)
            preds = model(xb)
            loss = criterion(preds, yb)
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item() * xb.size(0)
        epoch_loss /= len(train_loader.dataset)
        metrics = evaluate(model, train_loader, device=device)
        print(f"Epoch {epoch}/{args.epochs} loss={epoch_loss:.4f} acc={metrics['accuracy']:.4f} time={(time.time()-t0):.1f}s")
        if metrics['accuracy'] > best_acc:
            best_acc = metrics['accuracy']
            save_checkpoint({'model_state': model.state_dict(), 'epoch': epoch, 'acc': best_acc}, args.output_dir, f'best_epoch_{epoch}.pth')


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('--manifest', required=True, help='CSV manifest with image_path,label')
    p.add_argument('--output-dir', default='./artifacts')
    p.add_argument('--epochs', type=int, default=5)
    p.add_argument('--batch-size', type=int, default=32)
    p.add_argument('--lr', type=float, default=1e-4)
    p.add_argument('--model', default='tf_efficientnet_b0')
    p.add_argument('--img-size', type=int, default=224)
    p.add_argument('--num-classes', type=int, default=2)
    p.add_argument('--no-pretrained', action='store_true')
    p.add_argument('--force-cpu', dest='force_cpu', action='store_true')
    return p.parse_args()


if __name__ == '__main__':
    args = parse_args()
    os.makedirs(args.output_dir, exist_ok=True)
    train(args)
