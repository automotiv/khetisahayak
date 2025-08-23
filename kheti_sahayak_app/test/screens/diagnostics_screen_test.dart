import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_platform_interface/models/models.dart';
import 'package:kheti_sahayak_app/screens/diagnostics/diagnostics_screen.dart';
import 'package:kheti_sahayak_app/services/diagnostic_service.dart';
import 'package:kheti_sahayak_app/models/diagnostic.dart';
import 'diagnostics_screen_test.mocks.dart';

// Generate mocks
@GenerateMocks([DiagnosticService, ImagePicker])
void main() {
  late MockDiagnosticService mockDiagnosticService;
  late MockImagePicker mockImagePicker;
  late Widget testApp;
  
  // Create a test image file
  Future<File> createTestImage() async {
    final directory = await Directory.systemTemp.createTemp();
    final file = File('${directory.path}/test_image.jpg');
    await file.writeAsBytes(List.generate(1000, (index) => 0));
    return file;
  }

  setUp(() {
    mockDiagnosticService = MockDiagnosticService();
    mockImagePicker = MockImagePicker();
    
    // Setup PathProvider for file operations
    PathProviderPlatform.instance = MockPathProviderPlatform();
    
    testApp = MaterialApp(
      home: DiagnosticsScreen(),
    );
  });

  testWidgets('shows error when no image is selected', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(testApp);

    // Tap the analyze button without selecting an image
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify the error dialog is shown
    expect(find.text('No Image Selected'), findsOneWidget);
    expect(find.text('Please select an image to analyze.'), findsOneWidget);
  });

  testWidgets('shows error for large image', (WidgetTester tester) async {
    final largeFile = File('test_large.jpg');
    // Mock file size to be 11MB (larger than 10MB limit)
    when(largeFile.length()).thenAnswer((_) async => 11 * 1024 * 1024);
    
    when(mockImagePicker.pickImage(
      source: anyNamed('source'),
      imageQuality: anyNamed('imageQuality'),
      maxWidth: anyNamed('maxWidth'),
      maxHeight: anyNamed('maxHeight'),
    )).thenAnswer((_) async => XFile(largeFile.path));

    await tester.pumpWidget(testApp);
    
    // Tap the image picker button
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    // Verify the error dialog for large image
    expect(find.text('Image Too Large'), findsOneWidget);
    expect(find.textContaining('Please select an image smaller than 10MB'), findsOneWidget);
  });

  testWidgets('shows error for invalid file type', (WidgetTester tester) async {
    final invalidFile = File('test.pdf');
    when(invalidFile.length()).thenAnswer((_) async => 1024); // 1KB
    
    when(mockImagePicker.pickImage(
      source: anyNamed('source'),
      imageQuality: anyNamed('imageQuality'),
      maxWidth: anyNamed('maxWidth'),
      maxHeight: anyNamed('maxHeight'),
    )).thenAnswer((_) async => XFile(invalidFile.path));

    await tester.pumpWidget(testApp);
    
    // Tap the image picker button
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    // Verify the error dialog for invalid file type
    expect(find.text('Unsupported Format'), findsOneWidget);
    expect(find.textContaining('Please select an image in JPG, PNG, or HEIC format'), findsOneWidget);
  });

  testWidgets('shows error for network failure', (WidgetTester tester) async {
    final testImage = await createTestImage();
    
    when(mockImagePicker.pickImage(
      source: anyNamed('source'),
      imageQuality: anyNamed('imageQuality'),
      maxWidth: anyNamed('maxWidth'),
      maxHeight: anyNamed('maxHeight'),
    )).thenAnswer((_) async => XFile(testImage.path));

    // Mock network error
    when(mockDiagnosticService.uploadForDiagnosis(
      imageFile: anyNamed('imageFile'),
      cropType: anyNamed('cropType'),
      issueDescription: anyNamed('issueDescription'),
    )).thenThrow(SocketException('Network error'));

    await tester.pumpWidget(testApp);
    
    // Select an image
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    // Fill in required fields
    await tester.enterText(find.byType(TextFormField).first, 'Rice');
    await tester.enterText(find.byType(TextFormField).last, 'Yellow leaves');
    
    // Tap analyze button
    await tester.tap(find.text('Analyze'));
    await tester.pumpAndSettle();

    // Verify network error dialog with retry option
    expect(find.text('Network Error'), findsOneWidget);
    expect(find.textContaining('Unable to connect to the server'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

// Mock PathProviderPlatform
class MockPathProviderPlatform extends Mock implements PathProviderPlatform {
  @override
  Future<String> getTemporaryPath() async {
    return '/tmp';
  }
}

// Mock XFile
class MockXFile extends Mock implements XFile {
  @override
  final String path;
  
  MockXFile(this.path);
  
  @override
  Future<Uint8List> readAsBytes() async {
    return Uint8List(100);
  }
  
  @override
  Future<int> length() async {
    return 100;
  }
}
