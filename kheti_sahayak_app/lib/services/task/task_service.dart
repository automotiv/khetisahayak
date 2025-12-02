import 'dart:convert';
import 'dart:io';
import 'package:kheti_sahayak_app/models/task/task_image.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/services/sync_service.dart';
import 'package:kheti_sahayak_app/services/task/task_image_service.dart';
import 'package:kheti_sahayak_app/utils/logger.dart';

class TaskService {
  static final TaskService instance = TaskService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SyncService _syncService = SyncService.instance;
  final TaskImageService _imageService = TaskImageService();

  TaskService._init();

  /// Create a new task
  /// If online: uploads images and creates task via API
  /// If offline: saves task locally for later sync
  Future<Map<String, dynamic>> createTask({
    required String title,
    required String description,
    required List<TaskImage> images,
  }) async {
    try {
      final isOnline = await _syncService.isOnline();

      if (isOnline) {
        return await _createTaskOnline(title, description, images);
      } else {
        return await _createTaskOffline(title, description, images);
      }
    } catch (e) {
      AppLogger.error('Error creating task', e);
      // If online creation fails, try saving offline as fallback
      try {
        return await _createTaskOffline(title, description, images);
      } catch (offlineError) {
        AppLogger.error('Error saving task offline', offlineError);
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> _createTaskOnline(
    String title,
    String description,
    List<TaskImage> images,
  ) async {
    // 1. Upload images first
    final List<String> uploadedImageUrls = [];
    
    for (final image in images) {
      if (image.isLocal && image.file != null) {
        // Upload image
        final result = await _imageService.uploadImageViaPresign(image.file!);
        if (result['url'] != null) {
          uploadedImageUrls.add(result['url']);
        }
      } else if (image.isRemote && image.url != null) {
        uploadedImageUrls.add(image.url!);
      }
    }

    // 2. Create task via API
    final taskData = {
      'title': title,
      'description': description,
      'images': uploadedImageUrls,
      'status': 'pending', // Default status
    };

    final result = await ApiService.post('tasks', taskData);
    return result;
  }

  Future<Map<String, dynamic>> _createTaskOffline(
    String title,
    String description,
    List<TaskImage> images,
  ) async {
    // Save local file paths
    final List<String> imagePaths = images
        .where((img) => img.isLocal && img.file != null)
        .map((img) => img.file!.path)
        .toList();

    final taskData = {
      'title': title,
      'description': description,
      'image_paths': jsonEncode(imagePaths),
    };

    await _dbHelper.insertPendingTask(taskData);

    return {
      'offline': true,
      'message': 'Task saved offline. It will be synced when you are online.',
    };
  }
}
