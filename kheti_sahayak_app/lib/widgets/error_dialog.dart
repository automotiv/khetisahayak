import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? buttonText;
  final String? retryButtonText;
  final VoidCallback? onPressed;
  final VoidCallback? onRetry;
  final bool showRetry;

  const ErrorDialog({
    Key? key,
    required this.title,
    required this.content,
    this.buttonText = 'OK',
    this.retryButtonText = 'Retry',
    this.onPressed,
    this.onRetry,
    this.showRetry = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
          child: Text(buttonText ?? 'OK'),
        ),
        if (showRetry || onRetry != null)
          TextButton(
            onPressed: onRetry ?? () {
              Navigator.of(context).pop();
              if (onRetry != null) onRetry!();
            },
            child: Text(retryButtonText ?? 'Retry'),
          ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String content,
    String? buttonText,
    String? retryButtonText,
    VoidCallback? onPressed,
    VoidCallback? onRetry,
    bool showRetry = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ErrorDialog(
        title: title,
        content: content,
        buttonText: buttonText,
        retryButtonText: retryButtonText,
        onPressed: onPressed,
        onRetry: onRetry,
        showRetry: showRetry,
      ),
    );
  }
}
