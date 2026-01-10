import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/application.dart';
import 'package:kheti_sahayak_app/models/application_timeline_event.dart';
import 'package:kheti_sahayak_app/services/application_service.dart';
import 'package:kheti_sahayak_app/services/auth_service.dart';
import 'package:kheti_sahayak_app/screens/tracking/application_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';

class ApplicationTrackingScreen extends StatefulWidget {
  const ApplicationTrackingScreen({super.key});

  @override
  State<ApplicationTrackingScreen> createState() => _ApplicationTrackingScreenState();
}

class _ApplicationTrackingScreenState extends State<ApplicationTrackingScreen> {
  List<Application> _applications = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      // In a real app, we'd get the user ID from AuthService
      // For now, we'll use a dummy ID or fetch from AuthService if available
      final user = await AuthService().getCurrentUser();
      _userId = user?.id ?? 'dummy_user_id';
      
      // Initialize dummy data for testing
      await ApplicationService.initializeDummyData(_userId!);
      
      final apps = await ApplicationService.getApplicationsForUser(_userId!);
      if (mounted) {
        setState(() {
          _applications = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
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
    // Ideally these should be in LanguageService
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'), // Add to translations if possible
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? Center(child: Text(localizations.noData))
              : RefreshIndicator(
                  onRefresh: _loadApplications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _applications.length,
                    itemBuilder: (context, index) {
                      final app = _applications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApplicationDetailsScreen(application: app),
                              ),
                            );
                            _loadApplications(); // Refresh on return
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        app.schemeName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(app.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getStatusColor(app.status),
                                        ),
                                      ),
                                      child: Text(
                                        _getStatusText(app.status),
                                        style: TextStyle(
                                          color: _getStatusColor(app.status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Submitted on: ${DateFormat.yMMMd(localizations.locale.toString()).format(app.submissionDate)}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                if (app.expectedDisbursementDate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Expected Disbursement: ${DateFormat.yMMMd(localizations.locale.toString()).format(app.expectedDisbursementDate!)}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
