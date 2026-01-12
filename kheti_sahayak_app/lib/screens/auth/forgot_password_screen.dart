import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/providers/user_provider.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/widgets/custom_text_field.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';
import 'package:kheti_sahayak_app/widgets/success_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() => _isLoading = true);
    
    final success = await userProvider.requestPasswordReset(
      _emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      if (success) {
        _emailSent = true;
      }
    });

    if (success) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => SuccessDialog(
            title: 'Email Sent',
            content: 'We have sent a password reset link to your email. Please check your inbox.',
            buttonText: 'Back to Login',
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        );
      }
    } else if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => ErrorDialog(
          title: 'Password Reset Failed',
          content: userProvider.error ?? 'Failed to send password reset email. Please try again.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Illustration or icon
                    const SizedBox(height: 40),
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),

                    // Title and description
                    Text(
                      'Forgot Your Password?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _emailSent
                          ? 'We\'ve sent a password reset link to your email. Please check your inbox.'
                          : 'Enter your email address and we\'ll send you a link to reset your password.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    if (!_emailSent) ...[
                      // Email field
                      Text(
                        'Email Address',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Enter your email',
                        icon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Send Reset Link button
                      PrimaryButton(
                        onPressed: _resetPassword,
                        text: 'Send Reset Link',
                        isLoading: _isLoading,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Back to login
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      },
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
