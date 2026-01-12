import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/providers/user_provider.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';
import 'package:kheti_sahayak_app/widgets/custom_text_field.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/success_dialog.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';

/// Reset Password Screen
/// 
/// Allows users to set a new password using a reset token from email
class ResetPasswordScreen extends StatefulWidget {
  final String token;
  
  const ResetPasswordScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (ctx) => const ErrorDialog(
          title: 'Passwords Don\'t Match',
          content: 'Please make sure your passwords match.',
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() => _isLoading = true);
    
    final success = await userProvider.resetPassword(
      widget.token,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => SuccessDialog(
            title: 'Password Reset Successfully',
            content: 'Your password has been reset. You can now log in with your new password.',
            buttonText: 'Go to Login',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => ErrorDialog(
            title: 'Reset Failed',
            content: userProvider.error ?? 
                'Failed to reset password. The link may have expired. Please request a new password reset.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Password'),
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
                    const SizedBox(height: 40),
                    
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Create New Password',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      'Please enter a new secure password for your account.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Password requirements
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Password Requirements',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildRequirement('At least 6 characters long'),
                          _buildRequirement('Use a mix of letters and numbers'),
                          _buildRequirement('Avoid common passwords'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // New Password field
                    Text(
                      'New Password',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Enter new password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password field
                    Text(
                      'Confirm Password',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm new password',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Reset button
                    PrimaryButton(
                      onPressed: _resetPassword,
                      text: 'Reset Password',
                      isLoading: _isLoading,
                    ),
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

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
