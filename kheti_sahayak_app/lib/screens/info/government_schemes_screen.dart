import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/services/scheme_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/screens/info/document_checklist_screen.dart';
import 'package:kheti_sahayak_app/services/eligibility_service.dart';
import 'package:kheti_sahayak_app/services/auth_service.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/models/user.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/screens/info/scheme_comparison_screen.dart';
import 'package:kheti_sahayak_app/models/application.dart';
import 'package:kheti_sahayak_app/models/application_timeline_event.dart';
import 'package:kheti_sahayak_app/services/application_service.dart';

class GovernmentSchemesScreen extends StatefulWidget {
  const GovernmentSchemesScreen({Key? key}) : super(key: key);

  @override
  _GovernmentSchemesScreenState createState() => _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends State<GovernmentSchemesScreen> with SingleTickerProviderStateMixin {
  List<Scheme> _schemes = [];
  List<Scheme> _recentSchemes = [];
  List<Application> _applications = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  User? _user;
  List<Field> _fields = [];

  // Filter state
  double? _filterFarmSize;
  String? _filterCrop;
  String? _filterState;
  String? _filterDistrict;
  double? _filterIncome;
  String? _filterLandOwnership;
  
  // Comparison state
  final Set<int> _selectedSchemesIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadSchemes(),
      _loadRecentSchemes(),
      _loadUserAndFields(),
      _loadApplications(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserAndFields() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        final fields = await FieldService().getFields(); // Assuming getFields exists and returns List<Field>
        if (mounted) {
          setState(() {
            _user = user;
            _fields = fields;
          });
        }
      }
    } catch (e) {
      // Handle error gently
      print('Error loading user/fields: $e');
    }
  }

  Future<void> _loadSchemes({bool forceRefresh = false}) async {
    // setState(() => _isLoading = true); // Handled in _loadData
    final schemes = await SchemeService.getSchemes(
      forceRefresh: forceRefresh,
      farmSize: _filterFarmSize,
      crop: _filterCrop,
      state: _filterState,
      district: _filterDistrict,
      income: _filterIncome,
      landOwnership: _filterLandOwnership,
    );
    if (mounted) {
      setState(() {
        _schemes = schemes;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentSchemes() async {
    final recents = await SchemeService.getRecentSchemes();
    if (mounted) {
      setState(() {
        _recentSchemes = recents;
      });
    }
  }

  Future<void> _loadApplications() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        // Initialize dummy data for demo
        await ApplicationService.initializeDummyData(user.id);
        final apps = await ApplicationService.getApplicationsForUser(user.id);
        if (mounted) {
          setState(() {
            _applications = apps;
          });
        }
      }
    } catch (e) {
      print('Error loading applications: $e');
    }
  }

  Future<void> _searchSchemes(String query) async {
    if (query.isEmpty) {
      _loadSchemes();
      return;
    }
    setState(() => _isLoading = true);
    final results = await SchemeService.searchSchemes(query);
    if (mounted) {
      setState(() {
        _schemes = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.governmentSchemes),
        backgroundColor: Colors.green[700],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.allSchemes),
            Tab(text: localizations.recentlyViewed),
            Tab(text: 'My Applications'), // Add to translations
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllSchemesTab(localizations),
          _buildRecentSchemesTab(localizations),
          _buildApplicationsTab(localizations),
        ],
      ),
      floatingActionButton: _selectedSchemesIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _navigateToComparison,
              label: Text('${localizations.compare} (${_selectedSchemesIds.length})'),
              icon: const Icon(Icons.compare_arrows),
              backgroundColor: Colors.orange,
            )
          : null,
    );
  }

  void _navigateToComparison() {
    final selectedSchemes = _schemes.where((s) => _selectedSchemesIds.contains(s.id)).toList();
    if (selectedSchemes.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SchemeComparisonScreen(schemes: selectedSchemes),
        ),
      );
    }
  }

  Widget _buildAllSchemesTab(AppLocalizations localizations) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
            key: const Key('searchSemantics'),
            label: localizations.searchSchemes,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizations.searchSchemes,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: localizations.close,
                        onPressed: () {
                          _searchController.clear();
                          _searchSchemes('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                // Debounce could be added here
                _searchSchemes(value);
              },
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter Schemes', // Add to translations
          onPressed: _showFilterBottomSheet,
        ),
      ],
    ),
  ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _loadSchemes(forceRefresh: true),
                  child: _schemes.isEmpty
                      ? Center(child: Text(localizations.noSchemesFound))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _schemes.length,
                          itemBuilder: (context, index) => _buildSchemeCard(_schemes[index], localizations),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentSchemesTab(AppLocalizations localizations) {
    return _recentSchemes.isEmpty
        ? Center(child: Text(localizations.noSchemesFound))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _recentSchemes.length,
            itemBuilder: (context, index) => _buildSchemeCard(_recentSchemes[index], localizations),
          );
  }

  Widget _buildApplicationsTab(AppLocalizations localizations) {
    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Please login to view your applications'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to login
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return const Center(
        child: Text('No applications submitted yet.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _applications.length,
      itemBuilder: (context, index) {
        final app = _applications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              app.schemeName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Status: ${_getStatusText(app.status)}',
                    style: TextStyle(
                      color: _getStatusColor(app.status),
                      fontWeight: FontWeight.bold,
                    )),
                Text('Submitted: ${app.submissionDate.toString().split(' ')[0]}'),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Timeline:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...app.timeline.map((event) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: _getStatusColor(event.status),
                                  ),
                                  if (event != app.timeline.last)
                                    Container(
                                      width: 2,
                                      height: 30,
                                      color: Colors.grey[300],
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getStatusText(event.status),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      event.date.toString().split(' ')[0],
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    Text(event.description),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (app.expectedDisbursementDate != null) ...[
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Expected Disbursement: ${app.expectedDisbursementDate.toString().split(' ')[0]}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStatusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.submitted: return 'Submitted';
      case ApplicationStatus.underReview: return 'Under Review';
      case ApplicationStatus.approved: return 'Approved';
      case ApplicationStatus.rejected: return 'Rejected';
      case ApplicationStatus.disbursed: return 'Disbursed';
    }
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.submitted: return Colors.blue;
      case ApplicationStatus.underReview: return Colors.orange;
      case ApplicationStatus.approved: return Colors.green;
      case ApplicationStatus.rejected: return Colors.red;
      case ApplicationStatus.disbursed: return Colors.purple;
    }
  }

  Widget _buildSchemeCard(Scheme scheme, AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: _selectedSchemesIds.contains(scheme.id) ? Colors.green[50] : null,
      child: ExpansionTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: _selectedSchemesIds.contains(scheme.id),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedSchemesIds.add(scheme.id);
                    } else {
                      _selectedSchemesIds.remove(scheme.id);
                      if (_selectedSchemesIds.isEmpty) _isSelectionMode = false;
                    }
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.compare_arrows),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedSchemesIds.add(scheme.id);
                  });
                },
                tooltip: 'Select for comparison', // Add to translations
              ),
        title: Text(
          scheme.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scheme.category ?? 'General',
              style: TextStyle(color: Colors.green[800]),
            ),
            const SizedBox(height: 4),
            _buildEligibilityBadge(scheme),
          ],
        ),
        onExpansionChanged: (expanded) {
          if (expanded) {
            SchemeService.markSchemeAccessed(scheme.id);
            _loadRecentSchemes(); // Refresh recent list
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    '${localizations.description}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(scheme.description),
                const SizedBox(height: 8),
                if (scheme.deadline != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        'Deadline: ${scheme.deadline.toString().split(' ')[0]}', // Add to translations
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (scheme.benefits != null) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      '${localizations.benefits}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(scheme.benefits!),
                  const SizedBox(height: 8),
                ],
                if (scheme.eligibility != null) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      '${localizations.eligibility}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(scheme.eligibility!),
                  const SizedBox(height: 8),
                ],
                _buildEligibilityAnalysis(scheme),
                if (scheme.link != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DocumentChecklistScreen(scheme: scheme),
                              ),
                            );
                          },
                          icon: const Icon(Icons.checklist),
                          label: const Text('Checklist'), // Add to translations
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: '${localizations.visitWebsite} ${scheme.name}',
                          button: true,
                          child: TextButton.icon(
                            onPressed: () => _launchUrl(scheme.link!),
                            icon: const Icon(Icons.open_in_new),
                            label: Text(localizations.visitWebsite),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green[800], // Darker green for better contrast
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEligibilityBadge(Scheme scheme) {
    final result = EligibilityService.checkEligibility(scheme, _user, _fields);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Color(EligibilityService.getStatusColor(result.status)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Color(EligibilityService.getStatusColor(result.status))),
      ),
      child: Text(
        EligibilityService.getStatusText(result.status),
        style: TextStyle(
          color: Color(EligibilityService.getStatusColor(result.status)),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEligibilityAnalysis(Scheme scheme) {
    final result = EligibilityService.checkEligibility(scheme, _user, _fields);
    
    if (result.status == EligibilityStatus.eligible || result.status == EligibilityStatus.uncertain) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Eligibility Analysis:', // Add to translations
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          ...result.missingCriteria.map((criteria) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(criteria, style: const TextStyle(fontSize: 12))),
              ],
            ),
          )),
          const SizedBox(height: 8),
          const Text(
            'Suggestions:', // Add to translations
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 4),
          ...result.suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text(suggestion, style: const TextStyle(fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    final localizations = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Text(
                        'Filter Schemes', // Add to translations
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildFilterDropdown<String>(
                        label: 'State', // Add to translations
                        value: _filterState,
                        items: ['Punjab', 'Haryana', 'Uttar Pradesh', 'Madhya Pradesh'], // TODO: Fetch dynamically
                        onChanged: (val) => setState(() => _filterState = val),
                      ),
                      _buildFilterDropdown<String>(
                        label: 'Crop', // Add to translations
                        value: _filterCrop,
                        items: ['Wheat', 'Rice', 'Cotton', 'Sugarcane'], // TODO: Fetch dynamically
                        onChanged: (val) => setState(() => _filterCrop = val),
                      ),
                      _buildFilterTextField(
                        label: 'Farm Size (Acres)', // Add to translations
                        value: _filterFarmSize?.toString(),
                        onChanged: (val) => setState(() => _filterFarmSize = double.tryParse(val)),
                        keyboardType: TextInputType.number,
                      ),
                      _buildFilterTextField(
                        label: 'Annual Income (Rs)', // Add to translations
                        value: _filterIncome?.toString(),
                        onChanged: (val) => setState(() => _filterIncome = double.tryParse(val)),
                        keyboardType: TextInputType.number,
                      ),
                      _buildFilterDropdown<String>(
                        label: 'Land Ownership', // Add to translations
                        value: _filterLandOwnership,
                        items: ['Owner', 'Tenant', 'Sharecropper'],
                        onChanged: (val) => setState(() => _filterLandOwnership = val),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _filterFarmSize = null;
                                  _filterCrop = null;
                                  _filterState = null;
                                  _filterDistrict = null;
                                  _filterIncome = null;
                                  _filterLandOwnership = null;
                                });
                              },
                              child: Text(localizations.clear),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _loadSchemes(forceRefresh: true);
                              },
                              child: Text(localizations.apply),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      setState(() {}); 
    });
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFilterTextField({
    required String label,
    required String? value,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }
}
