import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:kheti_sahayak_app/services/network_quality_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCompressionService {
  static Future<File?> compressImage(File file) async {
    final qualityService = NetworkQualityService();
    final shouldCompressAggressively = qualityService.shouldCompressAggressively();
    
    // Target size: < 100KB for low bandwidth, < 500KB for high
    final targetSize = shouldCompressAggressively ? 100 * 1024 : 500 * 1024;
    
    final fileSize = await file.length();
    if (fileSize <= targetSize) {
      return file;
    }

    final dir = await getTemporaryDirectory();
    final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg');

    // Initial quality estimation
    int quality = shouldCompressAggressively ? 70 : 85;
    
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: 1024,
      minHeight: 1024,
    );
    
    // If still too big, compress more aggressively
    if (result != null && await result.length() > targetSize) {
      quality = shouldCompressAggressively ? 50 : 70;
      result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 800,
        minHeight: 800,
      );
    }

    return result != null ? File(result.path) : file;
  }
}
