import io
from typing import List, Tuple, Optional
import numpy as np
import cv2
from PIL import Image


IMAGENET_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
IMAGENET_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


def decode_image_bytes(image_bytes: bytes) -> Optional[np.ndarray]:
    try:
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if image is not None:
            return cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        pil_image = Image.open(io.BytesIO(image_bytes))
        pil_image = pil_image.convert('RGB')
        return np.array(pil_image)
    except Exception:
        return None


def resize_image(image: np.ndarray, target_size: Tuple[int, int] = (224, 224)) -> np.ndarray:
    return cv2.resize(image, target_size, interpolation=cv2.INTER_LINEAR)


def normalize_image(image: np.ndarray, mean: np.ndarray = IMAGENET_MEAN, std: np.ndarray = IMAGENET_STD) -> np.ndarray:
    image = image.astype(np.float32) / 255.0
    image = (image - mean) / std
    return image


def to_chw_format(image: np.ndarray) -> np.ndarray:
    return image.transpose(2, 0, 1)


def add_batch_dimension(image: np.ndarray) -> np.ndarray:
    return np.expand_dims(image, axis=0)


def preprocess_image(
    image_bytes: bytes,
    target_size: Tuple[int, int] = (224, 224),
    normalize: bool = True
) -> Optional[np.ndarray]:
    image = decode_image_bytes(image_bytes)
    if image is None:
        return None
    
    if len(image.shape) == 2:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    elif image.shape[2] == 4:
        image = cv2.cvtColor(image, cv2.COLOR_RGBA2RGB)
    
    image = resize_image(image, target_size)
    
    if normalize:
        image = normalize_image(image)
    
    image = to_chw_format(image)
    image = add_batch_dimension(image)
    
    return image.astype(np.float32)


def preprocess_for_display(
    image_bytes: bytes,
    target_size: Tuple[int, int] = (224, 224)
) -> Optional[np.ndarray]:
    image = decode_image_bytes(image_bytes)
    if image is None:
        return None
    
    return resize_image(image, target_size)


def augment_for_tta(image: np.ndarray, num_augmentations: int = 5) -> List[np.ndarray]:
    augmented_images = [image.copy()]
    
    augmented_images.append(np.fliplr(image).copy())
    
    for angle in [90, 180, 270]:
        if len(augmented_images) >= num_augmentations:
            break
        k = angle // 90
        rotated = np.rot90(image, k=k).copy()
        augmented_images.append(rotated)
    
    return augmented_images[:num_augmentations]


def preprocess_batch_for_tta(
    image_bytes: bytes,
    target_size: Tuple[int, int] = (224, 224),
    num_augmentations: int = 5
) -> Optional[np.ndarray]:
    image = decode_image_bytes(image_bytes)
    if image is None:
        return None
    
    if len(image.shape) == 2:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    elif image.shape[2] == 4:
        image = cv2.cvtColor(image, cv2.COLOR_RGBA2RGB)
    
    image = resize_image(image, target_size)
    
    augmented = augment_for_tta(image, num_augmentations)
    
    batch = []
    for aug_image in augmented:
        normalized = normalize_image(aug_image)
        chw = to_chw_format(normalized)
        batch.append(chw)
    
    return np.stack(batch, axis=0).astype(np.float32)


def apply_center_crop(
    image: np.ndarray,
    crop_ratio: float = 0.875
) -> np.ndarray:
    height, width = image.shape[:2]
    crop_height = int(height * crop_ratio)
    crop_width = int(width * crop_ratio)
    
    start_y = (height - crop_height) // 2
    start_x = (width - crop_width) // 2
    
    return image[start_y:start_y + crop_height, start_x:start_x + crop_width]


def preprocess_with_center_crop(
    image_bytes: bytes,
    target_size: Tuple[int, int] = (224, 224),
    resize_size: Tuple[int, int] = (256, 256)
) -> Optional[np.ndarray]:
    image = decode_image_bytes(image_bytes)
    if image is None:
        return None
    
    if len(image.shape) == 2:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    elif image.shape[2] == 4:
        image = cv2.cvtColor(image, cv2.COLOR_RGBA2RGB)
    
    image = resize_image(image, resize_size)
    
    crop_ratio = target_size[0] / resize_size[0]
    image = apply_center_crop(image, crop_ratio)
    
    image = normalize_image(image)
    image = to_chw_format(image)
    image = add_batch_dimension(image)
    
    return image.astype(np.float32)


def validate_image_bytes(image_bytes: bytes) -> Tuple[bool, str]:
    if len(image_bytes) == 0:
        return False, "Empty image data"
    
    if len(image_bytes) > 50 * 1024 * 1024:
        return False, "Image too large (max 50MB)"
    
    image = decode_image_bytes(image_bytes)
    if image is None:
        return False, "Invalid image format"
    
    height, width = image.shape[:2]
    if height < 32 or width < 32:
        return False, "Image too small (min 32x32)"
    
    if height > 10000 or width > 10000:
        return False, "Image dimensions too large (max 10000x10000)"
    
    return True, "Valid image"


def get_image_info(image_bytes: bytes) -> dict:
    image = decode_image_bytes(image_bytes)
    if image is None:
        return {"valid": False, "error": "Could not decode image"}
    
    height, width = image.shape[:2]
    channels = image.shape[2] if len(image.shape) > 2 else 1
    
    return {
        "valid": True,
        "width": width,
        "height": height,
        "channels": channels,
        "size_bytes": len(image_bytes),
        "aspect_ratio": round(width / height, 2)
    }
