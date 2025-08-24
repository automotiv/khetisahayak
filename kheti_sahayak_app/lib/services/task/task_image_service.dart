import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../models/task/task_image.dart';
import '../../utils/logger.dart';
import '../task/image_picker_adapter.dart';
import '../task/permission_adapter.dart';
import '../../utils/image_processor.dart';
import 'ingest_client.dart';
import 'upload_queue.dart';

class TaskImageService {
  static const int maxImageSizeMB = 10; // 10MB max file size
  static const int maxImageWidth = 4096; // Max image width in pixels
  static const int maxImageHeight = 4096; // Max image height in pixels
  static const int maxImagesPerTask = 5; // Maximum number of images per task
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  final ImagePickerAdapter _imagePickerAdapter;
  final PermissionAdapter _permissionAdapter;

  TaskImageService({ImagePickerAdapter? imagePickerAdapter, PermissionAdapter? permissionAdapter})
      : _imagePickerAdapter = imagePickerAdapter ?? ImagePickerAdapterImpl(),
        _permissionAdapter = permissionAdapter ?? PermissionAdapterImpl();

  /// Request gallery permission
  Future<bool> requestGalleryPermission() async {
    try {
      final photosStatus = await _permissionAdapter.status(Permission.photos);
      if (photosStatus.isGranted) return true;

      final storageStatus = await _permissionAdapter.status(Permission.storage);
      if (storageStatus.isGranted) return true;

      final req = await _permissionAdapter.request(Permission.photos);
      return req.isGranted;
    } catch (e) {
      AppLogger.error('Error requesting gallery permission', e);
      return false;
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await _permissionAdapter.status(Permission.camera);
      if (status.isDenied) {
        final result = await _permissionAdapter.request(Permission.camera);
        return result.isGranted;
      }
      return status.isGranted;
    } catch (e) {
      AppLogger.error('Error requesting camera permission', e);
      return false;
    }
  }

  /// Pick multiple images from gallery
  Future<List<TaskImage>> pickImages({
    int maxImages = 5,
    bool allowMultiple = true,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Choose permission flow based on source
      if (source == ImageSource.camera) {
        final hasCamera = await requestCameraPermission();
        if (!hasCamera) throw Exception('Camera permission not granted');

        final XFile? captured = await _imagePickerAdapter.pickImage(
          source: ImageSource.camera,
          maxWidth: maxImageWidth.toDouble(),
          maxHeight: maxImageHeight.toDouble(),
          imageQuality: 85,
        );

        if (captured == null) return [];

        try {
          final processed = await _processImageFile(captured);
          return [processed];
        } catch (e) {
          AppLogger.error('Error processing captured image', e);
          return [];
        }
      }

      // Gallery flow
      final hasPermission = await requestGalleryPermission();
      if (!hasPermission) {
        throw Exception('Gallery permission not granted');
      }

  final List<XFile>? pickedFiles = await _imagePickerAdapter.pickMultiImage(
        maxWidth: maxImageWidth.toDouble(),
        maxHeight: maxImageHeight.toDouble(),
        imageQuality: 85,
      );

      if (pickedFiles == null || pickedFiles.isEmpty) return [];

      // Limit the number of images
      final limitedFiles = pickedFiles.take(maxImages).toList();

      // Convert to TaskImage list
      final List<TaskImage> taskImages = [];

      for (final file in limitedFiles) {
        try {
          final taskImage = await _processImageFile(file);
          taskImages.add(taskImage);
        } catch (e) {
          AppLogger.error('Error processing image: ${file.path}', e);
          // Continue with other images even if one fails
        }
      }

      return taskImages;
    } catch (e) {
      AppLogger.error('Error picking images', e);
      rethrow;
    }
  }

  /// Process and validate an image file
  Future<TaskImage> _processImageFile(XFile xFile) async {
    // Convert XFile to File
    final file = File(xFile.path);
    
    // Check file size
    final fileSize = await file.length();
    if (fileSize > maxImageSizeMB * 1024 * 1024) {
      throw Exception('Image size exceeds maximum allowed size of ${maxImageSizeMB}MB');
    }

    // Validate image format
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) {
      throw Exception('Invalid image format');
    }

    // Validate dimensions
    if (image.width > maxImageWidth || image.height > maxImageHeight) {
      throw Exception('Image dimensions exceed maximum allowed size of ${maxImageWidth}x${maxImageHeight}');
    }

    // Create a thumbnail (optional, can be done later when needed)
    // final thumbnail = await _createThumbnail(file);

    return TaskImage.fromFile(file);
  }

  /// Create a thumbnail from an image file
  Future<File> _createThumbnail(File originalFile, {int width = 200, int height = 200}) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate aspect ratio
      final aspectRatio = image.width / image.height;
      int targetWidth, targetHeight;
      
      if (aspectRatio > 1) {
        // Landscape
        targetWidth = width;
        targetHeight = (width / aspectRatio).round();
      } else {
        // Portrait or square
        targetHeight = height;
        targetWidth = (height * aspectRatio).round();
      }

      // Resize image
      final thumbnail = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
      );

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final thumbnailFile = File('${tempDir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await thumbnailFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 80));
      
      return thumbnailFile;
    } catch (e) {
      AppLogger.error('Error creating thumbnail', e);
      rethrow;
    }
  }

  /// Compress an image file to reduce size
  Future<File> compressImage(File file, {int quality = 85}) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Get the file extension
      final ext = path.extension(file.path).toLowerCase();
      
      // Encode the image with the specified quality
      List<int> compressedBytes;
      if (ext == '.png') {
        compressedBytes = img.encodePng(image, level: (100 - quality) ~/ 10);
      } else if (ext == '.jpg' || ext == '.jpeg') {
        compressedBytes = img.encodeJpg(image, quality: quality);
      } else {
        // For other formats, just return the original
        return file;
      }

      // Save to a temporary file
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}$ext');
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      AppLogger.error('Error compressing image', e);
      // Return original file if compression fails
      return file;
    }
  }

  /// Upload an image file using presigned S3 URL flow
  Future<Map<String, dynamic>> uploadImageViaPresign(File file, {bool keepLocation = false}) async {
    try {
      final bytes = await file.readAsBytes();
      final contentType = _detectMimeType(file.path);
      final filename = path.basename(file.path);

      final presign = await IngestClient.presign(filename, contentType);
      final uploadUrl = presign['uploadUrl'] as String;
      final key = presign['key'] as String;

      // Upload to presigned URL
      await IngestClient.uploadToUrl(uploadUrl, bytes, contentType);

      // Finalize ingest on server (strip EXIF by default)
      final result = await IngestClient.finalize(key, keepLocation: keepLocation);
      return result;
    } catch (e) {
      AppLogger.error('Presigned upload failed, enqueuing for retry', e);
      try {
        await UploadQueue.enqueue(file, keepLocation: keepLocation);
      } catch (queueErr) {
        AppLogger.error('Failed to enqueue upload', queueErr);
      }
      // Return a minimal object so caller can continue; it indicates queued status
      return {'queued': true, 'path': file.path};
    }
  }

  String _detectMimeType(String p) {
    final ext = path.extension(p).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg') return 'image/jpeg';
    if (ext == '.png') return 'image/png';
    if (ext == '.webp') return 'image/webp';
    return 'application/octet-stream';
  }
}
