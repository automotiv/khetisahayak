import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/models/user.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/services/eligibility_service.dart';
import 'package:kheti_sahayak_app/services/document_checklist_service.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/providers/user_provider.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';

class SchemeDetailScreen extends StatefulWidget {
  final Scheme scheme;

  const SchemeDetailScreen({Key? key, required this.scheme}) : super(key: key);

  @override
  _SchemeDetailScreenState createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends State<SchemeDetailScreen> {
  EligibilityResult? _eligibilityResult;
  bool _isLoadingEligibility = true;
  final FieldService _fieldService = FieldService();
  final Map<String, bool> _checkedDocuments = {};

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    try {
      final fields = await _fieldService.getFields();
      
      setState(() {
        _eligibilityResult = EligibilityService.checkEligibility(
          widget.scheme,
          user,
          fields,
        );
        _isLoadingEligibility = false;
      });
    } catch (e) {
      print('Error checking eligibility: $e');
      setState(() {
        _isLoadingEligibility = false;
      });
    }
  }

  void _generateChecklistPdf() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to generate checklist.')),
      );
      return;
    }

    try {
      await DocumentChecklistService.generateChecklistPdf(
        widget.scheme,
        user,
        _checkedDocuments,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checklist generated successfully!')),
      );
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate checklist.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final checklist = DocumentChecklistService.getChecklistForScheme(scheme);

    return Scaffold(
      appBar: AppBar(
        title: Text(scheme.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eligibility Status Card
            if (_isLoadingEligibility)
              Center(child: CircularProgressIndicator())
            else if (_eligibilityResult != null)
              Card(
                color: Color(EligibilityService.getStatusColor(_eligibilityResult!.status)).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _eligibilityResult!.status == EligibilityStatus.eligible
                                ? Icons.check_circle
                                : _eligibilityResult!.status == EligibilityStatus.notEligible
                                    ? Icons.cancel
                                    : Icons.info,
                            color: Color(EligibilityService.getStatusColor(_eligibilityResult!.status)),
                          ),
                          SizedBox(width: 8),
                          Text(
                            EligibilityService.getStatusText(_eligibilityResult!.status),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(EligibilityService.getStatusColor(_eligibilityResult!.status)),
                            ),
                          ),
                        ],
                      ),
                      if (_eligibilityResult!.missingCriteria.isNotEmpty) ...[
                        SizedBox(height: 10),
                        Text('Missing Criteria:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._eligibilityResult!.missingCriteria.map((e) => Text('• $e')),
                      ],
                      if (_eligibilityResult!.suggestions.isNotEmpty) ...[
                        SizedBox(height: 10),
                        Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._eligibilityResult!.suggestions.map((e) => Text('• $e')),
                      ],
                    ],
                  ),
                ),
              ),
            SizedBox(height: 20),

            // Scheme Details
            Text('Description', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text(scheme.description),
            SizedBox(height: 20),

            if (scheme.benefits != null) ...[
              Text('Benefits', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              Text(scheme.benefits!),
              SizedBox(height: 20),
            ],

            if (scheme.eligibility != null) ...[
              Text('Eligibility Criteria', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 8),
              Text(scheme.eligibility!),
              SizedBox(height: 20),
            ],

            // Document Checklist
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Document Checklist', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: Icon(Icons.picture_as_pdf),
                  onPressed: _generateChecklistPdf,
                  tooltip: 'Download Checklist',
                ),
              ],
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: checklist.length,
              itemBuilder: (context, index) {
                final item = checklist[index];
                return CheckboxListTile(
                  title: Text(item),
                  value: _checkedDocuments[item] ?? false,
                  onChanged: (bool? value) {
                    setState(() {
                      _checkedDocuments[item] = value ?? false;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 20),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement apply functionality or open link
                  if (scheme.link != null) {
                    // Launch URL
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening application portal...')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Application link not available.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Apply Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
