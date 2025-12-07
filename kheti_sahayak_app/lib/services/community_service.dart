import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/community_post.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';

class CommunityService {
  static Future<List<CommunityPost>> getPosts() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/community/posts'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['data'];
          return items.map((item) => CommunityPost.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching community posts: $e');
      return [];
    }
  }
}
