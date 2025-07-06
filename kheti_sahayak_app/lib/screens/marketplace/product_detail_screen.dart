import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
  final CarouselController _carouselController = CarouselController();
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = false;
  bool _isFavorite = false;
  
  // Mock product data - replace with actual API call
  final Map<String, dynamic> _product = {
    'id': 'prod_123',
    'name': 'Organic Tomato Seeds',
    'seller': 'Green Valley Farms',
    'price': 120.0,
    'originalPrice': 150.0,
    'discount': 20,
    'rating': 4.5,
    'reviewCount': 128,
    'inStock': true,
    'sold': 450,
    'description': 'High-quality organic tomato seeds that yield delicious, juicy tomatoes. These seeds are non-GMO and have a high germination rate. Perfect for home gardens and commercial farming.',
    'specifications': {
      'Brand': 'Organic Harvest',
      'Seed Type': 'Heirloom',
      'Germination Rate': '90%',
      'Time to Harvest': '70-80 days',
      'Planting Season': 'Year Round',
      'Watering': 'Regular',
      'Sunlight': 'Full Sun',
      'Suitable For': 'Pots, Terrace, Balcony',
    },
    'images': [
      'https://example.com/tomato1.jpg',
      'https://example.com/tomato2.jpg',
      'https://example.com/tomato3.jpg',
    ],
    'reviews': [
      {
        'user': 'Rahul Sharma',
        'rating': 5,
        'date': '2 weeks ago',
        'comment': 'Excellent quality seeds. 90% germination rate. Highly recommended!',
      },
      {
        'user': 'Priya Patel',
        'rating': 4,
        'date': '1 month ago',
        'comment': 'Good seeds, but took longer to germinate than expected.',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() => _isLoading = true);
    // TODO: Fetch product details from API using widget.productId
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    setState(() => _isLoading = false);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image gallery
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image carousel
                  CarouselSlider.builder(
                    carouselController: _carouselController,
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: _product['images'].length > 1,
                      autoPlay: _product['images'].length > 1,
                      autoPlayInterval: const Duration(seconds: 5),
                      onPageChanged: (index, reason) {
                        setState(() => _currentImageIndex = index);
                      },
                    ),
                    itemCount: _product['images'].length,
                    itemBuilder: (context, index, realIndex) {
                      return Image.network(
                        _product['images'][index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colorScheme.surfaceVariant,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined, size: 48),
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
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  
                  // Image indicators
                  if (_product['images'].length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _product['images'].asMap().entries.map((entry) {
                          return GestureDetector(
                            onTap: () => _carouselController.animateToPage(entry.key),
                            child: Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == entry.key
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          );
                        }).toList(),
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
                  shape: BoxShape.circle,
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
                    shape: BoxShape.circle,
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
                    shape: BoxShape.circle,
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
                  // Price and discount
                  Row(
                    children: [
                      Text(
                        '₹${_product['price']}'
                            .replaceAllMapped(
                              RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
                              (match) => '${match[1]},',
                            ),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_product['discount'] > 0)
                        Text(
                          '₹${_product['originalPrice']}'
                              .replaceAllMapped(
                                RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
                                (match) => '${match[1]},',
                              ),
                          style: textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.hintColor,
                          ),
                        ),
                      if (_product['discount'] > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_product['discount']}% OFF',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Product name
                  Text(
                    _product['name'],
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // Seller and rating
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Seller
                      Row(
                        children: [
                          const Icon(Icons.store_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _product['seller'],
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${_product['rating']} (${_product['reviewCount']})',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Sold count
                  const SizedBox(height: 8),
                  Text(
                    '${_product['sold']}+ sold',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  
                  // Quantity selector
                  const SizedBox(height: 24),
                  Text(
                    'Quantity',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _quantity < 10
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  
                  // Description
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ReadMoreText(
                    _product['description'],
                    trimLines: 3,
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
                  
                  // Specifications
                  const SizedBox(height: 24),
                  Text(
                    'Specifications',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _product['specifications'].length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
                      itemBuilder: (context, index) {
                        final key = _product['specifications'].keys.elementAt(index);
                        final value = _product['specifications'][key];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  key,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ),
                              const Text(':  '),
                              Expanded(
                                child: Text(
                                  value,
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Reviews
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews (${_product['reviews'].length})',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all reviews
                        },
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  
                  if (_product['reviews'].isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No reviews yet. Be the first to review!',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._product['reviews'].take(2).map((review) => _buildReviewCard(review, theme)),
                  
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Add to cart button
              Expanded(
                child: OutlinedButton(
                  onPressed: _addToCart,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add to Cart'),
                ),
              ),
              const SizedBox(width: 16),
              // Buy now button
              Expanded(
                child: PrimaryButton(
                  onPressed: _buyNow,
                  text: 'Buy Now',
                ),
              ),
            ],
          ),
        ),
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
