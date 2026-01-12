import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/wishlist.dart';
import 'package:kheti_sahayak_app/services/wishlist_service.dart';
import 'package:kheti_sahayak_app/services/cart_service.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  Wishlist? _wishlist;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final wishlist = await WishlistService.getWishlist();
      if (mounted) {
        setState(() {
          _wishlist = wishlist;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFromWishlist(WishlistItem item) async {
    try {
      await WishlistService.removeFromWishlist(item.productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.productName} removed from wishlist'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await WishlistService.addToWishlist(item.productId);
                _loadWishlist();
              },
            ),
          ),
        );
        _loadWishlist();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addToCart(WishlistItem item) async {
    try {
      await CartService.addToCart(productId: item.productId, quantity: 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.productName} added to cart'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to cart: ${e.toString()}')),
        );
      }
    }
  }

  String _formatPrice(double price) {
    if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(2)} L';
    } else if (price >= 1000) {
      return '₹${price.toStringAsFixed(0)}';
    }
    return '₹${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading wishlist', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadWishlist,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_wishlist == null || _wishlist!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Your wishlist is empty',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Save items you love by tapping the heart icon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.marketplace),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Browse Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWishlist,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _wishlist!.items.length,
        itemBuilder: (context, index) {
          final item = _wishlist!.items[index];
          return _buildWishlistItemCard(item);
        },
      ),
    );
  }

  Widget _buildWishlistItemCard(WishlistItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.productDetail,
            arguments: {'productId': item.productId},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: item.productImage != null
                      ? Image.network(
                          item.productImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.eco, size: 40, color: Colors.green),
                        )
                      : const Icon(Icons.eco, size: 40, color: Colors.green),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category!,
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(item.price),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          item.isAvailable ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: item.isAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isAvailable ? 'In Stock' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: item.isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => _removeFromWishlist(item),
                    tooltip: 'Remove from wishlist',
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(
                      Icons.add_shopping_cart,
                      color: item.isAvailable ? Colors.green[700] : Colors.grey,
                    ),
                    onPressed: item.isAvailable ? () => _addToCart(item) : null,
                    tooltip: 'Add to cart',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
