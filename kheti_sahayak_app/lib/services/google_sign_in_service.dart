import 'package:google_sign_in/google_sign_in.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/models/user.dart';
import 'package:kheti_sahayak_app/services/auth_service.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  Future<User> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      final response = await ApiService.post('auth/google', {
        'idToken': idToken,
      });

      final user = User.fromJson(response['user']);
      final token = response['token'] as String;

      await Future.wait([
        _storage.write(key: _tokenKey, value: token),
        _storage.write(key: _userKey, value: json.encode(user.toJson())),
      ]);

      return user;
    } catch (e) {
      print('GoogleSignInService: Error during sign in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('GoogleSignInService: Error during sign out: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      print('GoogleSignInService: Error during disconnect: $e');
    }
  }

  Future<Map<String, bool>> getAvailableProviders() async {
    try {
      final response = await ApiService.get('auth/providers');
      return {
        'google': response['google'] as bool? ?? false,
        'facebook': response['facebook'] as bool? ?? false,
        'email': response['email'] as bool? ?? true,
      };
    } catch (e) {
      return {'google': false, 'facebook': false, 'email': true};
    }
  }

  Future<void> unlinkGoogle() async {
    await ApiService.post('auth/google/unlink', {});
    await _googleSignIn.signOut();
  }
}
