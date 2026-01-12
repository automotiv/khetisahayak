import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/providers/user_provider.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';

/// Email Verification Screen
/// 
/// Shows email verification status and allows resending verification email
class EmailVerificationScreen extends StatefulWidget {
  final String? email;
  
  const EmailVerificationScreen({Key? key, this.email}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _emailSent = false;
  String? _error;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    // Auto-send verification email if not verified
    _checkAndSendVerification();
  }

  Future<void> _checkAndSendVerification() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    if (user != null && !user.isEmailVerified && !_emailSent) {
      await _resendVerification();
    }
  }

  Future<void> _resendVerification() async {
    if (_resendCountdown > 0) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await userProvider.resendVerificationEmail();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (success) {
            _emailSent = true;
            _startResendCountdown();
          } else {
            _error = userProvider.error ?? 'Failed to send verification email';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      setState(() {
        _resendCountdown = _resendCountdown > 0 ? _resendCountdown - 1 : 0;
      });
      
      return _resendCountdown > 0;
    });
  }

  Future<void> _checkVerificationStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() => _isLoading = true);
    
    final success = await userProvider.refreshProfile();
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success && userProvider.user?.isEmailVerified == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final email = widget.email ?? user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Email icon with animation
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Check Your Email',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'We\'ve sent a verification link to:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Email address
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            email,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Click the link in the email to verify your account',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'The link will expire in 24 hours. Check your spam folder if you don\'t see it.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Check verification status button
                  PrimaryButton(
                    onPressed: _checkVerificationStatus,
                    text: 'I\'ve Verified My Email',
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Resend button
                  OutlinedButton.icon(
                    onPressed: _resendCountdown > 0 ? null : _resendVerification,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _resendCountdown > 0
                          ? 'Resend in $_resendCountdown s'
                          : 'Resend Verification Email',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Help text
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Open help/support
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact support: support@khetisahayak.com')),
                      );
                    },
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Need help?'),
                  ),
                ],
              ),
            ),
    );
  }
}
