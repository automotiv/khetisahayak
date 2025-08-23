# Task Image Gallery Integration

This module provides image gallery functionality for tasks, allowing users to select, view, and manage multiple images related to a task.

## Features

- Select multiple images from device gallery
- Preview selected images with zoom and swipe capabilities
- Remove or replace individual images
- Image validation (size, dimensions, format)
- Permission handling for gallery access
- Responsive image grid layout

## Components

### 1. TaskImage Model

A model class representing an image associated with a task. It can handle both local files and remote URLs.

### 2. TaskImageService

A service class that handles image picking, validation, and processing:
- `pickImages()`: Opens the device gallery for image selection
- `_processImageFile()`: Validates and processes selected images
- `_createThumbnail()`: Creates thumbnails for images
- `compressImage()`: Compresses images to reduce file size

### 3. ImageGallery Widget

A reusable widget that displays a grid of selected images with the following features:
- Thumbnail grid view
- Full-screen image viewer with zoom and pan
- Remove and replace functionality
- Add more images button (respects maximum limit)

### 4. TaskImageSelector

A form field widget that integrates with the image gallery functionality:
- Handles image selection and management
- Provides validation and error states
- Displays a user-friendly interface for adding/removing images
- Integrates with form validation

## Usage

### Basic Usage

```dart
TaskImageSelector(
  initialImages: [],
  maxImages: 5,
  onImagesChanged: (images) {
    // Handle the updated list of images
  },
  title: 'Task Images',
  description: 'Add up to 5 images related to this task',
)
```

### Integration with Forms

```dart
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
```

## Configuration

### Image Validation

The following parameters can be adjusted in `TaskImageService`:
- `maxImageSizeMB`: Maximum allowed image size (default: 10MB)
- `maxImageWidth`: Maximum image width in pixels (default: 4096)
- `maxImageHeight`: Maximum image height in pixels (default: 4096)
- `maxImagesPerTask`: Maximum number of images per task (default: 5)
- `allowedMimeTypes`: List of allowed image MIME types

### Permissions

On Android, add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

On iOS, add the following to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to let you select images for tasks.</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access to let you take photos for tasks.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for video recording.</string>
```

## Dependencies

- `image_picker`: For selecting images from the device
- `permission_handler`: For handling runtime permissions
- `photo_view`: For image zooming and panning
- `cached_network_image`: For efficient image loading and caching
- `path_provider`: For accessing device storage
- `image`: For image processing

## Testing

Run the tests with:

```bash
flutter test test/features/tasks/image_gallery_test.dart
```

## Known Issues

- On some Android devices, there might be issues with accessing the gallery after permission is granted. This is usually resolved by restarting the app.
- Large images may cause performance issues. The `compressImage()` method is provided to help with this.

## Future Improvements

- Add support for capturing images with the camera
- Implement image editing capabilities (crop, rotate, etc.)
- Add support for drag-and-drop reordering of images
- Implement batch upload with progress indication
- Add support for videos and other media types
