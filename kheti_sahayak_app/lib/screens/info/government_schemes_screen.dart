import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/services/scheme_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GovernmentSchemesScreen extends StatefulWidget {
  const GovernmentSchemesScreen({Key? key}) : super(key: key);

  @override
  _GovernmentSchemesScreenState createState() => _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends State<GovernmentSchemesScreen> with SingleTickerProviderStateMixin {
  List<Scheme> _schemes = [];
  List<Scheme> _recentSchemes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSchemes();
    _loadRecentSchemes();
  }

  Future<void> _loadSchemes({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final schemes = await SchemeService.getSchemes(forceRefresh: forceRefresh);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Schemes'),
        backgroundColor: Colors.green[700],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Schemes'),
            Tab(text: 'Recently Viewed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllSchemesTab(),
          _buildRecentSchemesTab(),
        ],
      ),
    );
  }

  Widget _buildAllSchemesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search schemes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
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
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _loadSchemes(forceRefresh: true),
                  child: _schemes.isEmpty
                      ? const Center(child: Text('No schemes found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _schemes.length,
                          itemBuilder: (context, index) => _buildSchemeCard(_schemes[index]),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentSchemesTab() {
    return _recentSchemes.isEmpty
        ? const Center(child: Text('No recently viewed schemes.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _recentSchemes.length,
            itemBuilder: (context, index) => _buildSchemeCard(_recentSchemes[index]),
          );
  }

  Widget _buildSchemeCard(Scheme scheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          scheme.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          scheme.category ?? 'General',
          style: TextStyle(color: Colors.green[700]),
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
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(scheme.description),
                const SizedBox(height: 8),
                if (scheme.benefits != null) ...[
                  const Text(
                    'Benefits:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(scheme.benefits!),
                  const SizedBox(height: 8),
                ],
                if (scheme.eligibility != null) ...[
                  const Text(
                    'Eligibility:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(scheme.eligibility!),
                  const SizedBox(height: 8),
                ],
                if (scheme.link != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _launchUrl(scheme.link!),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Visit Website'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
