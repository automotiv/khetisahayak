import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/input_recommendation.dart';
import 'package:kheti_sahayak_app/services/input_advisor_service.dart';
import 'package:kheti_sahayak_app/services/cart_service.dart';
import 'package:kheti_sahayak_app/widgets/activity_type_dropdown.dart'; // Reusing for style if needed, but likely need generic dropdown

class InputAdvisorScreen extends StatefulWidget {
  const InputAdvisorScreen({Key? key}) : super(key: key);

  @override
  _InputAdvisorScreenState createState() => _InputAdvisorScreenState();
}

class _InputAdvisorScreenState extends State<InputAdvisorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputAdvisorService = InputAdvisorService();
  
  String? _selectedCrop;
  String? _selectedSoilType;
  final _farmHistoryController = TextEditingController();
  
  InputRecommendation? _recommendation;
  bool _isLoading = false;

  final List<String> _crops = ['Wheat', 'Rice', 'Corn', 'Cotton', 'Sugarcane', 'Soybean'];
  final List<String> _soilTypes = ['Clay', 'Loam', 'Sandy', 'Silt', 'Peat', 'Chalk'];

  Future<void> _getRecommendations() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _recommendation = null;
    });

    try {
      final result = await _inputAdvisorService.getRecommendations(
        cropName: _selectedCrop!,
        soilType: _selectedSoilType!,
        farmHistory: _farmHistoryController.text,
      );

      setState(() {
        _recommendation = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting recommendations: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(String productId, String productName) async {
    try {
      await CartService.addToCart(productId: productId, quantity: 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$productName added to cart'),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              // Navigate to cart (optional, or just let user go via home)
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Advisor'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildForm(),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_recommendation != null)
              _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Get Optimized Recommendations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCrop,
                decoration: const InputDecoration(
                  labelText: 'Select Crop',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grass),
                ),
                items: _crops.map((crop) {
                  return DropdownMenuItem(value: crop, child: Text(crop));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCrop = value),
                validator: (value) => value == null ? 'Please select a crop' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSoilType,
                decoration: const InputDecoration(
                  labelText: 'Select Soil Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.landscape),
                ),
                items: _soilTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _selectedSoilType = value),
                validator: (value) => value == null ? 'Please select soil type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _farmHistoryController,
                decoration: const InputDecoration(
                  labelText: 'Farm History (Optional)',
                  hintText: 'e.g., Previous crop was Wheat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.history),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _getRecommendations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Get Recommendations',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalysisCard(),
        const SizedBox(height: 24),
        const Text(
          'Recommended Seeds',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._recommendation!.recommendedSeeds.map((p) => _buildProductCard(p)).toList(),
        const SizedBox(height: 24),
        const Text(
          'Recommended Fertilizers',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._recommendation!.recommendedFertilizers.map((p) => _buildProductCard(p)).toList(),
      ],
    );
  }

  Widget _buildAnalysisCard() {
    final analysis = _recommendation!.costBenefitAnalysis;
    return Card(
      color: Colors.green[50],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green[800]),
                const SizedBox(width: 8),
                Text(
                  'Yield & Cost Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Expected Yield Improvement:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            Text(
              _recommendation!.expectedYieldImprovement,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAnalysisItem('Est. Cost', '₹${analysis.estimatedCost.toStringAsFixed(0)}'),
                _buildAnalysisItem('Est. Revenue', '₹${analysis.estimatedRevenue.toStringAsFixed(0)}'),
                _buildAnalysisItem('Net Profit', '₹${analysis.netProfit.toStringAsFixed(0)}', isHighlight: true),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ROI: ${analysis.roi}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.green[800] : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(RecommendedProduct recommendedProduct) {
    final product = recommendedProduct.product;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Icon(
                product.category == 'Seeds' ? Icons.grass : Icons.eco,
                color: Colors.green[700],
              ),
            ),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(product.description ?? ''),
            trailing: Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Why: ${recommendedProduct.reason}',
                          style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Competitor Comparison:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                ...recommendedProduct.competitorComparison.map((comp) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.compare_arrows, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'vs ${comp.name} (₹${comp.price.toStringAsFixed(0)}): ${comp.difference}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addToCart(product.id, product.name),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add to Cart'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
