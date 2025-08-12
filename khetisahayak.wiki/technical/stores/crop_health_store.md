# Crop Health Diagnostics - State Management

## Store Architecture

### 1. CropHealthStore
Manages the core state and business logic for the Crop Health Diagnostics feature.

#### State
```dart
class CropHealthState {
  final bool isLoading;
  final List<DiagnosticResult> results;
  final List<DiagnosticHistory> history;
  final String? error;
  final bool isOffline;
  final List<DiagnosticResult> pendingSync;
  final Map<String, dynamic>? currentDiagnosis;
  final List<File> selectedImages;
  final List<DiagnosticResult> filteredResults;
  final String searchQuery;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final List<String> selectedCrops;
  final List<String> selectedIssues;
}
```

#### Actions
```dart
// Image Selection
class SelectImagesAction {
  final List<File> images;
}

class RemoveImageAction {
  final int index;
}

// Analysis
class AnalyzeImagesAction {
  final List<File> images;
  final LocationData? location;
  final String? cropType;
}

class AnalysisSuccessAction {
  final DiagnosticResult result;
}

class AnalysisFailedAction {
  final String error;
}

// History
class LoadHistoryAction {}

class HistoryLoadedAction {
  final List<DiagnosticHistory> history;
}

class FilterHistoryAction {
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? crops;
  final List<String>? issues;
}

// Offline
class QueueForSyncAction {
  final DiagnosticResult result;
}

class SyncCompletedAction {
  final String resultId;
}

// Results
class SaveResultAction {
  final DiagnosticResult result;
  final String? notes;
}

class ExportResultAction {
  final String resultId;
  final ExportFormat format;
}
```

### 2. CameraStore
Manages camera state and image capture functionality.

#### State
```dart
class CameraState {
  final CameraController? controller;
  final bool isInitialized;
  final bool isRecording;
  final String? error;
  final List<File> capturedImages;
  final int maxImages;
  final FlashMode flashMode;
  final CameraLensDirection lensDirection;
}
```

### 3. OfflineStore
Manages offline functionality and sync state.

#### State
```dart
class OfflineState {
  final bool isOnline;
  final List<DiagnosticResult> pendingSync;
  final DateTime? lastSync;
  final bool isSyncing;
  final String? syncError;
}
```

## API Services

### 1. ImageAnalysisService
```dart
class ImageAnalysisService {
  Future<DiagnosticResult> analyzeImages({
    required List<File> images,
    String? cropType,
    LocationData? location,
  });
  
  Future<DiagnosticResult> getCachedResult(String resultId);
  Future<void> cacheResult(DiagnosticResult result);
}
```

### 2. HistoryService
```dart
class HistoryService {
  Future<List<DiagnosticHistory>> getHistory({
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? crops,
    List<String>? issues,
  });
  
  Future<void> saveToHistory(DiagnosticResult result, {String? notes});
  Future<void> deleteFromHistory(String resultId);
  Future<void> exportHistory(String resultId, ExportFormat format);
}
```

### 3. SyncService
```dart
class SyncService {
  Future<void> syncPendingOperations();
  Future<bool> checkConnectivity();
  Future<void> retryFailedSync(String operationId);
}
```

## Models

### DiagnosticResult
```dart
class DiagnosticResult {
  final String id;
  final DateTime timestamp;
  final List<String> imageUrls;
  final List<IdentifiedIssue> issues;
  final LocationData? location;
  final String? cropType;
  final double confidenceScore;
  final String status; // 'pending', 'completed', 'failed'
  final String? error;
  final Map<String, dynamic>? metadata;
}

class IdentifiedIssue {
  final String id;
  final String type; // 'disease', 'pest', 'deficiency'
  final String name;
  final String scientificName;
  final String description;
  final double confidence;
  final List<Treatment> treatments;
  final List<PreventiveMeasure> preventiveMeasures;
  final List<String> similarIssues;
}

class Treatment {
  final String id;
  final String name;
  final String description;
  final String dosage;
  final String applicationMethod;
  final String frequency;
  final List<String> safetyPrecautions;
  final List<NearbyStore>? nearbyStores;
}

class PreventiveMeasure {
  final String id;
  final String title;
  final String description;
  final String? timing;
  final String? frequency;
}
```

## UI Components

### 1. CameraScreen
- Camera preview
- Capture button
- Flash toggle
- Switch camera
- Gallery access
- Image counter

### 2. AnalysisScreen
- Loading state
- Progress indicator
- Analysis results
- Confidence indicators
- Alternative suggestions

### 3. ResultsScreen
- Issue cards
- Treatment recommendations
- Preventive measures
- Save/share options
- Add to calendar

### 4. HistoryScreen
- List of past diagnostics
- Filter and search
- Sort options
- Export functionality

## Error Handling

### Error Types
1. **Image Capture Errors**
   - Camera permissions
   - Storage permissions
   - Camera initialization

2. **Analysis Errors**
   - Network issues
   - Server errors
   - Invalid image format
   - Low confidence results

3. **Sync Errors**
   - Offline mode
   - Conflict resolution
   - Failed sync operations

### Error Recovery
- Automatic retry for transient errors
- Clear error messages
- Actionable recovery steps
- Offline queuing with sync status

## Performance Considerations
1. **Image Processing**
   - Image compression before upload
   - Progressive loading
   - Caching strategy

2. **State Management**
   - Efficient state updates
   - Selective rebuilds
   - Memory management

3. **Offline Support**
   - Local storage optimization
   - Batch operations
   - Conflict resolution

## Testing Strategy

### Unit Tests
- State management
- Business logic
- Model validation

### Widget Tests
- UI components
- User interactions
- State changes

### Integration Tests
- End-to-end flows
- API interactions
- Offline scenarios

### Performance Tests
- Image processing
- Memory usage
- Battery impact
