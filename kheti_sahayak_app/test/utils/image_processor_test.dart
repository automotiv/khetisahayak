// import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/utils/image_processor.dart';

void main() {
  group('ImageProcessor', () {
    test('should be instantiable', () {
      final processor = ImageProcessor();
      expect(processor, isNotNull);
    });
  });
}
