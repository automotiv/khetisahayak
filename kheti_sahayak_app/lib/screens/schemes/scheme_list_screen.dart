import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/services/scheme_service.dart';
import 'package:kheti_sahayak_app/screens/schemes/scheme_detail_screen.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';

class SchemeListScreen extends StatefulWidget {
  const SchemeListScreen({Key? key}) : super(key: key);

  @override
  _SchemeListScreenState createState() => _SchemeListScreenState();
}

class _SchemeListScreenState extends State<SchemeListScreen> {
  List<Scheme> _schemes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Filters
  double? _farmSize;
  String? _crop;
  String? _state;
  String? _district;
  double? _income;
  String? _landOwnership;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSchemes();
  }

  Future<void> _fetchSchemes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final schemes = await SchemeService.getSchemes(
        farmSize: _farmSize,
        crop: _crop,
        state: _state,
        district: _district,
        income: _income,
        landOwnership: _landOwnership,
      );
      
      setState(() {
        _schemes = schemes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching schemes: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load schemes. Please try again.')),
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Schemes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Farm Size (Acres)'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _farmSize = double.tryParse(val),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Crop'),
                onChanged: (val) => _crop = val.isNotEmpty ? val : null,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'State'),
                onChanged: (val) => _state = val.isNotEmpty ? val : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Reset filters
              _farmSize = null;
              _crop = null;
              _state = null;
              _district = null;
              _income = null;
              _landOwnership = null;
              Navigator.pop(context);
              _fetchSchemes();
            },
            child: Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchSchemes();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSchemes = _schemes.where((scheme) {
      final query = _searchQuery.toLowerCase();
      return scheme.name.toLowerCase().contains(query) ||
             scheme.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Government Schemes'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search schemes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredSchemes.isEmpty
                    ? Center(child: Text('No schemes found.'))
                    : ListView.builder(
                        itemCount: filteredSchemes.length,
                        itemBuilder: (context, index) {
                          final scheme = filteredSchemes[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Text(scheme.name, style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                scheme.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SchemeDetailScreen(scheme: scheme),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
