Minimal ML training scaffold for Crop Diagnostics

Contents
- `requirements.txt` — Python deps for quick experiments
- `train.py` — training entrypoint (data loader, model, training loop, eval, checkpoint)
- `dataset.py` — small manifest-based Dataset (CSV with image_path,label)
- `utils.py` — metrics and helpers
- `Dockerfile` — lightweight image to run training experiments

Quick start
1. Create a Python venv and install deps:
   pip install -r requirements.txt
2. Prepare a manifest CSV with columns `image_path,label` (absolute paths or paths relative to working dir)
3. Run a short smoke training:
   python train.py --manifest data/manifest.csv --output-dir ./artifacts --epochs 2 --batch-size 32

Notes
- This scaffold is intentionally minimal and focused on transfer-learning using `timm` models. Extend augmentation, logging (W&B), DVC integration and hyperparameter tuning as required by the PRD.
