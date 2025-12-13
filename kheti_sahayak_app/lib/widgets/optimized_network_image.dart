import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/services/network_quality_service.dart';

class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? placeholderAsset;
  final bool forceHighQuality;

  const OptimizedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderAsset,
    this.forceHighQuality = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkQuality>(
      stream: NetworkQualityService().qualityStream,
      initialData: NetworkQualityService().currentQuality,
      builder: (context, snapshot) {
        final quality = snapshot.data ?? NetworkQuality.medium;
        
        // Logic to determine if we should load image
        // For extremely low bandwidth, we might want to show a placeholder with a "Tap to load" option
        // For now, we'll just optimize memory cache size
        
        int? memCacheWidth;
        int? memCacheHeight;
        
        if (width != null && width != double.infinity) {
          memCacheWidth = (width! * (quality == NetworkQuality.high ? 2 : 1)).toInt();
        }
        
        if (height != null && height != double.infinity) {
          memCacheHeight = (height! * (quality == NetworkQuality.high ? 2 : 1)).toInt();
        }

        return CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
    );
  }
}
