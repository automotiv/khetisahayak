import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/services/wishlist_service.dart';

class WishlistButton extends StatefulWidget {
  final String productId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback? onToggled;

  const WishlistButton({
    Key? key,
    required this.productId,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.onToggled,
  }) : super(key: key);

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> with SingleTickerProviderStateMixin {
  bool _isInWishlist = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkWishlistStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkWishlistStatus() async {
    final isInWishlist = WishlistService.isInWishlistSync(widget.productId);
    if (mounted) {
      setState(() => _isInWishlist = isInWishlist);
    }
  }

  Future<void> _toggleWishlist() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      if (_isInWishlist) {
        await WishlistService.removeFromWishlist(widget.productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from wishlist'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await WishlistService.addToWishlist(widget.productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to wishlist'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
      if (mounted) {
        setState(() => _isInWishlist = !_isInWishlist);
        widget.onToggled?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.red;
    final inactiveColor = widget.inactiveColor ?? Colors.grey[400];

    return GestureDetector(
      onTap: _toggleWishlist,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _isLoading
            ? SizedBox(
                width: widget.size,
                height: widget.size,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isInWishlist ? Icons.favorite : Icons.favorite_border,
                size: widget.size,
                color: _isInWishlist ? activeColor : inactiveColor,
              ),
      ),
    );
  }
}

class WishlistIconButton extends StatefulWidget {
  final String productId;
  final VoidCallback? onToggled;

  const WishlistIconButton({
    Key? key,
    required this.productId,
    this.onToggled,
  }) : super(key: key);

  @override
  State<WishlistIconButton> createState() => _WishlistIconButtonState();
}

class _WishlistIconButtonState extends State<WishlistIconButton> {
  bool _isInWishlist = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final isInWishlist = WishlistService.isInWishlistSync(widget.productId);
    if (mounted) {
      setState(() => _isInWishlist = isInWishlist);
    }
  }

  Future<void> _toggleWishlist() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await WishlistService.toggleWishlist(widget.productId);
      if (mounted) {
        setState(() => _isInWishlist = !_isInWishlist);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isInWishlist ? 'Added to wishlist' : 'Removed from wishlist'),
            duration: const Duration(seconds: 1),
          ),
        );
        widget.onToggled?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: _isInWishlist ? Colors.red : Colors.grey,
            ),
      onPressed: _toggleWishlist,
      tooltip: _isInWishlist ? 'Remove from wishlist' : 'Add to wishlist',
    );
  }
}
