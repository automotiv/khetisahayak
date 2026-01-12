import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/services/product_comparison_service.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';

class CompareButton extends StatefulWidget {
  final String productId;
  final double size;
  final bool showLabel;
  final VoidCallback? onStateChanged;

  const CompareButton({
    Key? key,
    required this.productId,
    this.size = 24,
    this.showLabel = false,
    this.onStateChanged,
  }) : super(key: key);

  @override
  State<CompareButton> createState() => _CompareButtonState();
}

class _CompareButtonState extends State<CompareButton> {
  bool _isInComparison = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final inComparison =
        await ProductComparisonService.isInComparison(widget.productId);
    if (mounted) {
      setState(() => _isInComparison = inComparison);
    }
  }

  Future<void> _toggleComparison() async {
    setState(() => _isLoading = true);

    try {
      if (_isInComparison) {
        await ProductComparisonService.removeFromComparison(widget.productId);
        if (mounted) {
          setState(() => _isInComparison = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from comparison'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        final count = await ProductComparisonService.getComparisonCount();
        if (count >= ProductComparisonService.maxCompareProducts) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 5 products can be compared'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final added =
            await ProductComparisonService.addToComparison(widget.productId);
        if (added && mounted) {
          setState(() => _isInComparison = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to comparison (${count + 1}/5)'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Compare',
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.productComparison,
                ),
              ),
            ),
          );
        }
      }

      widget.onStateChanged?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showLabel) {
      return TextButton.icon(
        onPressed: _isLoading ? null : _toggleComparison,
        icon: _isLoading
            ? SizedBox(
                width: widget.size,
                height: widget.size,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isInComparison ? Icons.compare : Icons.compare_arrows_outlined,
                size: widget.size,
                color: _isInComparison ? Colors.green[700] : Colors.grey[600],
              ),
        label: Text(
          _isInComparison ? 'In Comparison' : 'Compare',
          style: TextStyle(
            color: _isInComparison ? Colors.green[700] : Colors.grey[600],
          ),
        ),
      );
    }

    return IconButton(
      onPressed: _isLoading ? null : _toggleComparison,
      icon: _isLoading
          ? SizedBox(
              width: widget.size,
              height: widget.size,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isInComparison ? Icons.compare : Icons.compare_arrows_outlined,
              size: widget.size,
              color: _isInComparison ? Colors.green[700] : Colors.grey[600],
            ),
      tooltip: _isInComparison ? 'Remove from comparison' : 'Add to comparison',
    );
  }
}

class ComparisonFAB extends StatefulWidget {
  const ComparisonFAB({Key? key}) : super(key: key);

  @override
  State<ComparisonFAB> createState() => _ComparisonFABState();
}

class _ComparisonFABState extends State<ComparisonFAB> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final count = await ProductComparisonService.getComparisonCount();
    if (mounted) {
      setState(() => _count = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_count < 2) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.productComparison),
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
      icon: Badge(
        label: Text('$_count'),
        child: const Icon(Icons.compare_arrows),
      ),
      label: const Text('Compare'),
    );
  }
}
