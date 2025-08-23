import 'dart:io';
import 'dart:typed_data';

/// Creates a temporary image file for testing
Future<File> createTempImageFile({
  int width = 100, 
  int height = 100, 
  String? path,
}) async {
  final tempDir = Directory.systemTemp;
  final file = File(path ?? '${tempDir.path}/test_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
  
  // Create a simple colored image (RGBA format)
  final bytes = Uint8List(width * height * 4);
  for (int i = 0; i < bytes.length; i += 4) {
    bytes[i] = 255;     // R
    bytes[i + 1] = 0;   // G
    bytes[i + 2] = 0;   // B
    bytes[i + 3] = 255; // A
  }
  
  await file.writeAsBytes(bytes);
  return file;
}
