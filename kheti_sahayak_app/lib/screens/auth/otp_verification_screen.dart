import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/providers/user_provider.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';

/// OTP Verification Screen
/// 
/// Allows users to verify their phone number via OTP
class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback? onVerified;
  final bool canSkip;
  
  const OTPVerificationScreen({
    Key? key,
    required this.phoneNumber,
    this.onVerified,
    this.canSkip = true,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _isSendingOTP = false;
  String? _error;
  int _resendCountdown = 0;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    // Auto-send OTP on screen load
    _sendOTP();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  Future<void> _sendOTP() async {
    if (_resendCountdown > 0) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() {
      _isSendingOTP = true;
      _error = null;
    });

    try {
      final success = await userProvider.sendOTP(widget.phoneNumber);
      
      if (mounted) {
        setState(() {
          _isSendingOTP = false;
          if (success) {
            _otpSent = true;
            _startResendCountdown();
          } else {
            _error = userProvider.error ?? 'Failed to send OTP';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingOTP = false;
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

  Future<void> _verifyOTP() async {
    final otp = _otp;
    
    if (otp.length != 6) {
      setState(() => _error = 'Please enter the complete 6-digit OTP');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await userProvider.verifyOTP(widget.phoneNumber, otp);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          if (widget.onVerified != null) {
            widget.onVerified!();
          } else {
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _error = userProvider.error ?? 'Invalid OTP. Please try again.';
          });
          _clearOTP();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
        _clearOTP();
      }
    }
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _onOTPChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto-verify when all digits are entered
    if (_otp.length == 6) {
      _verifyOTP();
    }
    
    setState(() {}); // Update UI
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace && 
          _otpControllers[index].text.isEmpty && 
          index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        centerTitle: true,
        actions: widget.canSkip
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Skip'),
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Phone icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Enter Verification Code',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'We\'ve sent a 6-digit code to:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Phone number
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.phoneNumber,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sending OTP indicator
                  if (_isSendingOTP)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Sending OTP...'),
                        ],
                      ),
                    ),

                  // OTP Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 48,
                        height: 56,
                        margin: EdgeInsets.only(
                          left: index > 0 ? 8 : 0,
                          right: index == 2 ? 16 : 0, // Extra space in middle
                        ),
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _onKeyPressed(index, event),
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: _otpControllers[index].text.isNotEmpty
                                  ? colorScheme.primaryContainer.withOpacity(0.3)
                                  : null,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) => _onOTPChanged(index, value),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

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

                  // Verify button
                  PrimaryButton(
                    onPressed: _otp.length == 6 ? _verifyOTP : null,
                    text: 'Verify',
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn\'t receive the code? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      TextButton(
                        onPressed: _resendCountdown > 0 || _isSendingOTP
                            ? null
                            : _sendOTP,
                        child: Text(
                          _resendCountdown > 0
                              ? 'Resend in $_resendCountdown s'
                              : 'Resend OTP',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hint
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'The OTP is valid for 10 minutes. Make sure to enter it before it expires.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
