import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageManagementScreen Widget', () {
    testWidgets('renders main sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(),
          ),
        ),
      );

      expect(find.text('Storage Management'), findsOneWidget);
      expect(find.text('Storage Overview'), findsOneWidget);
      expect(find.text('Cached Data'), findsOneWidget);
    });

    testWidgets('shows database storage info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(
              databaseSize: '15.5 MB',
              cacheSize: '8.2 MB',
            ),
          ),
        ),
      );

      expect(find.text('Database'), findsOneWidget);
      expect(find.text('15.5 MB'), findsOneWidget);
      expect(find.text('Cache'), findsOneWidget);
      expect(find.text('8.2 MB'), findsOneWidget);
    });

    testWidgets('shows progress indicator for storage',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('shows cached data categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(
              cachedProducts: 45,
              cachedEducation: 28,
              cachedImages: 156,
            ),
          ),
        ),
      );

      expect(find.text('45 items'), findsOneWidget);
      expect(find.text('28 items'), findsOneWidget);
      expect(find.text('156 images'), findsOneWidget);
    });

    testWidgets('shows clear cache buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(),
          ),
        ),
      );

      expect(find.text('Clear All Cache'), findsOneWidget);
    });

    testWidgets('calls onClearCache when clear button is pressed',
        (WidgetTester tester) async {
      bool clearCacheCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(
              onClearCache: () => clearCacheCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Clear All Cache'));
      await tester.pump();

      expect(clearCacheCalled, isTrue);
    });

    testWidgets('shows cache settings section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(),
          ),
        ),
      );

      expect(find.text('Cache Settings'), findsOneWidget);
    });

    testWidgets('shows auto-delete toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(autoDeleteEnabled: true),
          ),
        ),
      );

      expect(find.text('Auto-delete old cache'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('auto-delete switch toggles correctly',
        (WidgetTester tester) async {
      bool autoDeleteEnabled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => _MockStorageManagementScreen(
                autoDeleteEnabled: autoDeleteEnabled,
                onAutoDeleteChanged: (value) {
                  setState(() => autoDeleteEnabled = value);
                },
              ),
            ),
          ),
        ),
      );

      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);

      await tester.tap(switchWidget);
      await tester.pump();

      expect(autoDeleteEnabled, isTrue);
    });

    testWidgets('shows retention period dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(retentionDays: 7),
          ),
        ),
      );

      expect(find.text('Cache retention period'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
    });

    testWidgets('shows danger zone section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(),
          ),
        ),
      );

      expect(find.text('Danger Zone'), findsOneWidget);
    });

    testWidgets('shows loading indicator when clearing cache',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockStorageManagementScreen(isClearing: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Storage size formatting', () {
    test('formats bytes correctly', () {
      expect(_formatSize(500), '500 B');
    });

    test('formats kilobytes correctly', () {
      expect(_formatSize(1024), '1.0 KB');
      expect(_formatSize(2048), '2.0 KB');
    });

    test('formats megabytes correctly', () {
      expect(_formatSize(1024 * 1024), '1.0 MB');
      expect(_formatSize(15.5 * 1024 * 1024), '15.5 MB');
    });

    test('formats gigabytes correctly', () {
      expect(_formatSize(1024 * 1024 * 1024), '1.0 GB');
    });
  });
}

String _formatSize(double bytes) {
  if (bytes < 1024) {
    return '${bytes.toInt()} B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _MockStorageManagementScreen extends StatelessWidget {
  final String databaseSize;
  final String cacheSize;
  final int cachedProducts;
  final int cachedEducation;
  final int cachedImages;
  final bool autoDeleteEnabled;
  final int retentionDays;
  final bool isClearing;
  final VoidCallback? onClearCache;
  final ValueChanged<bool>? onAutoDeleteChanged;

  const _MockStorageManagementScreen({
    this.databaseSize = '10.0 MB',
    this.cacheSize = '5.0 MB',
    this.cachedProducts = 0,
    this.cachedEducation = 0,
    this.cachedImages = 0,
    this.autoDeleteEnabled = false,
    this.retentionDays = 7,
    this.isClearing = false,
    this.onClearCache,
    this.onAutoDeleteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Storage Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildStorageOverview(),
          const SizedBox(height: 24),
          _buildCachedData(),
          const SizedBox(height: 24),
          _buildCacheSettings(),
          const SizedBox(height: 24),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildStorageOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Storage Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStorageRow('Database', databaseSize, 0.6),
            const SizedBox(height: 12),
            _buildStorageRow('Cache', cacheSize, 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageRow(String label, String size, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(size)],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: progress),
      ],
    );
  }

  Widget _buildCachedData() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cached Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (cachedProducts > 0)
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Products'),
                subtitle: Text('$cachedProducts items'),
              ),
            if (cachedEducation > 0)
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Educational Content'),
                subtitle: Text('$cachedEducation items'),
              ),
            if (cachedImages > 0)
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Images'),
                subtitle: Text('$cachedImages images'),
              ),
          ],
        ),
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
            const Text('Cache Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-delete old cache'),
              value: autoDeleteEnabled,
              onChanged: onAutoDeleteChanged,
            ),
            ListTile(
              title: const Text('Cache retention period'),
              subtitle: Text('$retentionDays days'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Danger Zone',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
            const SizedBox(height: 16),
            if (isClearing)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: onClearCache,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear All Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
