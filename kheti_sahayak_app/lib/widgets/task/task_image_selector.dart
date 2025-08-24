import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/task/task_image_service.dart';
import '../../../models/task/task_image.dart';
import 'image_gallery.dart';
import '../../../utils/dialogs.dart';

class TaskImageSelector extends StatefulWidget {
  final List<TaskImage> initialImages;
  final Function(List<TaskImage>)? onImagesChanged;
  final int maxImages;
  final bool enabled;
  final String? title;
  final String? description;

  const TaskImageSelector({
    Key? key,
    this.initialImages = const [],
    this.onImagesChanged,
    this.maxImages = 5,
    this.enabled = true,
    this.title,
    this.description,
  }) : super(key: key);

  @override
  _TaskImageSelectorState createState() => _TaskImageSelectorState();
}

class _TaskImageSelectorState extends State<TaskImageSelector> {
  late List<TaskImage> _selectedImages;
  final TaskImageService _imageService = TaskImageService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedImages = List.from(widget.initialImages);
  }

  @override
  void didUpdateWidget(TaskImageSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImages != widget.initialImages) {
      setState(() {
        _selectedImages = List.from(widget.initialImages);
      });
    }
  }

  Future<void> _pickImages() async {
    if (!widget.enabled) return;

    setState(() => _isLoading = true);
    
    try {
  final remainingSlots = widget.maxImages - _selectedImages.length;
      if (remainingSlots <= 0) {
        if (mounted) {
          await Dialogs.showInfoDialog(
            context,
            title: 'Maximum Images Reached',
            content: 'You can only add up to ${widget.maxImages} images.',
          );
        }
        return;
      }

      // Let user choose Camera or Gallery
      final source = await showModalBottomSheet<ImageSource?>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose From Gallery'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(ctx).pop(null),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final images = await _imageService.pickImages(
        maxImages: remainingSlots,
        source: source,
      );

      if (images.isNotEmpty) {
        // Upload each image via presigned flow and replace local file with remote metadata
        final List<TaskImage> uploaded = [];
        for (final t in images) {
          if (t.isLocal && t.file != null) {
            try {
              final result = await _imageService.uploadImageViaPresign(t.file!);
              // Expecting result to include url and key; create TaskImage from JSON-like map
              final remote = TaskImage.fromJson({
                'url': result['url'],
                'name': result['key']?.split('/')?.last ?? t.name,
                'size': result['size'],
                'mimeType': t.mimeType,
                'uploadedAt': DateTime.now().toIso8601String(),
              });
              uploaded.add(remote);
            } catch (e) {
              AppLogger.error('Upload failed for ${t.name}', e);
              // fallback to local image so user can retry
              uploaded.add(t);
            }
          } else {
            uploaded.add(t);
          }
        }

        setState(() {
          _selectedImages.addAll(uploaded);
          widget.onImagesChanged?.call(List.from(_selectedImages));
        });
      }
    } catch (e) {
      if (mounted) {
        await Dialogs.showErrorDialog(
          context,
          title: 'Error Selecting Images',
          content: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeImage(int index) {
    if (!widget.enabled) return;
    
    setState(() {
      _selectedImages.removeAt(index);
      widget.onImagesChanged?.call(List.from(_selectedImages));
    });
  }

  Future<void> _replaceImage(int index) async {
    if (!widget.enabled) return;

    try {
      final images = await _imageService.pickImages(maxImages: 1);
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages[index] = images.first;
          widget.onImagesChanged?.call(List.from(_selectedImages));
        });
      }
    } catch (e) {
      if (mounted) {
        await Dialogs.showErrorDialog(
          context,
          title: 'Error Replacing Image',
          content: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (widget.description != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
          const SizedBox(height: 8),
        ],
        
        // Image gallery
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _selectedImages.isEmpty
                ? _buildEmptyState()
                : ImageGallery(
                    images: _selectedImages,
                    maxImages: widget.maxImages,
                    canEdit: widget.enabled,
                    onRemove: _removeImage,
                    onReplace: _replaceImage,
                    onAddMore: _pickImages,
                  ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: widget.enabled ? _pickImages : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: widget.enabled
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).disabledColor.withOpacity(0.1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add images (max ${widget.maxImages})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Example usage in a form:
/*
class TaskForm extends StatefulWidget {
  @override
  _TaskFormState createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final List<TaskImage> _taskImages = [];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Other form fields...
          
          const SizedBox(height: 16),
          TaskImageSelector(
            initialImages: _taskImages,
            maxImages: 5,
            onImagesChanged: (images) {
              setState(() {
                _taskImages.clear();
                _taskImages.addAll(images);
              });
            },
            title: 'Task Images',
            description: 'Add up to 5 images related to this task',
          ),
          
          // Submit button...
        ],
      ),
    );
  }
}
*/
