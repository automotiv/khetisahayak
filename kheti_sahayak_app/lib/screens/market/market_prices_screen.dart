
import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({Key? key}) : super(key: key);

  @override
  _MarketPricesScreenState createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  late Future<List<dynamic>> _pricesFuture;
  List<dynamic> _allPrices = [];
  List<dynamic> _filteredPrices = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pricesFuture = ApiService().getMarketPrices();
    _pricesFuture.then((prices) {
      setState(() {
        _allPrices = prices;
        _filteredPrices = prices;
      });
    });
    _searchController.addListener(_filterPrices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPrices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPrices = _allPrices.where((price) {
        return price['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Prices'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Commodities',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _pricesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _filteredPrices.length,
                    itemBuilder: (context, index) {
                      final item = _filteredPrices[index];
                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                        child: ListTile(
                          leading: const Icon(Icons.food_bank_outlined, color: Colors.yellow), // Changed this line only
                          title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item['price']!),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.marketPriceDetail, arguments: item);
                          },
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('No market price data available.'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
