# ML Model Assets

This directory contains the machine learning model for offline crop disease detection.

## Files

| File | Description | Status |
|------|-------------|--------|
| `labels.txt` | Disease classification labels | Ready |
| `crop_disease_lite.tflite` | TFLite model (not included) | Pending |

## Model Requirements

| Requirement | Target |
|-------------|--------|
| Model size | <25 MB |
| Inference time | <3 seconds |
| Accuracy | >80% |
| Input size | 224x224 RGB |
| Output | 15 class probabilities |

## Supported Diseases

1. healthy
2. bacterial_blight
3. fungal_rust
4. leaf_spot
5. powdery_mildew
6. early_blight
7. late_blight
8. mosaic_virus
9. septoria_leaf_spot
10. target_spot
11. yellow_curl_virus
12. anthracnose
13. downy_mildew
14. cercospora_leaf_spot
15. alternaria_leaf_spot

## Creating the TFLite Model

### Option 1: Convert existing TensorFlow model

```python
import tensorflow as tf

# Load your trained model
model = tf.keras.models.load_model('crop_disease_model.h5')

# Convert with quantization
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]

tflite_model = converter.convert()

# Save
with open('crop_disease_lite.tflite', 'wb') as f:
    f.write(tflite_model)
```

### Option 2: Use Transfer Learning

```python
import tensorflow as tf

# Base model
base_model = tf.keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights='imagenet'
)

# Add classification head
model = tf.keras.Sequential([
    base_model,
    tf.keras.layers.GlobalAveragePooling2D(),
    tf.keras.layers.Dense(256, activation='relu'),
    tf.keras.layers.Dropout(0.5),
    tf.keras.layers.Dense(15, activation='softmax')  # 15 classes
])

# Train on your dataset...
# Then convert to TFLite
```

## Adding Model to Project

1. Place `crop_disease_lite.tflite` in this directory
2. Ensure pubspec.yaml includes:
   ```yaml
   flutter:
     assets:
       - assets/ml/
   ```
3. Add tflite_flutter dependency:
   ```yaml
   dependencies:
     tflite_flutter: ^0.10.0
   ```

## Testing the Model

```dart
import 'services/offline_ml_service.dart';

final mlService = OfflineMLService.instance;
await mlService.initialize();

final predictions = await mlService.predict(imageFile);
for (final p in predictions) {
  print('${p.displayName}: ${p.confidencePercent}');
}
```

## Mock Mode

If the TFLite model is not available, the service will use mock predictions for development and testing purposes.
