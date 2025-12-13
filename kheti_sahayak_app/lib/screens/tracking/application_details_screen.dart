import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/application.dart';
import 'package:kheti_sahayak_app/models/application_timeline_event.dart';
import 'package:kheti_sahayak_app/services/application_service.dart';
import 'package:kheti_sahayak_app/services/local_notification_service.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final Application application;

  const ApplicationDetailsScreen({super.key, required this.application});

  @override
  State<ApplicationDetailsScreen> createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  late Application _application;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _application = widget.application;
  }

  Future<void> _simulateStatusUpdate() async {
    setState(() => _isUpdating = true);
    
    // Determine next logical status for demo purposes
    ApplicationStatus nextStatus;
    switch (_application.status) {
      case ApplicationStatus.submitted:
        nextStatus = ApplicationStatus.underReview;
        break;
      case ApplicationStatus.underReview:
        nextStatus = ApplicationStatus.approved;
        break;
      case ApplicationStatus.approved:
        nextStatus = ApplicationStatus.disbursed;
        break;
      default:
        nextStatus = ApplicationStatus.submitted; // Reset for demo
    }

    try {
      final updatedApp = await ApplicationService.updateApplicationStatus(
        _application.id,
        nextStatus,
        remarks: nextStatus == ApplicationStatus.rejected ? 'Documents incomplete' : null,
      );

      // Show notification
      await LocalNotificationService().showApplicationStatusNotification(
        schemeName: updatedApp.schemeName,
        status: nextStatus.toString().split('.').last,
        applicationId: updatedApp.id,
      );

      if (mounted) {
        setState(() {
          _application = updatedApp;
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).success}: Status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'), // Add to translations
        backgroundColor: Colors.green[700],
        actions: [
          // Demo button to simulate status changes
          IconButton(
            icon: const Icon(Icons.update),
            tooltip: 'Simulate Status Update',
            onPressed: _isUpdating ? null : _simulateStatusUpdate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            const Text(
              'Application Timeline', // Add to translations
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final localizations = AppLocalizations.of(context);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _application.schemeName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Application ID: ${_application.id}'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Current Status: ', // Add to translations
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _getStatusText(_application.status),
                  style: TextStyle(
                    color: _getStatusColor(_application.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_application.expectedDisbursementDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Expected Disbursement: ', // Add to translations
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat.yMMMd(localizations.locale.toString()).format(_application.expectedDisbursementDate!),
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final localizations = AppLocalizations.of(context);
    
    // Sort timeline by date descending
    final sortedEvents = List<ApplicationTimelineEvent>.from(_application.timeline)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        final isLast = index == sortedEvents.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(event.status),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey[300],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(event.status),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd(localizations.locale.toString()).add_jm().format(event.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(event.description),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.submitted:
        return Colors.blue;
      case ApplicationStatus.underReview:
        return Colors.orange;
      case ApplicationStatus.approved:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
      case ApplicationStatus.disbursed:
        return Colors.purple;
    }
  }

  String _getStatusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.disbursed:
        return 'Disbursed';
    }
  }
}
