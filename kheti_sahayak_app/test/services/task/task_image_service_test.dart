import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/services/task/task_image_service.dart';
import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart';

// Mock classes would go here if we were doing full isolation testing
// For this task, we'll focus on the logic we can test without heavy mocking of native channels

void main() {
  group('TaskImageService Constants', () {
    test('should have correct max image size', () {
      expect(TaskImageService.maxImageSizeMB, 10);
    });

    test('should have correct max dimensions', () {
      expect(TaskImageService.maxImageWidth, 4096);
      expect(TaskImageService.maxImageHeight, 4096);
    });

    test('should have correct min dimensions', () {
      expect(TaskImageService.minImageWidth, 800);
      expect(TaskImageService.minImageHeight, 600);
    });

    test('should have correct max images per task', () {
      expect(TaskImageService.maxImagesPerTask, 5);
    });

    test('should have correct allowed mime types', () {
      expect(TaskImageService.allowedMimeTypes, contains('image/jpeg'));
      expect(TaskImageService.allowedMimeTypes, contains('image/png'));
      expect(TaskImageService.allowedMimeTypes, contains('image/webp'));
    });
  });
}
