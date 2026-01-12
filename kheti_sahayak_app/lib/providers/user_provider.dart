import 'package:flutter/foundation.dart';
import 'package:kheti_sahayak_app/models/user.dart';
import 'package:kheti_sahayak_app/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  final AuthService _authService = AuthService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  
  // Accessibility State
  bool _isHighContrastMode = false;
  bool get isHighContrastMode => _isHighContrastMode;

  // Initialize the provider
  UserProvider() {
    _loadCurrentUser();
  }

  // Initialize method for main.dart
  Future<void> initialize() async {
    await _loadCurrentUser();
  }

  // Load current user from secure storage
  Future<void> _loadCurrentUser() async {
    try {
      _user = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user data';
      if (kDebugMode) {
        print('Error loading user: $e');
      }
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register a new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        username,
        email,
        password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? username,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? bio,
  }) async {
    if (_user == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.updateProfile(
        username: username,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        address: address,
        bio: bio,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.changePassword(currentPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Request password reset
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.requestPasswordReset(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset password with token
  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(token, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Resend verification email
  Future<bool> resendVerificationEmail() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resendVerificationEmail();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Send OTP for phone verification
  Future<bool> sendOTP(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendOTP(phone);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String phone, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyOTP(phone, otp);
      // Refresh user to get updated verification status
      _user = await _authService.refreshProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshProfile() async {
    try {
      _user = await _authService.refreshProfile();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, bool>> getAvailableAuthProviders() async {
    return _authService.getAvailableAuthProviders();
  }

  Future<bool> unlinkGoogleAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.unlinkGoogleAccount();
      _user = await _authService.refreshProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithFacebook();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> unlinkFacebookAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.unlinkFacebookAccount();
      _user = await _authService.refreshProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
  Future<void> logout() async {
    try {
      await _authService.logout();
      _user = null;
      _error = null;
    } catch (e) {
      _error = 'Failed to logout';
      if (kDebugMode) {
        print('Error during logout: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Toggle High Contrast Mode
  void toggleHighContrast() {
    _isHighContrastMode = !_isHighContrastMode;
    notifyListeners();
  }

  // Dispose method
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
