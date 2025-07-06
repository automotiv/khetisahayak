import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/models/user.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';
  
  static final AuthService _instance = AuthService._internal();
  final StreamController<User?> _userController = StreamController<User?>();
  
  // Current user stream
  Stream<User?> get user => _userController.stream;
  User? _currentUser;
  String? _authToken;
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal() {
    _initAuth();
  }
  
  Future<void> _initAuth() async {
    // Load token and user data from secure storage
    _authToken = await _storage.read(key: _tokenKey);
    final userData = await _storage.read(key: _userKey);
    
    if (userData != null && _authToken != null) {
      try {
        _currentUser = User.fromJson(Map<String, dynamic>.from(userData as Map));
        _userController.add(_currentUser);
      } catch (e) {
        await _clearAuthData();
      }
    } else {
      _userController.add(null);
    }
  }
  
  Future<User> register(String username, String email, String password, {
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await ApiService.post('auth/register', {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone_number': phoneNumber,
      });
      
      final user = User.fromJson(response['user']);
      await _saveAuthData(response['token'], user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> login(String email, String password) async {
    try {
      final response = await ApiService.post('auth/login', {
        'email': email,
        'password': password,
      });
      
      final user = User.fromJson(response['user']);
      await _saveAuthData(response['token'], user);
      return user;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> _saveAuthData(String token, User user) async {
    _authToken = token;
    _currentUser = user;
    
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userKey, value: user.toJson().toString()),
    ]);
    
    _userController.add(user);
  }
  
  Future<void> logout() async {
    await _clearAuthData();
    _userController.add(null);
  }
  
  Future<void> _clearAuthData() async {
    _authToken = null;
    _currentUser = null;
    
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
    ]);
  }
  
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      _currentUser = User.fromJson(Map<String, dynamic>.from(userData as Map));
      return _currentUser;
    }
    return null;
  }
  
  String? get token => _authToken;
  
  bool get isAuthenticated => _authToken != null && _currentUser != null;
  
  Future<User> updateProfile({
    String? username,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? bio,
  }) async {
    if (_currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final response = await ApiService.put(
        'users/${_currentUser!.id}',
        {
          if (username != null) 'username': username,
          if (email != null) 'email': email,
          if (fullName != null) 'full_name': fullName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (address != null) 'address': address,
          if (bio != null) 'bio': bio,
        },
        includeAuth: true,
      );
      
      final updatedUser = User.fromJson(response);
      _currentUser = updatedUser;
      await _storage.write(key: _userKey, value: updatedUser.toJson().toString());
      _userController.add(updatedUser);
      
      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    await ApiService.post(
      'auth/change-password',
      {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
      includeAuth: true,
    );
  }
  
  Future<void> requestPasswordReset(String email) async {
    await ApiService.post('auth/forgot-password', {'email': email});
  }
  
  void dispose() {
    _userController.close();
  }
}