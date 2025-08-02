import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:readmore/readmore.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  
  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = false;
  bool _isFavorite = false;
  
  // Product data - will be populated from API
  late Map<String, dynamic> _product;
  
  // Initialize product with default values
  void _initializeProduct() {
    _product = {
      'id': widget.productId,
      'name': 'Loading...',
      'variety': '',
      'season': '',
      'duration': '',
      'price_per_kg': 0.0,
      'yield_per_hectare': '',
      'description': 'Loading product details...',
      'planting_date': '',
      'harvest_date': '',
      'status': '',
      'image_url': 'https://via.placeholder.com/400x300?text=Loading...',
      'gallery': [],
      'requirements': {},
      'pests': [],
      'diseases': [],
    };
  }

  @override
  void initState() {
    super.initState();
    _initializeProduct();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data - in a real app, this would come from an API
      final mockData = {
        'id': widget.productId,
        'name': 'Rice',
        'variety': 'Basmati',
        'season': 'Kharif',
        'duration': '120-150 days',
        'price_per_kg': 25.50,
        'yield_per_hectare': '4-6 tons',
        'description': 'Premium quality basmati rice known for its aroma and long grains. Grown in flooded fields with proper water management.',
        'planting_date': '2023-06-01',
        'harvest_date': '2023-10-15',
        'status': 'Growing',
        'image_url': 'https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
        'gallery': [
          'https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
          'https://images.unsplash.com/photo-1595475207225-4288f6ae566b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
          'https://images.unsplash.com/photo-1500382246541-71b77d1a9e4c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
        ],
        'requirements': {
          'soil': 'Clayey loam with good water retention',
          'temperature': '20-35°C',
          'rainfall': '150-300 cm annually',
          'ph': '5.0-8.0'
        },
        'pests': ['Stem borer', 'Brown plant hopper', 'Leaf folder'],
        'diseases': ['Blast', 'Bacterial blight', 'Sheath blight'],
      };
      
      setState(() => _product = mockData);
      
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            title: 'Error',
            content: 'Failed to load product details. Please try again.',
            buttonText: 'Retry',
            onPressed: _loadProductDetails,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addToCart() {
    // TODO: Implement add to cart functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart')),
    );
  }

  void _buyNow() {
    // TODO: Implement buy now functionality
    Navigator.pushNamed(context, '/checkout');
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Prepare gallery images - use main image if gallery is empty
    final galleryImages = _product['gallery']?.isNotEmpty == true 
        ? List<String>.from(_product['gallery']) 
        : [_product['image_url']];
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Product Images Slider
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: galleryImages.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        galleryImages[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  // Image indicators (only show if more than one image)
                  if (galleryImages.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          galleryImages.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index 
                                  ? colorScheme.primary 
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.share, color: Colors.white),
                ),
                onPressed: () {
                  // TODO: Implement share functionality
                },
              ),
            ],
          ),
          
          // Product details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop name and variety
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _product['name'],
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _product['status'] == 'Growing' 
                              ? Colors.green.withOpacity(0.2) 
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _product['status'],
                          style: textTheme.labelSmall?.copyWith(
                            color: _product['status'] == 'Growing' 
                                ? Colors.green[800]
                                : Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_product['variety'].isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Variety: ${_product['variety']}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                  
                  // Price and season info
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price per kg
                        Row(
                          children: [
                            Text(
                              'Price: ',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${_product['price_per_kg']}/kg',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Season and duration
                        Row(
                          children: [
                            _buildInfoChip(
                              icon: Icons.calendar_today,
                              label: _product['season'],
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Icons.timelapse,
                              label: _product['duration'],
                              theme: theme,
                            ),
                            if (_product['yield_per_hectare'].isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                icon: Icons.agriculture,
                                label: _product['yield_per_hectare'],
                                theme: theme,
                              ),
                            ],
                          ],
                        ),
                        
                        // Planting and harvest dates
                        if (_product['planting_date'].isNotEmpty || _product['harvest_date'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (_product['planting_date'].isNotEmpty) ...[
                                _buildDateInfo(
                                  context: context,
                                  icon: Icons.agriculture_outlined,
                                  label: 'Planted',
                                  date: _product['planting_date'],
                                  theme: theme,
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (_product['harvest_date'].isNotEmpty)
                                _buildDateInfo(
                                  context: context,
                                  icon: Icons.emoji_events_outlined,
                                  label: 'Harvest',
                                  date: _product['harvest_date'],
                                  theme: theme,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Description
                  const SizedBox(height: 24),
                  Text(
                    'About ${_product['name']}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ReadMoreText(
                    _product['description'],
                    trimLines: 4,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: ' Read more',
                    trimExpandedText: ' Show less',
                    moreStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    lessStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    style: textTheme.bodyMedium,
                  ),
                  
                  // Crop Requirements
                  if (_product['requirements'] != null && _product['requirements'].isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Growing Requirements',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_product['requirements']['soil'] != null)
                          _buildRequirementChip(
                            icon: Icons.terrain,
                            label: 'Soil: ${_product['requirements']['soil']}',
                            theme: theme,
                          ),
                        if (_product['requirements']['temperature'] != null)
                          _buildRequirementChip(
                            icon: Icons.thermostat,
                            label: 'Temp: ${_product['requirements']['temperature']}',
                            theme: theme,
                          ),
                        if (_product['requirements']['rainfall'] != null)
                          _buildRequirementChip(
                            icon: Icons.water_drop_outlined,
                            label: 'Rainfall: ${_product['requirements']['rainfall']}',
                            theme: theme,
                          ),
                        if (_product['requirements']['ph'] != null)
                          _buildRequirementChip(
                            icon: Icons.science_outlined,
                            label: 'pH: ${_product['requirements']['ph']}',
                            theme: theme,
                          ),
                      ],
                    ),
                  ],
                  
                  // Pests and Diseases
                  if ((_product['pests'] != null && _product['pests'].isNotEmpty) || 
                      (_product['diseases'] != null && _product['diseases'].isNotEmpty)) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Common Issues',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_product['pests'] != null && _product['pests'].isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.bug_report_outlined, 
                            size: 20, 
                            color: theme.colorScheme.error.withOpacity(0.8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: _product['pests'].map<Widget>((pest) => 
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    pest,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_product['diseases'] != null && _product['diseases'].isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.medical_services_outlined, 
                            size: 20, 
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: _product['diseases'].map<Widget>((disease) => 
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    disease,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  
                  // Gallery
                  if (_product['gallery'] != null && _product['gallery'].length > 1) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Gallery',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _product['gallery'].length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              // TODO: Implement image viewer
                            },
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(_product['gallery'][index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 100), // Extra space at bottom
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }
  
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRequirementChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateInfo({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String date,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            Text(
              _formatDate(date),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
  
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _quantity < 10 ? () => setState(() => _quantity++) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Price',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              Text(
                '₹${(_product['price_per_kg'] * _quantity).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Add to cart button
          Expanded(
            child: PrimaryButton(
              onPressed: _addToCart,
              text: 'Add to Cart',
            ),
          ),
          const SizedBox(width: 12),
          // Buy now button
          Expanded(
            child: PrimaryButton(
              onPressed: _buyNow,
              text: 'Buy Now',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewCard(Map<String, dynamic> review, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  child: Text(
                    review['user'][0],
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['user'],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < review['rating']
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            review['date'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review['comment'],
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
