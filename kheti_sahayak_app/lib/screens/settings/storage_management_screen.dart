import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/services/offline_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({Key? key}) : super(key: key);

  @override
  State<StorageManagementScreen> createState() => _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  bool _isLoading = true;
  StorageInfo? _storageInfo;
  bool _autoDeleteOldCache = true;
  int _cacheRetentionDays = 7;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoDeleteOldCache = prefs.getBool('auto_delete_old_cache') ?? true;
      _cacheRetentionDays = prefs.getInt('cache_retention_days') ?? 7;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_delete_old_cache', _autoDeleteOldCache);
    await prefs.setInt('cache_retention_days', _cacheRetentionDays);
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper.instance;
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = await getTemporaryDirectory();

      int dbSize = 0;
      int cacheSize = 0;
      int imagesCacheSize = 0;

      final dbFile = File('${appDir.path}/kheti_sahayak.db');
      if (await dbFile.exists()) {
        dbSize = await dbFile.length();
      }

      cacheSize = await _getDirectorySize(cacheDir);

      final imagesDir = Directory('${cacheDir.path}/images');
      if (await imagesDir.exists()) {
        imagesCacheSize = await _getDirectorySize(imagesDir);
      }

      final cachedProducts = await dbHelper.getCachedProducts();
      final cachedEducation = await dbHelper.getCachedEducationalContent();

      if (mounted) {
        setState(() {
          _storageInfo = StorageInfo(
            databaseSize: dbSize,
            cacheSize: cacheSize,
            imagesCacheSize: imagesCacheSize,
            cachedProductsCount: cachedProducts.length,
            cachedEducationCount: cachedEducation.length,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading storage info: $e')),
        );
      }
    }
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      print('Error calculating directory size: $e');
    }
    return size;
  }

  Future<void> _clearCache(String cacheType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: Text('Are you sure you want to clear $cacheType cache? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      switch (cacheType) {
        case 'products':
          await DatabaseHelper.instance.clearProductsCache();
          break;
        case 'education':
          await DatabaseHelper.instance.clearEducationalContentCache();
          break;
        case 'images':
          final cacheDir = await getTemporaryDirectory();
          final imagesDir = Directory('${cacheDir.path}/images');
          if (await imagesDir.exists()) {
            await imagesDir.delete(recursive: true);
          }
          break;
        case 'all':
          await OfflineCacheService.clearAllCache();
          final cacheDir = await getTemporaryDirectory();
          await for (var entity in cacheDir.list()) {
            try {
              await entity.delete(recursive: true);
            } catch (_) {}
          }
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$cacheType cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadStorageInfo();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStorageInfo,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStorageOverview(),
                  const SizedBox(height: 24),
                  _buildCacheDetails(),
                  const SizedBox(height: 24),
                  _buildCacheSettings(),
                  const SizedBox(height: 24),
                  _buildClearCacheButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildStorageOverview() {
    final totalSize = (_storageInfo?.databaseSize ?? 0) +
        (_storageInfo?.cacheSize ?? 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Storage Usage',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(
              label: 'Total',
              value: totalSize,
              maxValue: 100 * 1024 * 1024,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              label: 'Database',
              value: _storageInfo?.databaseSize ?? 0,
              maxValue: 50 * 1024 * 1024,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              label: 'Cache',
              value: _storageInfo?.cacheSize ?? 0,
              maxValue: 50 * 1024 * 1024,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int value,
    required int maxValue,
    required Color color,
  }) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(_formatBytes(value), style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildCacheDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cached Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCacheItem(
              icon: Icons.shopping_bag,
              label: 'Products',
              count: _storageInfo?.cachedProductsCount ?? 0,
              onClear: () => _clearCache('products'),
            ),
            const Divider(),
            _buildCacheItem(
              icon: Icons.school,
              label: 'Educational Content',
              count: _storageInfo?.cachedEducationCount ?? 0,
              onClear: () => _clearCache('education'),
            ),
            const Divider(),
            _buildCacheItem(
              icon: Icons.image,
              label: 'Images',
              size: _storageInfo?.imagesCacheSize ?? 0,
              onClear: () => _clearCache('images'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheItem({
    required IconData icon,
    required String label,
    int? count,
    int? size,
    required VoidCallback onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(label),
      subtitle: Text(
        count != null ? '$count items cached' : _formatBytes(size ?? 0),
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: TextButton(
        onPressed: onClear,
        child: const Text('Clear'),
      ),
    );
  }

  Widget _buildCacheSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cache Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-delete old cache'),
              subtitle: const Text('Automatically remove old cached data'),
              value: _autoDeleteOldCache,
              onChanged: (value) {
                setState(() => _autoDeleteOldCache = value);
                _saveSettings();
              },
              activeColor: Colors.green[700],
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cache retention period'),
              subtitle: Text('$_cacheRetentionDays days'),
              trailing: DropdownButton<int>(
                value: _cacheRetentionDays,
                items: [3, 7, 14, 30].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text('$days days'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _cacheRetentionDays = value);
                    _saveSettings();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearCacheButtons() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clearing all cache will remove offline data. You will need an internet connection to reload content.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _clearCache('all'),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear All Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StorageInfo {
  final int databaseSize;
  final int cacheSize;
  final int imagesCacheSize;
  final int cachedProductsCount;
  final int cachedEducationCount;

  StorageInfo({
    required this.databaseSize,
    required this.cacheSize,
    required this.imagesCacheSize,
    required this.cachedProductsCount,
    required this.cachedEducationCount,
  });
}
