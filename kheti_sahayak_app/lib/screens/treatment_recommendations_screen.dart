import 'package:flutter/material.dart';
import '../models/treatment_model.dart';
import '../services/diagnostic_service.dart';
import '../widgets/treatment_card.dart';

/// Treatment Recommendations Screen
///
/// Displays disease information and treatment recommendations
/// for a specific diagnostic result
class TreatmentRecommendationsScreen extends StatefulWidget {
  final int diagnosticId;

  const TreatmentRecommendationsScreen({
    Key? key,
    required this.diagnosticId,
  }) : super(key: key);

  @override
  State<TreatmentRecommendationsScreen> createState() =>
      _TreatmentRecommendationsScreenState();
}

class _TreatmentRecommendationsScreenState
    extends State<TreatmentRecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late final DiagnosticService _diagnosticService;
  late TabController _tabController;

  TreatmentRecommendationsResponse? _recommendations;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _diagnosticService = DiagnosticService();
    _tabController = TabController(length: 3, vsync: this);
    _loadTreatments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTreatments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recommendations = await _diagnosticService.getTreatmentRecommendations(
        widget.diagnosticId,
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('उपचार सिफारिशें'),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTreatments,
            tooltip: 'साझा करें',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'उपचार विकल्प लोड हो रहे हैं...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'उपचार लोड करने में त्रुटि',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTreatments,
                icon: const Icon(Icons.refresh),
                label: const Text('पुनः प्रयास करें'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendations == null) {
      return const Center(child: Text('कोई डेटा नहीं'));
    }

    return RefreshIndicator(
      onRefresh: _loadTreatments,
      child: CustomScrollView(
        slivers: [
          _buildDiseaseInfoSection(),
          _buildTreatmentTabsSection(),
        ],
      ),
    );
  }

  Widget _buildDiseaseInfoSection() {
    final disease = _recommendations!.disease;

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[700]!, Colors.green[500]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disease Name
              Text(
                disease.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (disease.scientificName != null) ...[
                const SizedBox(height: 4),
                Text(
                  disease.scientificName!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              ],
              if (disease.cropType != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${disease.cropType}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              // Severity
              if (disease.severity != null) ...[
                const SizedBox(height: 16),
                _buildSeverityBadge(disease.severity!),
              ],

              // Description
              if (disease.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  disease.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],

              // Symptoms
              if (disease.symptoms != null) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  '🔍 लक्षण',
                  disease.symptoms!,
                  Colors.blue[100]!,
                ),
              ],

              // Prevention
              if (disease.prevention != null) ...[
                const SizedBox(height: 12),
                _buildInfoCard(
                  '🛡️ रोकथाम',
                  disease.prevention!,
                  Colors.orange[100]!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color badgeColor;
    String label;

    switch (severity.toLowerCase()) {
      case 'low':
        badgeColor = Colors.green;
        label = 'कम गंभीर';
        break;
      case 'moderate':
        badgeColor = Colors.orange;
        label = 'मध्यम';
        break;
      case 'high':
        badgeColor = Colors.deepOrange;
        label = 'गंभीर';
        break;
      case 'severe':
        badgeColor = Colors.red;
        label = 'अत्यधिक गंभीर';
        break;
      default:
        badgeColor = Colors.grey;
        label = severity;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentTabsSection() {
    final treatmentsByType = _recommendations!.treatmentsByType;
    final tabs = <Widget>[];
    final tabViews = <Widget>[];

    // All Treatments Tab
    tabs.add(const Tab(text: 'सभी'));
    tabViews.add(_buildTreatmentList(_recommendations!.treatments));

    // Organic Treatments Tab
    if (_recommendations!.organicTreatments.isNotEmpty) {
      tabs.add(const Tab(text: '🌱 जैविक'));
      tabViews.add(_buildTreatmentList(_recommendations!.organicTreatments));
    }

    // Chemical Treatments Tab
    if (_recommendations!.chemicalTreatments.isNotEmpty) {
      tabs.add(const Tab(text: '⚗️ रासायनिक'));
      tabViews.add(_buildTreatmentList(_recommendations!.chemicalTreatments));
    }

    _tabController = TabController(length: tabs.length, vsync: this);

    return SliverToBoxAdapter(
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.green[700],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green[700],
              tabs: tabs,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: TabBarView(
              controller: _tabController,
              children: tabViews,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentList(List<TreatmentModel> treatments) {
    if (treatments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'कोई उपचार उपलब्ध नहीं',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Sort by effectiveness rating
    final sortedTreatments = List<TreatmentModel>.from(treatments)
      ..sort((a, b) =>
          (b.effectivenessRating ?? 0).compareTo(a.effectivenessRating ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedTreatments.length,
      itemBuilder: (context, index) {
        return TreatmentCard(
          treatment: sortedTreatments[index],
          isRecommended: index == 0, // First treatment is most effective
        );
      },
    );
  }

  void _shareTreatments() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('साझा करने की सुविधा जल्द आ रही है')),
    );
  }
}
