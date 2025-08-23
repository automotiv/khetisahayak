import 'package:image_picker/image_picker.dart';

abstract class ImagePickerAdapter {
  Future<XFile?> pickImage({required ImageSource source, double? maxWidth, double? maxHeight, int? imageQuality});
  Future<List<XFile>?> pickMultiImage({double? maxWidth, double? maxHeight, int? imageQuality});
}

class ImagePickerAdapterImpl implements ImagePickerAdapter {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<XFile?> pickImage({required ImageSource source, double? maxWidth, double? maxHeight, int? imageQuality}) {
    return _picker.pickImage(source: source, maxWidth: maxWidth, maxHeight: maxHeight, imageQuality: imageQuality);
  }

  @override
  Future<List<XFile>?> pickMultiImage({double? maxWidth, double? maxHeight, int? imageQuality}) {
    return _picker.pickMultiImage(maxWidth: maxWidth, maxHeight: maxHeight, imageQuality: imageQuality);
  }
}
