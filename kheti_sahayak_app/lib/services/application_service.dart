import 'dart:async';
import 'package:kheti_sahayak_app/models/application.dart';
import 'package:kheti_sahayak_app/models/application_timeline_event.dart';
import 'package:uuid/uuid.dart';

class ApplicationService {
  // Mock in-memory storage
  static final List<Application> _applications = [];
  static final _uuid = Uuid();

  // Simulate network delay
  static Future<void> _delay() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Get all applications for a specific user
  static Future<List<Application>> getApplicationsForUser(String userId) async {
    await _delay();
    return _applications.where((app) => app.userId == userId).toList();
  }

  /// Get a single application by ID
  static Future<Application?> getApplicationById(String applicationId) async {
    await _delay();
    try {
      return _applications.firstWhere((app) => app.id == applicationId);
    } catch (e) {
      return null;
    }
  }

  /// Submit a new application
  static Future<Application> submitApplication({
    required String schemeId,
    required String schemeName,
    required String userId,
  }) async {
    await _delay();

    final newApplication = Application(
      id: _uuid.v4(),
      schemeId: schemeId,
      schemeName: schemeName,
      userId: userId,
      status: ApplicationStatus.submitted,
      submissionDate: DateTime.now(),
      timeline: [
        ApplicationTimelineEvent(
          status: ApplicationStatus.submitted,
          date: DateTime.now(),
          description: 'Application submitted successfully.',
        ),
      ],
    );

    _applications.add(newApplication);
    return newApplication;
  }

  /// Update application status (Simulated for demo/testing)
  static Future<Application> updateApplicationStatus(
    String applicationId,
    ApplicationStatus newStatus, {
    String? remarks,
  }) async {
    await _delay();

    final index = _applications.indexWhere((app) => app.id == applicationId);
    if (index == -1) {
      throw Exception('Application not found');
    }

    final currentApp = _applications[index];
    final now = DateTime.now();

    // Calculate expected disbursement date if status is approved
    DateTime? expectedDisbursement;
    if (newStatus == ApplicationStatus.approved) {
      expectedDisbursement = now.add(const Duration(days: 15));
    } else {
      expectedDisbursement = currentApp.expectedDisbursementDate;
    }

    final newEvent = ApplicationTimelineEvent(
      status: newStatus,
      date: now,
      description: _getStatusDescription(newStatus, remarks),
    );

    final updatedApp = currentApp.copyWith(
      status: newStatus,
      expectedDisbursementDate: expectedDisbursement,
      timeline: [...currentApp.timeline, newEvent],
      remarks: remarks,
    );

    _applications[index] = updatedApp;
    return updatedApp;
  }

  static String _getStatusDescription(ApplicationStatus status, String? remarks) {
    switch (status) {
      case ApplicationStatus.submitted:
        return 'Application submitted.';
      case ApplicationStatus.underReview:
        return 'Application is under review by officials.';
      case ApplicationStatus.approved:
        return 'Application approved. Disbursement expected soon.';
      case ApplicationStatus.rejected:
        return 'Application rejected. ${remarks ?? "Please contact support."}';
      case ApplicationStatus.disbursed:
        return 'Funds disbursed to your account.';
    }
  }

  /// Get applications for extension officer (Bulk view mock)
  static Future<List<Application>> getApplicationsForExtensionOfficer() async {
    await _delay();
    // Return all applications for now
    return List.from(_applications);
  }
  
  // Initialize with some dummy data for testing
  static Future<void> initializeDummyData(String userId) async {
    if (_applications.isNotEmpty) return;
    
    _applications.addAll([
      Application(
        id: _uuid.v4(),
        schemeId: 'scheme_1',
        schemeName: 'PM Kisan Samman Nidhi',
        userId: userId,
        status: ApplicationStatus.underReview,
        submissionDate: DateTime.now().subtract(const Duration(days: 5)),
        timeline: [
          ApplicationTimelineEvent(
            status: ApplicationStatus.submitted,
            date: DateTime.now().subtract(const Duration(days: 5)),
            description: 'Application submitted successfully.',
          ),
          ApplicationTimelineEvent(
            status: ApplicationStatus.underReview,
            date: DateTime.now().subtract(const Duration(days: 2)),
            description: 'Application is under review by officials.',
          ),
        ],
      ),
      Application(
        id: _uuid.v4(),
        schemeId: 'scheme_2',
        schemeName: 'Soil Health Card Scheme',
        userId: userId,
        status: ApplicationStatus.approved,
        submissionDate: DateTime.now().subtract(const Duration(days: 10)),
        expectedDisbursementDate: DateTime.now().add(const Duration(days: 5)),
        timeline: [
          ApplicationTimelineEvent(
            status: ApplicationStatus.submitted,
            date: DateTime.now().subtract(const Duration(days: 10)),
            description: 'Application submitted successfully.',
          ),
          ApplicationTimelineEvent(
            status: ApplicationStatus.underReview,
            date: DateTime.now().subtract(const Duration(days: 8)),
            description: 'Application is under review by officials.',
          ),
          ApplicationTimelineEvent(
            status: ApplicationStatus.approved,
            date: DateTime.now().subtract(const Duration(days: 1)),
            description: 'Application approved. Disbursement expected soon.',
          ),
        ],
      ),
    ]);
  }
}
