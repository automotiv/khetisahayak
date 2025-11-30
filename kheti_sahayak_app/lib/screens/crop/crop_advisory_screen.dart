
import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';

class CropAdvisoryScreen extends StatefulWidget {
  const CropAdvisoryScreen({Key? key}) : super(key: key);

  @override
  _CropAdvisoryScreenState createState() => _CropAdvisoryScreenState();
}

class _CropAdvisoryScreenState extends State<CropAdvisoryScreen> {
  late Future<List<dynamic>> _cropsFuture;
  List<dynamic> _allCrops = [];
  List<dynamic> _filteredCrops = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cropsFuture = ApiService().getCrops();
    _cropsFuture.then((crops) {
      setState(() {
        _allCrops = crops;
        _filteredCrops = crops;
      });
    });
    _searchController.addListener(_filterCrops);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCrops() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCrops = _allCrops.where((crop) {
        return crop['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Advisory'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Crops',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _cropsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _filteredCrops.length,
                    itemBuilder: (context, index) {
                      final crop = _filteredCrops[index];
                      final cropName = crop['name'];
                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                        child: ListTile(
                          leading: const Icon(Icons.food_bank_outlined, color: Colors.yellow), // Changed this line only
                          title: Text(cropName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Tap to view advisory'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.cropDetail, arguments: cropName);
                          },
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('No crop data available.'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
