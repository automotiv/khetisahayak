import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? buttonText;
  final VoidCallback? onPressed;

  const ErrorDialog({
    Key? key,
    required this.title,
    required this.content,
    this.buttonText = 'OK',
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(color: Colors.red),
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
          child: Text(buttonText!),
        ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String content,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ErrorDialog(
        title: title,
        content: content,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }
}
