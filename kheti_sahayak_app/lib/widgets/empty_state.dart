import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';

/// Empty State Widget
///
/// Reusable component for displaying empty states across the app (#381)
class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? customTitle;
  final String? customSubtitle;
  final IconData? customIcon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? customIllustration;

  const EmptyStateWidget({
    super.key,
    required this.type,
    this.customTitle,
    this.customSubtitle,
    this.customIcon,
    this.buttonText,
    this.onButtonPressed,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = _getConfig();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            customIllustration ??
                _buildIllustration(
                  context,
                  customIcon ?? config.icon,
                  config.iconColor ?? colorScheme.primary.withOpacity(0.6),
                ),
            const SizedBox(height: 24),

            // Title
            Text(
              customTitle ?? config.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              customSubtitle ?? config.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action button
            if (buttonText != null && onButtonPressed != null)
              SizedBox(
                width: 220,
                child: PrimaryButton(
                  onPressed: onButtonPressed!,
                  text: buttonText!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(BuildContext context, IconData icon, Color color) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decorative circles
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main icon
          Icon(
            icon,
            size: 56,
            color: color,
          ),
        ],
      ),
    );
  }

  _EmptyStateConfig _getConfig() {
    switch (type) {
      case EmptyStateType.noProducts:
        return _EmptyStateConfig(
          icon: Icons.shopping_bag_outlined,
          title: 'No Products Found',
          subtitle: 'There are no products matching your criteria. Try adjusting your filters or search terms.',
          iconColor: Colors.orange,
        );

      case EmptyStateType.noSearchResults:
        return _EmptyStateConfig(
          icon: Icons.search_off_rounded,
          title: 'No Results Found',
          subtitle: 'We couldn\'t find anything matching your search. Try different keywords or check your spelling.',
          iconColor: Colors.blue,
        );

      case EmptyStateType.emptyCart:
        return _EmptyStateConfig(
          icon: Icons.shopping_cart_outlined,
          title: 'Your Cart is Empty',
          subtitle: 'Looks like you haven\'t added any items to your cart yet. Start shopping to add products!',
          iconColor: Colors.green,
        );

      case EmptyStateType.noOrders:
        return _EmptyStateConfig(
          icon: Icons.receipt_long_outlined,
          title: 'No Orders Yet',
          subtitle: 'You haven\'t placed any orders. Browse our marketplace to find great agricultural products!',
          iconColor: Colors.purple,
        );

      case EmptyStateType.noDiagnostics:
        return _EmptyStateConfig(
          icon: Icons.camera_alt_outlined,
          title: 'No Diagnostics Yet',
          subtitle: 'Start by taking a photo of your crop to get instant disease detection and treatment recommendations.',
          iconColor: Colors.teal,
        );

      case EmptyStateType.noNotifications:
        return _EmptyStateConfig(
          icon: Icons.notifications_none_outlined,
          title: 'No Notifications',
          subtitle: 'You\'re all caught up! We\'ll notify you when there\'s something new.',
          iconColor: Colors.amber,
        );

      case EmptyStateType.noReviews:
        return _EmptyStateConfig(
          icon: Icons.rate_review_outlined,
          title: 'No Reviews Yet',
          subtitle: 'Be the first to share your experience with this product and help other farmers!',
          iconColor: Colors.deepOrange,
        );

      case EmptyStateType.noEducationalContent:
        return _EmptyStateConfig(
          icon: Icons.school_outlined,
          title: 'No Content Available',
          subtitle: 'Educational content for this topic is coming soon. Check back later for farming tips and guides.',
          iconColor: Colors.indigo,
        );

      case EmptyStateType.noConnection:
        return _EmptyStateConfig(
          icon: Icons.wifi_off_rounded,
          title: 'No Internet Connection',
          subtitle: 'Please check your internet connection and try again. Some features require an active connection.',
          iconColor: Colors.red,
        );

      case EmptyStateType.error:
        return _EmptyStateConfig(
          icon: Icons.error_outline_rounded,
          title: 'Something Went Wrong',
          subtitle: 'An unexpected error occurred. Please try again or contact support if the problem persists.',
          iconColor: Colors.red,
        );

      case EmptyStateType.noFavorites:
        return _EmptyStateConfig(
          icon: Icons.favorite_border_outlined,
          title: 'No Favorites Yet',
          subtitle: 'Save your favorite products here for easy access. Tap the heart icon on any product to add it.',
          iconColor: Colors.pink,
        );

      case EmptyStateType.comingSoon:
        return _EmptyStateConfig(
          icon: Icons.construction_rounded,
          title: 'Coming Soon',
          subtitle: 'We\'re working hard to bring this feature to you. Stay tuned for updates!',
          iconColor: Colors.grey,
        );

      case EmptyStateType.sellProducts:
        return _EmptyStateConfig(
          icon: Icons.add_business_outlined,
          title: 'Sell Your Products',
          subtitle: 'List your agricultural products to reach more customers and grow your business.',
          iconColor: Colors.green,
        );

      case EmptyStateType.noHistory:
        return _EmptyStateConfig(
          icon: Icons.history_rounded,
          title: 'No History',
          subtitle: 'Your activity history will appear here. Start using the app to see your history.',
          iconColor: Colors.blueGrey,
        );

      case EmptyStateType.noWeatherData:
        return _EmptyStateConfig(
          icon: Icons.cloud_off_rounded,
          title: 'Weather Unavailable',
          subtitle: 'Unable to fetch weather data. Please check your location settings and try again.',
          iconColor: Colors.cyan,
        );
    }
  }
}

