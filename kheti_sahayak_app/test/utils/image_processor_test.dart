import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/utils/image_processor.dart';
import '../test_helpers/mock_image.dart';

void main() {
  late File testImageFile;
  
  // Setup before each test
  setUp(() async {
    testImageFile = await createTempImageFile(width: 800, height: 600);
  });
  
  // Clean up after each test
  tearDown(() async {
    if (await testImageFile.exists()) {
      await testImageFile.delete();
    }
  });

  group('ImageProcessor', () {
    test('should validate image format', () async {
      // Test with valid image
      bool isValid = await ImageProcessor.isValidImageFormat(testImageFile);
      expect(isValid, isTrue);

      // Test with invalid file (text file)
      final tempFile = File('${testImageFile.path}.txt');
      await tempFile.writeAsString('This is not an image');
      
      isValid = await ImageProcessor.isValidImageFormat(tempFile);
      expect(isValid, isFalse);
      
      // Clean up
      await tempFile.delete();
    });
    
    test('should validate image size', () async {
      // Test with valid size
      bool isValid = await ImageProcessor.isValidImageSize(testImageFile, maxSizeMB: 2);
      expect(isValid, isTrue);
      
      // Test with invalid size (too large)
      isValid = await ImageProcessor.isValidImageSize(testImageFile, maxSizeMB: 0.0001);
      expect(isValid, isFalse);
    });
    
    test('should resize image', () async {
      final resized = await ImageProcessor.resizeImage(
        testImageFile,
        maxWidth: 400,
        maxHeight: 400,
      );
      
      final dimensions = await ImageProcessor.getImageDimensions(resized);
      expect(dimensions['width'], lessThanOrEqualTo(400));
      expect(dimensions['height'], lessThanOrEqualTo(400));
      
      // Clean up
      await resized.delete();
    });
    
    test('should compress image', () async {
      final originalSize = await testImageFile.length();
      final compressedFile = await ImageProcessor.compressImage(
        testImageFile,
        quality: 50,
      );
      
      final compressedSize = await compressedFile.length();
      expect(compressedSize, lessThan(originalSize));
      
      // Clean up
      await compressedFile.delete();
    });

    test('should resize image while maintaining aspect ratio', () async {
      // Resize to 400x300 (maintaining 4:3 aspect ratio)
      final resizedFile = await ImageProcessor.resizeImage(
        testImageFile,
        maxWidth: 400,
        maxHeight: 400,
      );
      
      // Verify the image was resized correctly
      final dimensions = await ImageProcessor.getImageDimensions(resizedFile);
      expect(dimensions['width'], lessThanOrEqualTo(400));
      expect(dimensions['height'], lessThanOrEqualTo(400));
      
      // Clean up
      await resizedFile.delete();
    });

    test('should handle invalid image files', () async {
      // Create a corrupted image file
      final corruptedFile = File('${testImageFile.path}.corrupted');
      await corruptedFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]); // PNG header but with .jpg extension
      
      // Test format validation
      bool isValid = await ImageProcessor.isValidImageFormat(corruptedFile);
      expect(isValid, isFalse);
      
      // Test resize with invalid image
      expect(
        () => ImageProcessor.resizeImage(corruptedFile, maxWidth: 100),
        throwsA(isA<FormatException>()),
      );
      
      // Clean up
      await corruptedFile.delete();
    });
  });

  group('ImageProcessor - Edge Cases', () {
    test('should handle minimum dimensions', () async {
      // Create a very small image
      final smallImageFile = await createTempImageFile(width: 10, height: 10);
      
      // Try to resize to larger dimensions
      final resized = await ImageProcessor.resizeImage(
        smallImageFile,
        maxWidth: 100,
        maxHeight: 100,
      );
      
      // Clean up
      await smallImageFile.delete();
      await resized.delete();
    });

    test('should handle maximum file size', () async {
      // Create a large image file
      final largeFile = await createTempImageFile(width: 2000, height: 2000);
      
      // Test with a small size limit
      bool isValid = await ImageProcessor.isValidImageSize(
        largeFile, 
        maxSizeMB: 0.1
      );
      expect(isValid, false);
      
      // Clean up
      await largeFile.delete();
    });
    
    test('should handle base64 encoding', () async {
      final base64String = await ImageProcessor.toBase64(testImageFile);
      expect(base64String, isNotEmpty);
      expect(base64String.length, greaterThan(100)); // Basic check that we have some data
    });
    
    test('should create thumbnail', () async {
      final thumbnail = await ImageProcessor.createThumbnail(
        testImageFile,
        width: 100,
        height: 100,
      );
      
      final dimensions = await ImageProcessor.getImageDimensions(thumbnail);
      expect(dimensions['width'], lessThanOrEqualTo(100));
      expect(dimensions['height'], lessThanOrEqualTo(100));
      
      // Clean up
      await thumbnail.delete();
    });
  });
}
