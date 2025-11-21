import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// Offline ML Service for Crop Disease Detection
///
/// This service provides offline crop disease diagnosis using TFLite.
///
/// Setup Instructions:
/// 1. Add tflite_flutter to pubspec.yaml:
///    ```yaml
///    dependencies:
///      tflite_flutter: ^0.10.0
///    ```
/// 2. Place the TFLite model at: assets/ml/crop_disease_lite.tflite
/// 3. Ensure labels.txt is at: assets/ml/labels.txt
/// 4. Add assets to pubspec.yaml:
///    ```yaml
///    flutter:
///      assets:
///        - assets/ml/
///    ```
///
/// For development, this uses mock predictions until model is available.
class OfflineMLService {
  static OfflineMLService? _instance;
  static OfflineMLService get instance {
    _instance ??= OfflineMLService._();
    return _instance!;
  }

  OfflineMLService._();

  // TFLite Interpreter - uncomment when tflite_flutter is added
  // late Interpreter _interpreter;

  List<String> _labels = [];
  bool _isInitialized = false;
  bool _modelLoaded = false;

  // Model input/output specifications
  static const int inputSize = 224;
  static const int numChannels = 3;
  static const int numClasses = 15;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if model is loaded
  bool get isModelLoaded => _modelLoaded;

  /// Initialize the ML service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load labels
      await _loadLabels();

      // Try to load model
      await _loadModel();