/// Empty state types
enum EmptyStateType {
  noProducts,
  noSearchResults,
  emptyCart,
  noOrders,
  noDiagnostics,
  noNotifications,
  noReviews,
  noEducationalContent,
  noConnection,
  error,
  noFavorites,
  comingSoon,
  sellProducts,
  noHistory,
  noWeatherData,
}

/// Configuration for empty state
class _EmptyStateConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;

  _EmptyStateConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
  });
}

/// Quick empty state builders for common cases
class EmptyStates {
  static Widget noProducts({VoidCallback? onRetry}) => EmptyStateWidget(
        type: EmptyStateType.noProducts,
        buttonText: onRetry != null ? 'Reset Filters' : null,
        onButtonPressed: onRetry,
      );

  static Widget noSearchResults({required VoidCallback onClear}) =>
      EmptyStateWidget(
        type: EmptyStateType.noSearchResults,
        buttonText: 'Clear Search',
        onButtonPressed: onClear,
      );

  static Widget emptyCart({required VoidCallback onShop}) => EmptyStateWidget(
        type: EmptyStateType.emptyCart,
        buttonText: 'Start Shopping',
        onButtonPressed: onShop,
      );

  static Widget noOrders({required VoidCallback onBrowse}) => EmptyStateWidget(
        type: EmptyStateType.noOrders,
        buttonText: 'Browse Products',
        onButtonPressed: onBrowse,
      );

  static Widget noDiagnostics({required VoidCallback onScan}) =>
      EmptyStateWidget(
        type: EmptyStateType.noDiagnostics,
        buttonText: 'Scan Crop',
        onButtonPressed: onScan,
      );

  static Widget noConnection({required VoidCallback onRetry}) =>
      EmptyStateWidget(
        type: EmptyStateType.noConnection,
        buttonText: 'Retry',
        onButtonPressed: onRetry,
      );

  static Widget error({required VoidCallback onRetry}) => EmptyStateWidget(
        type: EmptyStateType.error,
        buttonText: 'Try Again',
        onButtonPressed: onRetry,
      );

  static Widget sellProducts({required VoidCallback onAdd}) => EmptyStateWidget(
        type: EmptyStateType.sellProducts,
        buttonText: 'Add Product',
        onButtonPressed: onAdd,
      );

  static Widget comingSoon() => const EmptyStateWidget(
        type: EmptyStateType.comingSoon,
      );

  static Widget noNotifications() => const EmptyStateWidget(
        type: EmptyStateType.noNotifications,
      );

  static Widget noFavorites({required VoidCallback onBrowse}) =>
      EmptyStateWidget(
        type: EmptyStateType.noFavorites,
        buttonText: 'Browse Products',
        onButtonPressed: onBrowse,
      );
}
