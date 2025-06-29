import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/models/user.dart';

class AuthService {
  static Future<User> register(String username, String email, String password) async {
    final response = await ApiService.post('auth/register', {
      'username': username,
      'email': email,
      'password': password,
    });
    return User.fromJson(response);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('auth/login', {
      'email': email,
      'password': password,
    });
    return response; // This will contain token and user info
  }
}