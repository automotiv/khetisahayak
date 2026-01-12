import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/models/user.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FacebookSignInService {
  static final FacebookSignInService _instance = FacebookSignInService._internal();
  factory FacebookSignInService() => _instance;
  FacebookSignInService._internal();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  Future<bool> isLoggedIn() async {
    final accessToken = await FacebookAuth.instance.accessToken;
    return accessToken != null;
  }

  Future<User> signIn() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        if (result.status == LoginStatus.cancelled) {
          throw Exception('Facebook sign-in was cancelled');
        }
        throw Exception(result.message ?? 'Facebook sign-in failed');
      }

      final accessToken = result.accessToken?.tokenString;
      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      final response = await ApiService.post('auth/facebook', {
        'accessToken': accessToken,
      });

      final user = User.fromJson(response['user']);
      final token = response['token'] as String;

      await Future.wait([
        _storage.write(key: _tokenKey, value: token),
        _storage.write(key: _userKey, value: json.encode(user.toJson())),
      ]);

      return user;
    } catch (e) {
      print('FacebookSignInService: Error during sign in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      print('FacebookSignInService: Error during sign out: $e');
    }
  }

  Future<void> unlinkFacebook() async {
    await ApiService.post('auth/facebook/unlink', {});
    await FacebookAuth.instance.logOut();
  }
}
