import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageProcessor {
  /// Validates if the file is a valid image format
  static Future<bool> isValidImageFormat(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  /// Validates if the image size is within the specified limit
  static Future<bool> isValidImageSize(File file, {required double maxSizeMB}) async {
    final sizeInBytes = await file.length();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return sizeInMB <= maxSizeMB;
  }

  /// Resizes an image while maintaining aspect ratio
  static Future<File> resizeImage(
    File file, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw FormatException('Invalid image file');
    }

    // Calculate new dimensions while maintaining aspect ratio
    int newWidth = image.width;
    int newHeight = image.height;
    
    if (maxWidth != null && image.width > maxWidth) {
      final ratio = maxWidth / image.width;
      newWidth = maxWidth;
      newHeight = (image.height * ratio).round();
    }
    
    if (maxHeight != null && newHeight > maxHeight) {
      final ratio = maxHeight / newHeight;
      newHeight = maxHeight;
      newWidth = (newWidth * ratio).round();
    }
    
    // Resize the image
    final resizedImage = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
    );
    
    // Save to a temporary file
    final directory = await getTemporaryDirectory();
    final outputPath = path.join(
      directory.path,
      'resized_${path.basename(file.path)}',
    );
    
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodeJpg(resizedImage));
    
    return outputFile;
  }

  /// Compresses an image with the specified quality
  static Future<File> compressImage(
    File file, {
    int quality = 80,
  }) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw FormatException('Invalid image file');
    }
    
    // Encode with specified quality
    final compressedBytes = img.encodeJpg(image, quality: quality);
    
    // Save to a temporary file
    final directory = await getTemporaryDirectory();
    final outputPath = path.join(
      directory.path,
      'compressed_${path.basename(file.path)}',
    );
    
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(compressedBytes);
    
    return outputFile;
  }

  /// Gets image dimensions
  static Future<Map<String, int>> getImageDimensions(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw FormatException('Invalid image file');
    }
    
    return {
      'width': image.width,
      'height': image.height,
    };
  }

  /// Converts image to base64 string
  static Future<String> toBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Creates a thumbnail of the image
  static Future<File> createThumbnail(
    File file, {
    int width = 200,
    int height = 200,
  }) async {
    return await resizeImage(file, maxWidth: width, maxHeight: height);
  }
}
