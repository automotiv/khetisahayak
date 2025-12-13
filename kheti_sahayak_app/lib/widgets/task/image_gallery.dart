import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../models/task/task_image.dart';
import '../../widgets/optimized_network_image.dart';

class ImageGallery extends StatefulWidget {
  final List<TaskImage> images;
  final Function(int)? onRemove;
  final Function(int)? onReplace;
  final Function(int)? onEdit;
  final Function()? onAddMore;
  final int maxImages;
  final bool canEdit;
  final double imageSize;
  final double spacing;
  final int imagesPerRow;

  const ImageGallery({
    Key? key,
    required this.images,
    this.onRemove,
    this.onReplace,
    this.onEdit,
    this.onAddMore,
    this.maxImages = 5,
    this.canEdit = true,
    this.imageSize = 80.0,
    this.spacing = 8.0,
    this.imagesPerRow = 4,
  }) : super(key: key);

  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showFullScreenImage(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageGallery(
          images: widget.images,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageGrid(),
        if (widget.canEdit && widget.onAddMore != null && widget.images.length < widget.maxImages)
          _buildAddMoreButton(),
      ],
    );
  }

  Widget _buildImageGrid() {
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.spacing,
      children: List.generate(
        widget.images.length,
        (index) => _buildImageItem(index),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    final image = widget.images[index];
    final isLocal = image.isLocal;
    
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showFullScreenImage(index),
          child: Container(
            width: widget.imageSize,
            height: widget.imageSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: isLocal
                  ? Image.file(
                      image.file!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
                    )
                  : OptimizedNetworkImage(
                      imageUrl: image.thumbnailUrl ?? image.url!,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        if (widget.canEdit)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onRemove != null)
                    GestureDetector(
                      onTap: () => widget.onRemove!(index),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                      ),
                    ),
                  if (widget.onEdit != null)
                    GestureDetector(
                      onTap: () => widget.onEdit!(index),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.crop,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (widget.onReplace != null)
                    GestureDetector(
                      onTap: () => widget.onReplace!(index),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.refresh,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ElevatedButton.icon(
        onPressed: widget.onAddMore,
        icon: const Icon(Icons.add_photo_alternate, size: 18),
        label: Text('Add Images (${widget.maxImages - widget.images.length} remaining)'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}

class _FullScreenImageGallery extends StatelessWidget {
  final List<TaskImage> images;
  final int initialIndex;

  const _FullScreenImageGallery({
    Key? key,
    required this.images,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        builder: (BuildContext context, int index) {
          final image = images[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: image.isLocal
                ? FileImage(image.file!)
                : NetworkImage(image.url!) as ImageProvider,
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2.0,
            heroAttributes: PhotoViewHeroAttributes(tag: 'image_${image.id ?? index}'),
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: PageController(initialPage: initialIndex),
        onPageChanged: (index) {},
        loadingBuilder: (context, event) => const Center(
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
