import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'ingest_client.dart';
import '../../utils/logger.dart';

class _QueueEntry {
  final String filePath;
  final bool keepLocation;
  int attempts;

  _QueueEntry(this.filePath, {this.keepLocation = false, this.attempts = 0});

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'keepLocation': keepLocation,
        'attempts': attempts,
      };

  static _QueueEntry fromJson(Map<String, dynamic> j) => _QueueEntry(
        j['filePath'],
        keepLocation: j['keepLocation'] == true || j['keepLocation'] == 'true',
        attempts: j['attempts'] ?? 0,
      );
}

class UploadQueue {
  static const _prefsKey = 'kss_upload_queue_v1';
  static const int maxAttempts = 5;

  /// Enqueue a file for background upload. The file will be copied into app documents to avoid temp cleanup.
  static Future<void> enqueue(File file, {bool keepLocation = false}) async {
    try {
      final appDoc = await getApplicationDocumentsDirectory();
      final dstDir = Directory('${appDoc.path}/upload_queue');
      if (!await dstDir.exists()) await dstDir.create(recursive: true);
      final filename = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final dstPath = path.join(dstDir.path, filename);
      await file.copy(dstPath);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? <String>[];
      final entry = _QueueEntry(dstPath, keepLocation: keepLocation, attempts: 0);
      raw.add(json.encode(entry.toJson()));
      await prefs.setStringList(_prefsKey, raw);
      AppLogger.info('Enqueued upload: $dstPath');
    } catch (e) {
      AppLogger.error('Failed to enqueue upload', e);
    }
  }

  /// Process pending uploads sequentially. Call on app startup or when connectivity is restored.
  static Future<void> processQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];
    if (raw.isEmpty) return;

    final List<_QueueEntry> entries = raw.map((r) => _QueueEntry.fromJson(json.decode(r))).toList();
    final updated = <String>[];

    for (final e in entries) {
      if (e.attempts >= maxAttempts) {
        AppLogger.warning('Dropping upload after max attempts: ${e.filePath}');
        // skip and remove
        continue;
      }
      try {
        final file = File(e.filePath);
        if (!await file.exists()) {
          AppLogger.warning('Queued file missing, removing: ${e.filePath}');
          continue;
        }

        // presign
        final filename = path.basename(file.path);
        final presign = await IngestClient.presign(filename, _detectMime(filename));
        final url = presign['uploadUrl'] as String;
        final key = presign['key'] as String;

        await IngestClient.uploadToUrl(url, await file.readAsBytes(), _detectMime(filename));
        final result = await IngestClient.finalize(key, keepLocation: e.keepLocation);
        AppLogger.info('Background upload succeeded: ${result['url']}');

        // remove file after success
        try {
          await file.delete();
        } catch (_) {}
      } catch (err) {
        AppLogger.error('Background upload error for ${e.filePath}', err);
        e.attempts += 1;
        updated.add(json.encode(e.toJson()));
        continue;
      }
    }

    // Save updated queue (only entries that retried)
    await prefs.setStringList(_prefsKey, updated);
  }

  static String _detectMime(String filename) {
    final ext = path.extension(filename).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg') return 'image/jpeg';
    if (ext == '.png') return 'image/png';
    if (ext == '.webp') return 'image/webp';
    return 'application/octet-stream';
  }
}