      _isInitialized = true;
      print('OfflineMLService initialized');
    } catch (e) {
      print('Error initializing OfflineMLService: $e');
      _isInitialized = true; // Mark as initialized even if model fails (use mock)
    }
  }

  /// Load disease labels from assets
  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelsData.split('\n').where((l) => l.trim().isNotEmpty).toList();
      print('Loaded ${_labels.length} labels');
    } catch (e) {
      print('Error loading labels: $e');
      // Fallback labels
      _labels = [
        'healthy',
        'bacterial_blight',
        'fungal_rust',
        'leaf_spot',
        'powdery_mildew',
        'early_blight',
        'late_blight',
        'mosaic_virus',
        'septoria_leaf_spot',
        'target_spot',
        'yellow_curl_virus',
        'anthracnose',
        'downy_mildew',
        'cercospora_leaf_spot',
        'alternaria_leaf_spot',
      ];
    }
  }

  /// Load TFLite model from assets
  Future<void> _loadModel() async {
    try {
      // Check if model file exists
      final modelPath = 'assets/ml/crop_disease_lite.tflite';

      // In production, load actual TFLite model:
      // _interpreter = await Interpreter.fromAsset(modelPath);
      // _modelLoaded = true;

      // For now, use mock mode
      _modelLoaded = false;
      print('TFLite model not available, using mock predictions');
    } catch (e) {
      print('Error loading TFLite model: $e');
      _modelLoaded = false;
    }
  }

  /// Run inference on an image file
  Future<List<Prediction>> predict(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_modelLoaded) {
      // Use mock predictions for development
      return _mockPredictions();
    }

    try {
      // Read and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final input = await _preprocessImage(imageBytes);

      // Run inference
      final output = List<double>.filled(numClasses, 0);

      // In production:
      // _interpreter.run(input, output);

      // Convert to predictions
      return _processOutput(output);
    } catch (e) {
      print('Error during prediction: $e');
      return _mockPredictions();
    }
  }

  /// Run inference on image bytes
  Future<List<Prediction>> predictFromBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_modelLoaded) {
      return _mockPredictions();
    }

    try {
      final input = await _preprocessImage(imageBytes);
      final output = List<double>.filled(numClasses, 0);

      // In production:
      // _interpreter.run(input, output);

      return _processOutput(output);
    } catch (e) {
      print('Error during prediction: $e');
      return _mockPredictions();
    }
  }

  /// Preprocess image for model input
  Future<List<List<List<List<double>>>>> _preprocessImage(Uint8List imageBytes) async {
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to model input size
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Convert to normalized float array [1, 224, 224, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  /// Process model output to predictions
  List<Prediction> _processOutput(List<double> output) {
    // Apply softmax
    final maxVal = output.reduce(max);
    final expValues = output.map((e) => exp(e - maxVal)).toList();
    final sumExp = expValues.reduce((a, b) => a + b);
    final probabilities = expValues.map((e) => e / sumExp).toList();

    // Create predictions with labels
    final predictions = <Prediction>[];
    for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
      predictions.add(Prediction(
        label: _labels[i],
        confidence: probabilities[i],
        index: i,
      ));
    }

    // Sort by confidence and return top 5
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions.take(5).toList();
  }

  /// Generate mock predictions for development
  List<Prediction> _mockPredictions() {
    final random = Random();

    // Generate random confidences
    final confidences = List.generate(_labels.length, (_) => random.nextDouble());
    final total = confidences.reduce((a, b) => a + b);
    final normalized = confidences.map((c) => c / total).toList();

    final predictions = <Prediction>[];
    for (int i = 0; i < normalized.length; i++) {
      predictions.add(Prediction(
        label: _labels[i],
        confidence: normalized[i],
        index: i,
        isMock: true,
      ));
    }

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Simulate some processing delay
    return predictions.take(5).toList();
  }

  /// Get human-readable disease name
  String getDiseaseName(String label) {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  /// Get treatment recommendations for a disease
  Map<String, dynamic> getTreatmentInfo(String label) {
    final treatments = _diseaseInfo[label];
    if (treatments != null) {
      return treatments;
    }
    return {
      'description': 'Unknown condition. Please consult an agricultural expert.',
      'treatments': ['Consult local agricultural extension office'],
      'prevention': ['Regular crop monitoring', 'Maintain plant health'],
    };
  }

  /// Dispose resources
  void dispose() {
    // In production:
    // _interpreter.close();
    _isInitialized = false;
    _modelLoaded = false;
  }

  // Disease information database
  static final Map<String, Map<String, dynamic>> _diseaseInfo = {
    'healthy': {
      'description': 'The plant appears healthy with no visible disease symptoms.',
      'treatments': ['No treatment required'],
      'prevention': ['Maintain good agricultural practices', 'Regular monitoring'],
    },
    'bacterial_blight': {
      'description': 'Bacterial infection causing water-soaked lesions on leaves.',
      'treatments': [
        'Apply copper-based bactericides',
        'Remove and destroy infected plants',
        'Use disease-free seeds',
      ],
      'prevention': [
        'Use resistant varieties',
        'Avoid overhead irrigation',
        'Crop rotation',
      ],
    },
    'fungal_rust': {
      'description': 'Fungal disease causing rust-colored pustules on leaves.',
      'treatments': [
        'Apply fungicides (triadimefon, propiconazole)',
        'Remove heavily infected leaves',
      ],
      'prevention': [
        'Plant resistant varieties',
        'Ensure good air circulation',
        'Avoid excessive nitrogen fertilization',
      ],
    },
    'leaf_spot': {
      'description': 'Circular spots on leaves caused by various pathogens.',
      'treatments': [
        'Apply appropriate fungicide',
        'Remove infected leaves',
        'Improve drainage',
      ],
      'prevention': [
        'Avoid overhead watering',
        'Space plants properly',
        'Remove plant debris',
      ],
    },
    'powdery_mildew': {
      'description': 'White powdery coating on leaves caused by fungal infection.',
      'treatments': [
        'Apply sulfur-based fungicide',
        'Use neem oil spray',
        'Apply potassium bicarbonate solution',
      ],
      'prevention': [
        'Ensure good air circulation',
        'Avoid overcrowding plants',
        'Water at soil level, not on leaves',
      ],
    },
    'early_blight': {
      'description': 'Fungal disease causing concentric ring patterns on leaves.',
      'treatments': [
        'Apply chlorothalonil or mancozeb fungicide',
        'Remove lower infected leaves',
      ],
      'prevention': [
        'Crop rotation (3-4 years)',
        'Use mulch to prevent soil splash',
        'Stake plants for better air flow',
      ],
    },
    'late_blight': {
      'description': 'Serious disease causing water-soaked lesions and white mold.',
      'treatments': [
        'Apply copper fungicide immediately',
        'Remove and destroy all infected plants',
        'Apply systemic fungicides',
      ],
      'prevention': [
        'Plant certified disease-free stock',
        'Avoid overhead irrigation',
        'Destroy volunteer plants',
      ],
    },
  };
}

/// Represents a single prediction result
class Prediction {
  final String label;
  final double confidence;
  final int index;
  final bool isMock;

  Prediction({
    required this.label,
    required this.confidence,
    required this.index,
    this.isMock = false,
  });

  /// Get confidence as percentage
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Get human-readable label
  String get displayName => OfflineMLService.instance.getDiseaseName(label);

  Map<String, dynamic> toJson() => {
    'label': label,
    'confidence': confidence,
    'confidencePercent': confidencePercent,
    'displayName': displayName,
    'isMock': isMock,
  };
}
